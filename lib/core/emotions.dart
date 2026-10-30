import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 감정 목록은 assets/emotions.json(콕디자인, docs/SHARED.md 6번)에서 읽는다.
/// 목록 교체 = JSON 교체. 코드는 수정할 필요 없음.
class Emotion {
  const Emotion({
    required this.id,
    required this.label,
    required this.emoji,
    required this.category,
    required this.categoryLabel,
    required this.vibrationPattern,
    required this.reactions,
    required this.animationKey,
    this.icon,
  });

  final String id;
  final String label;
  final String emoji;
  final String category;
  final String categoryLabel;

  /// 진동 패턴(ms): [대기, 진동, 대기, 진동, ...]
  final List<int> vibrationPattern;

  /// 원탭 추천 반응 (reactionId = 인덱스 문자열)
  final List<Reaction> reactions;
  final String animationKey;

  /// `lucide:<name>` (lib/core/lucide_map.dart)
  final String? icon;

  factory Emotion.fromJson(Map<String, dynamic> j) {
    final rs = (j['reactions'] as List).cast<String>();
    return Emotion(
      id: j['id'] as String,
      label: j['label'] as String,
      emoji: j['emoji'] as String,
      category: j['category'] as String,
      categoryLabel: (j['category_label'] ?? j['category']) as String,
      vibrationPattern: (j['vibration_pattern_ms'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      reactions: [for (var i = 0; i < rs.length; i++) Reaction('$i', rs[i])],
      animationKey: (j['animation_key'] ?? '') as String,
      icon: j['icon'] as String?,
    );
  }
}

class Reaction {
  const Reaction(this.id, this.label);
  final String id;
  final String label;
}

/// 앱 시작 시 [loadEmotions]로 채워진다.
List<Emotion> kEmotions = const [];

List<Emotion> parseEmotions(String json) {
  final d = jsonDecode(json) as Map<String, dynamic>;
  return (d['emotions'] as List)
      .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> loadEmotions() async {
  kEmotions = parseEmotions(
    await rootBundle.loadString('assets/emotions.json'),
  );
}

Emotion? emotionById(String id) {
  for (final e in kEmotions) {
    if (e.id == id) return e;
  }
  return null;
}
