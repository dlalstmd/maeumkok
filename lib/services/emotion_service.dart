import '../core/emotions.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionEvent {
  EmotionEvent(
    this.id,
    this.senderUid,
    this.emotionId,
    this.createdAt,
    this.readAt, [
    this.count = 1,
    this.snapshot,
  ]);

  /// 보낼 때 복사해 둔 감정 표시 정보
  final Map<String, dynamic>? snapshot;

  /// 연타 묶음 개수(1~99)
  final int count;
  final String id;
  final String senderUid;
  final String emotionId;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory EmotionEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return EmotionEvent(
      d.id,
      m['senderUid'] as String,
      m['emotionId'] as String,
      (m['createdAt'] as Timestamp?)?.toDate(),
      (m['readAt'] as Timestamp?)?.toDate(),
      ((m['count'] as num?)?.toInt() ?? 1).clamp(1, kMaxBurst),
      (m['snapshot'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class ReactionEvent {
  ReactionEvent(this.id, this.senderUid, this.emotionDocId, this.reactionId);
  final String id;
  final String senderUid;
  final String emotionDocId;
  final String reactionId;

  factory ReactionEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ReactionEvent(
      d.id,
      m['senderUid'] as String,
      m['emotionDocId'] as String,
      m['reactionId'] as String,
    );
  }
}

/// [emotionDocId] 감정에 [senderUid]가 남긴 가장 최근 반응 (없으면 null).
ReactionEvent? reactionFor(
  Iterable<ReactionEvent> all,
  String emotionDocId, {
  String? senderUid,
}) {
  for (final r in all) {
    if (r.emotionDocId == emotionDocId &&
        (senderUid == null || r.senderUid == senderUid)) {
      return r;
    }
  }
  return null;
}

/// 감정의 추천 반응 id('0','1',..) → 표시 문구
String reactionLabel(Emotion? e, String reactionId) {
  for (final r in e?.reactions ?? const <Reaction>[]) {
    if (r.id == reactionId) return r.label;
  }
  return reactionId;
}

const kMaxBurst = 99;

/// 같은 감정을 이 시간 안에 다시 보내면 직전 문서 count를 올린다.
const kMergeWindow = Duration(seconds: 3);

class EmotionService {
  EmotionService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _emotions(String c) =>
      _db.collection('couples').doc(c).collection('emotions');
  CollectionReference<Map<String, dynamic>> _reactions(String c) =>
      _db.collection('couples').doc(c).collection('reactions');

  String? _lastId, _lastEmotion;
  DateTime? _lastAt;
  int _lastCount = 0;

  /// 감정 [count]개를 문서 1개로 보낸다. 같은 감정을 [kMergeWindow] 안에
  /// 다시 보내면 직전 문서의 count를 올린다(최대 [kMaxBurst]).
  Future<void> sendEmotion(
    String coupleId,
    String myUid,
    String emotionId, {
    int count = 1,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    count = count.clamp(1, kMaxBurst);
    final last = _lastId;
    if (last != null &&
        _lastEmotion == emotionId &&
        _lastAt != null &&
        t.difference(_lastAt!) < kMergeWindow &&
        _lastCount < kMaxBurst) {
      final next = (_lastCount + count).clamp(1, kMaxBurst);
      try {
        await _emotions(coupleId).doc(last).update({'count': next});
        _lastCount = next;
        _lastAt = t;
        return;
      } catch (_) {
        // 규칙상 병합 창이 지났으면 새 문서로
      }
    }
    final ref = _emotions(coupleId).doc();
    await ref.set({
      'senderUid': myUid,
      'emotionId': emotionId,
      'count': count,
      'snapshot': ?emotionById(emotionId)?.toSnapshot(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _lastId = ref.id;
    _lastEmotion = emotionId;
    _lastAt = t;
    _lastCount = count;
  }

  Future<void> markRead(String coupleId, String emotionDocId) =>
      _emotions(coupleId)
          .doc(emotionDocId)
          .update({'readAt': FieldValue.serverTimestamp()});

  Future<void> react(
    String coupleId,
    String myUid,
    String emotionDocId,
    String reactionId,
  ) => _reactions(coupleId).add({
    'senderUid': myUid,
    'emotionDocId': emotionDocId,
    'reactionId': reactionId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Stream<List<EmotionEvent>> watchEmotions(String coupleId, {int limit = 50}) =>
      _emotions(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(EmotionEvent.fromDoc).toList());

  Stream<List<ReactionEvent>> watchReactions(
    String coupleId, {
    int limit = 30,
  }) =>
      _reactions(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(ReactionEvent.fromDoc).toList());

  /// 타임라인 페이지: createdAt 내림차순, [after] 다음부터 [limit]개
  Future<QuerySnapshot<Map<String, dynamic>>> page(
    String coupleId, {
    DocumentSnapshot? after,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> q = _emotions(coupleId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    return q.get();
  }

  /// 감정 문서 id 목록에 달린 반응 (whereIn 30개 단위)
  Future<List<ReactionEvent>> reactionsFor(
    String coupleId,
    List<String> ids,
  ) async {
    final out = <ReactionEvent>[];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final r = await _reactions(coupleId)
          .where('emotionDocId', whereIn: chunk)
          .get();
      out.addAll(r.docs.map(ReactionEvent.fromDoc));
    }
    return out;
  }
}
