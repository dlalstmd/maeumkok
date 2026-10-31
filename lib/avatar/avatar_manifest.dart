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
    this.subtype,
    this.variant = false,
  });
  final String? subtype;
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
    subtype: j['subtype'] as String?,
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
const kCustomizableCategories = [
  'body',
  'hair',
  'clothes',
  'eyes',
  'brows',
  'mouth',
  'blush',
  'accessory',
];
const kCategoryLabels = {
  'body': '몸 색',
  'hair': '헤어',
  'clothes': '옷',
  'brows': '눈썹',
  'eyes': '눈',
  'mouth': '입',
  'blush': '볼터치',
  'accessory': '꾸미기',
};

/// 선택 맵에서 액세서리 목록 키 (쉼표 구분 문자열로 저장)
const kAccessoriesKey = 'accessories';

/// manifest v3 anchor_rules 한 항목 (512 캔버스 좌표)
class AnchorRule {
  const AnchorRule({
    this.anchor = (256, 256),
    this.scaleMin = 0.5,
    this.scaleMax = 2,
    this.rotMin = -180,
    this.rotMax = 180,
    this.movable = true,
    this.z = 0,
  });
  final (double, double) anchor;
  final double scaleMin, scaleMax, rotMin, rotMax;
  final bool movable;
  final int z;

  static double _d(Object? v, double d) => v is num ? v.toDouble() : d;
  factory AnchorRule.fromJson(Map j) {
    final a = (j['anchor'] as List?) ?? const [256, 256];
    final sr = (j['scale_range'] as List?) ?? const [0.5, 2];
    final rr = (j['rotation_range_deg'] as List?) ?? const [-180, 180];
    return AnchorRule(
      anchor: (_d(a[0], 256), _d(a[1], 256)),
      scaleMin: _d(sr[0], 0.5),
      scaleMax: _d(sr[1], 2),
      rotMin: _d(rr[0], -180),
      rotMax: _d(rr[1], 180),
      movable: j['movable'] != false,
      z: (j['z'] as num?)?.toInt() ?? 0,
    );
  }
}

class AvatarManifest {
  AvatarManifest({
    required this.layerOrder,
    required this.defaults,
    required this.parts,
    required this.constraints,
    this.bodyTone = const {},
    this.anchors = const {},
    this.toneVariants = const {},
    this.anchorRules = const {},
    this.subtypeLayer = const {},
    this.maxAccessories = 4,
    this.onePerSubtype = const {},
  });
  final Map<String, AnchorRule> anchorRules;

  /// accessory_slots.subtype_layer: subtype -> 레이어 이름(acc_hat 등)
  final Map<String, String> subtypeLayer;
  final int maxAccessories;
  final Set<String> onePerSubtype;

  /// 액세서리 파츠의 레이어 이름
  String? accLayerOf(String partId) {
    final st = parts[partId]?.subtype;
    return st == null ? null : subtypeLayer[st];
  }

  AnchorRule ruleForPart(String partId) =>
      anchorRules[accLayerOf(partId)] ?? const AnchorRule();

  /// 선택 맵의 액세서리 목록 (없는 파츠 제외, 규칙 위반분 정리)
  List<String> accessoriesOf(Map<String, String> sel) {
    final raw = (sel[kAccessoriesKey] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty);
    var out = <String>[];
    for (final id in raw) {
      out = addAccessory(out, id);
    }
    return out;
  }

  /// 액세서리 추가: 최대 [maxAccessories]개, 모자·안경·목도리는 같은 종류 교체
  List<String> addAccessory(List<String> cur, String id) {
    final p = parts[id];
    if (p == null ||
        p.category != 'accessory' ||
        subtypeLayer[p.subtype] == null) {
      return cur;
    }
    if (cur.contains(id)) return cur;
    var next = [...cur];
    if (onePerSubtype.contains(p.subtype)) {
      next.removeWhere((x) => parts[x]?.subtype == p.subtype);
    }
    if (next.length >= maxAccessories) return cur;
    return next..add(id);
  }

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
  List<AvatarPart> byCategory(String c) => parts.values
      .where((p) => p.category == c && !p.variant && p.subtype != 'none')
      .toList();

  /// 한 개만 고르는 카테고리(몸·헤어·옷·눈·눈썹·입·볼터치·그림자)
  Iterable<String> get singleCategories =>
      layerOrder.where((c) => c != 'fx' && !c.startsWith('acc_'));

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
    final slots = (m['accessory_slots'] as Map?) ?? const {};
    final cons = m['constraints'] is List
        ? (m['constraints'] as List)
              .map((c) => AvatarConstraint.fromJson(c as Map<String, dynamic>))
              .toList()
        : kDefaultConstraints;
    return AvatarManifest(
      layerOrder: (m['layer_order_bottom_to_top'] as List).cast<String>(),
      defaults: {
        for (final e in (m['default'] as Map).entries)
          if (e.value is String) e.key as String: e.value as String,
      },
      anchorRules: {
        for (final e in ((m['anchor_rules'] as Map?) ?? const {}).entries)
          if (e.value is Map)
            e.key as String: AnchorRule.fromJson(e.value as Map),
      },
      subtypeLayer: ((slots['subtype_layer'] as Map?) ?? const {})
          .cast<String, String>(),
      maxAccessories: (slots['max_total'] as num?)?.toInt() ?? 4,
      onePerSubtype: ((slots['one_per_subtype'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
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
    final out = {
      for (final c in singleCategories)
        c: (m[c] is String && parts[m[c]]?.category == c)
            ? m[c] as String
            : (defaults[c] ?? ''),
    }..removeWhere((_, v) => v.isEmpty);
    // v2 저장값(accessory 단일) 이전
    final legacy = m['accessory'];
    final accRaw = m[kAccessoriesKey] is String
        ? m[kAccessoriesKey] as String
        : (legacy is String ? legacy : '');
    final acc = accessoriesOf({kAccessoriesKey: accRaw});
    if (acc.isNotEmpty) out[kAccessoriesKey] = acc.join(',');
    return out;
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
