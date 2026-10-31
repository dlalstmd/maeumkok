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
    this.subcategory,
    this.subcategoryLabel,
    this.vibrationName,
    this.custom = false,
    this.deleted = false,
    this.createdBy,
  });
  final String? subcategory;
  final String? subcategoryLabel;
  final String? vibrationName;

  /// 커플 커스텀 감정(우리 감정)
  final bool custom;

  /// soft delete 된 커스텀 감정(보낸 기록 표시용으로만 남음)
  final bool deleted;
  final String? createdBy;

  /// 이모지 글리프(커스텀 감정 emoji 타입)일 때만 true
  bool get usesEmoji => icon == null || icon!.isEmpty;

  /// 메시지에 함께 저장하는 표시용 스냅샷
  Map<String, Object?> toSnapshot() => {
    'label': label,
    if (icon != null) 'icon': icon,
    if (emoji.isNotEmpty) 'emoji': emoji,
    'animationKey': animationKey,
    if (vibrationName != null) 'vibrationName': vibrationName,
    'category': category,
    if (custom) 'custom': true,
  };

  /// 스냅샷 → 표시용 감정(원본이 지워졌거나 바뀐 경우)
  static Emotion fromSnapshot(String id, Map snap) {
    final vib = snap['vibrationName'] as String?;
    return Emotion(
      id: id,
      label: (snap['label'] as String?) ?? id,
      emoji: (snap['emoji'] as String?) ?? '',
      category: (snap['category'] as String?) ?? 'mood',
      categoryLabel: kCategoryLabels[snap['category']] ?? '',
      vibrationPattern: kVibrationPresets[vib] ?? const [0, 40],
      reactions: kDefaultCustomReactions,
      animationKey: (snap['animationKey'] as String?) ?? '',
      icon: snap['icon'] as String?,
      vibrationName: vib,
      custom: snap['custom'] == true,
    );
  }

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
      subcategory: j['subcategory'] as String?,
      subcategoryLabel: j['subcategory_label'] as String?,
      vibrationName: j['vibration_name'] as String?,
    );
  }
}

class Reaction {
  const Reaction(this.id, this.label);
  final String id;
  final String label;
}

/// 앱 시작 시 [loadEmotions]로 채워진다(내장 감정, json 순서).
List<Emotion> kEmotions = const [];

/// 커플 커스텀 감정(홈 화면 리스너가 갱신). soft delete 포함.
Map<String, Emotion> kCustomEmotions = {};

/// vibration_presets: 이름 → 패턴
Map<String, List<int>> kVibrationPresets = const {
  'short': [0, 40],
  'double': [0, 40, 80, 40],
  'soft': [0, 120],
  'long': [0, 400],
  'heart': [0, 60, 100, 120],
  'triple': [0, 30, 60, 30, 60, 30],
  'slow': [0, 200, 300, 200],
  'buzz': [0, 80, 50, 80, 50, 80],
};

const kCategoryLabels = {
  'mood': '기분',
  'body': '몸 상태',
  'want': '하고 싶은 것',
  'love': '애정',
};
const kDefaultCustomReactions = [Reaction('0', '고마워'), Reaction('1', '나도!')];

class Subcategory {
  const Subcategory(this.id, this.label, this.emotionIds);
  final String id;
  final String label;
  final List<String> emotionIds;
}

class CategoryNode {
  const CategoryNode(this.id, this.label, this.icon, this.subcategories);
  final String id;
  final String label;
  final String? icon;
  final List<Subcategory> subcategories;
}

List<CategoryNode> kCategoryTree = const [];

/// 우리 감정 이름 최대 글자 수(emotions.json custom_label_max_chars)
int kCustomLabelMaxChars = 6;

/// 이전 버전에서 빠진 감정(이미 보낸 기록이 깨지지 않도록 표시용으로 유지)
final kLegacyEmotions = <String, Emotion>{
  'miss_you': const Emotion(
    id: 'miss_you',
    label: '보고싶어',
    emoji: '🥹',
    category: 'love',
    categoryLabel: '애정',
    vibrationPattern: [0, 200, 300, 200],
    reactions: [Reaction('0', '나도 너무 보고싶어'), Reaction('1', '곧 만나자')],
    animationKey: 'longing',
    icon: 'lucide:hourglass',
    vibrationName: 'slow',
  ),
};

List<Emotion> parseEmotions(String json) {
  final d = jsonDecode(json) as Map<String, dynamic>;
  return (d['emotions'] as List)
      .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
      .toList();
}

void _parseExtras(String json) {
  final d = jsonDecode(json) as Map<String, dynamic>;
  kCustomLabelMaxChars = (d['custom_label_max_chars'] as num?)?.toInt() ?? 6;
  final vp = d['vibration_presets'];
  if (vp is Map) {
    kVibrationPresets = {
      for (final e in vp.entries)
        e.key as String: (e.value as List)
            .map((x) => (x as num).toInt())
            .toList(),
    };
  }
  final tree = d['category_tree'];
  if (tree is List) {
    kCategoryTree = [
      for (final c in tree.cast<Map>())
        CategoryNode(
          c['id'] as String,
          c['label'] as String,
          c['icon'] as String?,
          [
            for (final sc
                in ((c['subcategories'] as List?) ?? const []).cast<Map>())
              Subcategory(
                sc['id'] as String,
                sc['label'] as String,
                ((sc['emotion_ids'] as List?) ?? const []).cast<String>(),
              ),
          ],
        ),
    ];
  }
}

Future<void> loadEmotions() async {
  final json = await rootBundle.loadString('assets/emotions.json');
  kEmotions = parseEmotions(json);
  _parseExtras(json);
}

/// 테스트용
void loadEmotionsFromString(String json) {
  kEmotions = parseEmotions(json);
  _parseExtras(json);
}

/// id로 찾기: 내장 → 우리 감정 → 이전 버전 감정. 순서에 의존하지 않는다.
Emotion? emotionById(String id) {
  for (final e in kEmotions) {
    if (e.id == id) return e;
  }
  return kCustomEmotions[id] ?? kLegacyEmotions[id];
}

/// 메시지 표시용: id로 못 찾으면 메시지에 저장된 스냅샷 사용
Emotion? emotionFor(String id, Map? snapshot) =>
    emotionById(id) ??
    (snapshot == null ? null : Emotion.fromSnapshot(id, snapshot));
