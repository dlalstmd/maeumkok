import 'dart:math' as math;

import 'avatar_manifest.dart';

/// 액세서리별 위치·크기·회전·모양(가로 늘이기) 조절값. 512 캔버스 단위.
/// Firestore: users/{uid}.avatarAdjust = `{partId: {dx, dy, s, r, sx, f}}`
/// (manifest v3 editor_transform_schema x,y,scale,rotation,flipX 대응: dx/dy는 기본위치 대비 이동)
class PartAdjust {
  const PartAdjust({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotate = 0,
    this.stretchX = 1,
    this.flipX = false,
  });
  final bool flipX;
  final double dx, dy; // -160..160
  final double scale; // 0.5..2.0
  final double rotate; // -180..180 (deg)
  final double stretchX; // 0.6..1.6 (가로/세로 비율 변형)

  static const none = PartAdjust();
  static const minScale = 0.5, maxScale = 2.0;
  static const maxOffset = 160.0;
  static const minStretch = 0.6, maxStretch = 1.6;

  bool get isIdentity =>
      dx == 0 &&
      dy == 0 &&
      scale == 1 &&
      rotate == 0 &&
      stretchX == 1 &&
      !flipX;

  PartAdjust copyWith({
    double? dx,
    double? dy,
    double? scale,
    double? rotate,
    double? stretchX,
    bool? flipX,
  }) => PartAdjust(
    flipX: flipX ?? this.flipX,
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
    scale: scale ?? this.scale,
    rotate: rotate ?? this.rotate,
    stretchX: stretchX ?? this.stretchX,
  ).clamped();

  PartAdjust clamped() {
    var r = rotate % 360;
    if (r > 180) r -= 360;
    if (r < -180) r += 360;
    return PartAdjust(
      dx: dx.clamp(-maxOffset, maxOffset),
      dy: dy.clamp(-maxOffset, maxOffset),
      scale: scale.clamp(minScale, maxScale),
      rotate: r,
      stretchX: stretchX.clamp(minStretch, maxStretch),
      flipX: flipX,
    );
  }

  /// manifest anchor_rules 범위로 제한 (이동 불가면 위치 고정)
  PartAdjust clampTo(AnchorRule r) {
    final c = clamped();
    return PartAdjust(
      dx: r.movable ? c.dx : 0,
      dy: r.movable ? c.dy : 0,
      scale: c.scale.clamp(r.scaleMin, r.scaleMax),
      rotate: c.rotate.clamp(r.rotMin, r.rotMax),
      stretchX: c.stretchX,
      flipX: c.flipX,
    );
  }

  static double _n(Object? v, double d) =>
      v is num && v.isFinite ? v.toDouble() : d;

  factory PartAdjust.fromJson(Object? j) {
    if (j is! Map) return none;
    return PartAdjust(
      dx: _n(j['dx'], 0),
      dy: _n(j['dy'], 0),
      scale: _n(j['s'], 1),
      rotate: _n(j['r'], 0),
      stretchX: _n(j['sx'], 1),
      flipX: j['f'] == true || j['f'] == 1,
    ).clamped();
  }

  Map<String, num> toJson() {
    double r2(double v) => (v * 100).roundToDouble() / 100;
    return {
      'dx': r2(dx),
      'dy': r2(dy),
      's': r2(scale),
      'r': r2(rotate),
      'sx': r2(stretchX),
      if (flipX) 'f': 1,
    };
  }

  double get radians => rotate * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is PartAdjust &&
      other.dx == dx &&
      other.dy == dy &&
      other.scale == scale &&
      other.rotate == rotate &&
      other.stretchX == stretchX &&
      other.flipX == flipX;
  @override
  int get hashCode => Object.hash(dx, dy, scale, rotate, stretchX, flipX);
}

/// Firestore 값 → {partId: PartAdjust}
Map<String, PartAdjust> parseAdjusts(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (e.key is String) e.key as String: PartAdjust.fromJson(e.value),
  };
}

/// 저장용: 기본값은 빼고, 최대 10개(규칙 제한)만 유지. [keep]은 반드시 포함.
Map<String, Map<String, num>> adjustsToJson(
  Map<String, PartAdjust> m, {
  String? keep,
}) {
  final entries = m.entries.where((e) => !e.value.isIdentity).toList();
  entries.sort(
    (a, b) => (a.key == keep ? 0 : 1).compareTo(b.key == keep ? 0 : 1),
  );
  return {for (final e in entries.take(10)) e.key: e.value.toJson()};
}
