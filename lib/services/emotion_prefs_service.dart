import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/emotions.dart';

const kMaxCustomEmotions = 30;
const kMaxFavorites = 24;
const kMaxRecent = 12;
int get kCustomLabelMax => kCustomLabelMaxChars;
const kMaxCustomReactions = 3;
const kCustomReactionMax = 12;
const kDefaultReactionTexts = ['고마워', '나도!'];

/// 추천 반응 정리: 공백 제거, 1~12자, 최대 3개
List<String> cleanReactions(Iterable<String> rs) => rs
    .map((r) => r.trim())
    .where((r) => r.isNotEmpty && r.characters.length <= kCustomReactionMax)
    .take(kMaxCustomReactions)
    .toList();

/// 우리 감정 만들기에서 고를 수 있는 프리셋
const kCustomIcons = [
  'lucide:laptop',
  'lucide:mic',
  'lucide:coffee',
  'lucide:music',
  'lucide:dog',
  'lucide:umbrella',
  'lucide:book-open',
  'lucide:gamepad-2',
];
const kCustomEmojis = ['🍗', '🎤', '☕', '🎮', '🍜', '🌙', '🚗', '💪'];
const kVibrationChoices = {
  'short': '톡',
  'double': '톡톡',
  'heart': '두근',
  'buzz': '부르르',
  'slow': '토닥',
  'long': '길게',
};
const kMotionChoices = {
  'joy_bounce': '통통',
  'sway': '살랑',
  'rush': '후다닥',
  'drool': '츄릅',
  'heart_pop': '하트',
  'shiver': '덜덜',
  'doze': '꾸벅',
  'cheer': '응원',
};

/// Firestore 문서 → 감정(커스텀)
Emotion customFromDoc(String id, Map<String, dynamic> m) {
  final vib = m['vibrationName'] as String?;
  final rs = ((m['reactions'] as List?) ?? const [])
      .whereType<String>()
      .toList();
  final cat = (m['category'] as String?) ?? 'mood';
  return Emotion(
    id: id,
    label: (m['label'] as String?) ?? '',
    emoji: m['glyphType'] == 'emoji' ? ((m['emoji'] as String?) ?? '') : '',
    category: cat,
    categoryLabel: kCategoryLabels[cat] ?? cat,
    vibrationPattern: kVibrationPresets[vib] ?? const [0, 40],
    reactions: rs.isEmpty
        ? kDefaultCustomReactions
        : [for (var i = 0; i < rs.length; i++) Reaction('$i', rs[i])],
    animationKey: (m['animationKey'] as String?) ?? 'joy_bounce',
    icon: m['glyphType'] == 'icon' ? m['icon'] as String? : null,
    vibrationName: vib,
    custom: true,
    deleted: m['deleted'] == true,
    createdBy: m['createdBy'] as String?,
  );
}

/// 즐겨찾기 정리: 중복·없는·삭제된 감정 제거, 최대 [kMaxFavorites]
List<String> cleanFavorites(Iterable<String> ids) {
  final out = <String>[];
  for (final id in ids) {
    final e = emotionById(id);
    if (e == null || e.deleted || out.contains(id)) continue;
    out.add(id);
    if (out.length >= kMaxFavorites) break;
  }
  return out;
}

class RecentItem {
  const RecentItem(this.emotionId, this.sentAt);
  final String emotionId;
  final DateTime sentAt;
}

/// 최근 목록에 [id]를 맨 앞으로(중복 제거, 최대 [kMaxRecent])
List<RecentItem> pushRecent(List<RecentItem> cur, String id, DateTime at) => [
  RecentItem(id, at),
  ...cur.where((r) => r.emotionId != id),
].take(kMaxRecent).toList();

class EmotionPrefsService {
  EmotionPrefsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  final _rand = Random.secure();

