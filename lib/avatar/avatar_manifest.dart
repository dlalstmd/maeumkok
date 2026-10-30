import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// assets/avatar/manifest.json (콕디자인) 기반 데이터 구동 아바타.
/// 파츠 추가 = SVG + manifest 항목 추가. 코드 수정 불필요.
class AvatarPart {
  const AvatarPart({
    required this.id,
    required this.category,
    required this.file,
    this.fill,
    this.stroke,
    this.slot,
    this.variant = false,
  });
  final String id;
  final String category;
  final String file;
  final String? fill;
  final String? stroke;
  final String? slot;
  final bool variant;

  factory AvatarPart.fromJson(Map<String, dynamic> j) => AvatarPart(
    id: j['id'] as String,
    category: j['category'] as String,
    file: j['file'] as String,
    fill: j['fill'] as String?,
    stroke: j['stroke'] as String?,
    slot: j['slot'] as String?,
  );
}

/// 색 조합 제약: when(카테고리→파츠 id 목록)이 맞으면 대상 카테고리 SVG 색을 치환.
/// manifest.json `constraints`로 추가 가능. 없으면 [kDefaultConstraints] 사용.
class AvatarConstraint {
  const AvatarConstraint({required this.when, required this.recolor});
  final Map<String, List<String>> when;
  final Map<String, Map<String, String>> recolor; // category -> {from: to}

  bool matches(Map<String, String> sel) =>
      when.entries.every((e) => e.value.contains(sel[e.key]));

  factory AvatarConstraint.fromJson(Map<String, dynamic> j) => AvatarConstraint(
    when: (j['when'] as Map).map(
      (k, v) => MapEntry(k as String, (v as List).cast<String>()),
    ),
    recolor: (j['recolor'] as Map).map(
      (k, v) => MapEntry(
        k as String,
        (v as Map).map((a, b) => MapEntry(a as String, b as String)),
      ),
    ),
  );
}

/// 추가 색 치환 제약(선택). 기본 대비 규칙은 manifest `contrast_rules`가 담당.
const kDefaultConstraints = <AvatarConstraint>[];

/// 사용자 선택 가능 카테고리(그림자·fx 제외)
const kCustomizableCategories = ['body', 'eyes', 'mouth', 'blush', 'accessory'];
const kCategoryLabels = {
  'body': '몸 색',
  'eyes': '눈',
  'mouth': '입',
  'blush': '볼터치',
  'accessory': '꾸미기',
};

class AvatarManifest {
  AvatarManifest({
    required this.layerOrder,
    required this.defaults,
    required this.parts,
    required this.constraints,
    this.bodyTone = const {},
    this.anchors = const {},
    this.toneVariants = const {},
  });
  final List<String> layerOrder;
  final Map<String, String> defaults;
  final Map<String, AvatarPart> parts;
  final List<AvatarConstraint> constraints;

  /// contrast_rules.body_tone: body id -> tone(light/dark)
  final Map<String, String> bodyTone;

  /// anchors (512 캔버스 좌표)
  final Map<String, (double, double)> anchors;

  /// contrast_rules.`<tone>`: category -> 템플릿("{id}_light")
  final Map<String, Map<String, String>> toneVariants;

  /// 대비 규칙 적용: 어두운 몸이면 eyes/mouth를 _light 변형으로 (변형 없으면 원본)
  String resolve(String category, String id, String? bodyId) {
    final tone = bodyTone[bodyId];
    final tpl = tone == null ? null : toneVariants[tone]?[category];
    if (tpl == null) return id;
    final v = tpl.replaceAll('{id}', id);
    return parts.containsKey(v) ? v : id;
  }

  /// 편집기 노출용(_light 변형 제외)
  List<AvatarPart> byCategory(String c) =>
      parts.values.where((p) => p.category == c && !p.variant).toList();

  factory AvatarManifest.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final parts = <String, AvatarPart>{
      for (final p in (m['parts'] as List))
        (p['id'] as String): AvatarPart.fromJson(p as Map<String, dynamic>),
    };
    final cr = (m['contrast_rules'] as Map?) ?? const {};
    final lv = (m['light_variants'] as Map?) ?? const {};
    lv.forEach((cat, ids) {
      for (final id in (ids as List).cast<String>()) {
        parts.putIfAbsent(
          id,
          () => AvatarPart(
            id: id,
            category: cat as String,
            file: 'parts/$cat/$id.svg',
            variant: true,
          ),
        );
      }
    });
    final cons = m['constraints'] is List
        ? (m['constraints'] as List)
              .map((c) => AvatarConstraint.fromJson(c as Map<String, dynamic>))
              .toList()
        : kDefaultConstraints;
    return AvatarManifest(
      layerOrder: (m['layer_order_bottom_to_top'] as List).cast<String>(),
      defaults: (m['default'] as Map).cast<String, String>(),
      parts: parts,
      constraints: cons,
      anchors: {
        for (final e in ((m['anchors'] as Map?) ?? const {}).entries)
          e.key as String: (
            (e.value[0] as num).toDouble(),
            (e.value[1] as num).toDouble(),
          ),
      },
      bodyTone: ((cr['body_tone'] as Map?) ?? const {}).cast<String, String>(),
      toneVariants: {
        for (final e in cr.entries)
          if (e.value is Map && e.key != 'body_tone')
            e.key as String: (e.value as Map).cast<String, String>(),
      },
    );
  }

  /// 저장값 정리: 없는/잘못된 파츠는 기본값으로
  Map<String, String> normalize(Object? raw) {
    final m = raw is Map ? raw : const {};
    return {
      for (final c in layerOrder)
        if (c != 'fx')
          c: (m[c] is String && parts[m[c]]?.category == c)
              ? m[c] as String
              : (defaults[c] ?? ''),
    }..removeWhere((_, v) => v.isEmpty);
  }

  /// 선택 조합에 맞는 색 치환표
  Map<String, Map<String, String>> recolorsFor(Map<String, String> sel) {
    final out = <String, Map<String, String>>{};
    for (final c in constraints.where((c) => c.matches(sel))) {
      c.recolor.forEach((cat, map) => (out[cat] ??= {}).addAll(map));
    }
    return out;
  }
}

AvatarManifest? _cached;
final _svgCache = <String, String>{};

Future<AvatarManifest> loadAvatarManifest() async =>
    _cached ??= AvatarManifest.parse(
      await rootBundle.loadString('assets/avatar/manifest.json'),
    );

Future<String> loadPartSvg(AvatarPart p) async => _svgCache[p.file] ??=
    await rootBundle.loadString('assets/avatar/${p.file}');

String applyRecolor(String svg, Map<String, String>? map) {
  if (map == null) return svg;
  var s = svg;
  map.forEach(
    (from, to) =>
        s = s.replaceAll(RegExp(RegExp.escape(from), caseSensitive: false), to),
  );
  return s;
}
