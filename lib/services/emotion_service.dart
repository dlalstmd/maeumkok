import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionEvent {
  EmotionEvent(
    this.id,
    this.senderUid,
    this.emotionId,
    this.createdAt,
    this.readAt,
  );
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

class EmotionService {
  EmotionService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _emotions(String c) =>
      _db.collection('couples').doc(c).collection('emotions');
  CollectionReference<Map<String, dynamic>> _reactions(String c) =>
      _db.collection('couples').doc(c).collection('reactions');

  Future<void> sendEmotion(String coupleId, String myUid, String emotionId) =>
      _emotions(coupleId).add({
        'senderUid': myUid,
        'emotionId': emotionId,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    int limit = 50,
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
  Future<List<ReactionEvent>> reactionsFor(String coupleId, List<String> ids) async {
    final out = <ReactionEvent>[];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final r = await _reactions(coupleId).where('emotionDocId', whereIn: chunk).get();
      out.addAll(r.docs.map(ReactionEvent.fromDoc));
    }
    return out;
  }
}