  CollectionReference<Map<String, dynamic>> customs(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('customEmotions');
  DocumentReference<Map<String, dynamic>> _fav(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('prefs')
      .doc('emotionFavorites');
  DocumentReference<Map<String, dynamic>> _recent(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('prefs')
      .doc('recentEmotions');

  String newCustomId() {
    const hex = '0123456789abcdef';
    return 'custom_${List.generate(20, (_) => hex[_rand.nextInt(16)]).join()}';
  }

  Stream<List<Emotion>> watchCustoms(String coupleId) =>
      customs(coupleId)
          .orderBy('createdAt')
          .limit(60)
          .snapshots()
          .map((s) => [for (final d in s.docs) customFromDoc(d.id, d.data())]);

  Future<void> saveCustom(
    String coupleId,
    String uid, {
    String? id,
    required String label,
    required String glyphType,
    String? icon,
    String? emoji,
    required String category,
    required String vibrationName,
    required String animationKey,
    List<String> reactions = kDefaultReactionTexts,
  }) async {
    final name = label.trim();
    if (name.isEmpty || name.characters.length > kCustomLabelMax) {
      throw ArgumentError('이름은 1~$kCustomLabelMax자로 지어 주세요');
    }
    final active = kCustomEmotions.values.where((e) => !e.deleted).length;
    if (id == null && active >= kMaxCustomEmotions) {
      throw StateError('우리 감정은 최대 $kMaxCustomEmotions개까지 만들 수 있어요');
    }
    final docId = id ?? newCustomId();
    final data = <String, Object?>{
      'id': docId,
      'label': label.trim(),
      'glyphType': glyphType,
      'icon': glyphType == 'icon' ? icon : null,
      'emoji': glyphType == 'emoji' ? emoji : null,
      'category': category,
      'vibrationName': vibrationName,
      'animationKey': animationKey,
      'reactions': cleanReactions(reactions),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      final counter = _counter(coupleId);
      await _db.runTransaction((tx) async {
        final c = await tx.get(counter);
        final n = ((c.data()?['n'] as num?) ?? 0).toInt();
        if (n >= kMaxCustomEmotions) {
          throw StateError('우리 감정은 최대 $kMaxCustomEmotions개까지 만들 수 있어요');
        }
        tx.set(counter, {'n': n + 1});
        tx.set(customs(coupleId).doc(docId), {
          ...data,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'deleted': false,
        });
      });
    } else {
      await customs(coupleId).doc(docId).update(data);
    }
  }

  /// soft delete: 문서는 남기고 deleted 표시
  Future<void> deleteCustom(String coupleId, String id) async {
    final counter = _counter(coupleId);
    await _db.runTransaction((tx) async {
      final c = await tx.get(counter);
      final d = await tx.get(customs(coupleId).doc(id));
      if (d.data()?['deleted'] == true) return;
      final n = ((c.data()?['n'] as num?) ?? 1).toInt();
      tx.set(counter, {'n': n > 0 ? n - 1 : 0});
      tx.update(customs(coupleId).doc(id), {
        'deleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _counter(String coupleId) => _db
      .collection('couples')
      .doc(coupleId)
      .collection('counters')
      .doc('customEmotions');

  Stream<List<String>> watchFavorites(String uid) => _fav(uid).snapshots().map(
    (s) => ((s.data()?['order'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
  );

  Future<void> saveFavorites(String uid, List<String> order) => _fav(uid).set({
    'order': order.take(kMaxFavorites).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Stream<List<RecentItem>> watchRecent(String uid) =>
      _recent(uid).snapshots().map(
        (s) => [
          for (final m
              in ((s.data()?['items'] as List?) ?? const []).whereType<Map>())
            if (m['emotionId'] is String && m['sentAt'] is Timestamp)
              RecentItem(
                m['emotionId'] as String,
                (m['sentAt'] as Timestamp).toDate(),
              ),
        ],
      );

  Future<void> saveRecent(String uid, List<RecentItem> items) =>
      _recent(uid).set({
        'items': [
          for (final r in items.take(kMaxRecent))
            {'emotionId': r.emotionId, 'sentAt': Timestamp.fromDate(r.sentAt)},
        ],
      });
}
