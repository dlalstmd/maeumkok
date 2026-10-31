import 'dart:convert';

import 'package:flutter/animation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// assets/avatar/motion/`<key>`.json (콕디자인) 키프레임 모션.
/// 좌표 단위는 512 캔버스, rotate는 degree.
class Kf {
  const Kf(
    this.t,
    this.scale,
    this.rotate,
    this.tx,
    this.ty,
    this.opacity,
    this.curve,
  );
  final double t, scale, rotate, tx, ty, opacity;
  final Curve curve;

  factory Kf.fromJson(Map j) {
    double n(String k, double d) => (j[k] as num?)?.toDouble() ?? d;
    return Kf(
      n('t', 0),
      n('scale', 1),
      n('rotate', 0),
      n('tx', 0),
      n('ty', 0),
      n('opacity', 1),
      _curve(j['curve'] as String?),
    );
  }
}

Curve _curve(String? c) => switch (c) {
  'linear' => Curves.linear,
  'easeOut' => Curves.easeOut,
  'easeOutBack' => Curves.easeOutBack,
  'easeIn' => Curves.easeIn,
  _ => Curves.easeInOut,
};

/// t(0..1) 시점의 보간값
Kf sampleKfs(List<Kf> k, double t) {
  if (k.isEmpty) return const Kf(0, 1, 0, 0, 0, 1, Curves.linear);
  if (t <= k.first.t) return k.first;
  for (var i = 0; i < k.length - 1; i++) {
    final a = k[i], b = k[i + 1];
    if (t <= b.t) {
      final span = b.t - a.t;
      final u = span <= 0
          ? 1.0
          : b.curve.transform(((t - a.t) / span).clamp(0.0, 1.0));
      double l(double x, double y) => x + (y - x) * u;
      return Kf(
        t,
        l(a.scale, b.scale),
        l(a.rotate, b.rotate),
        l(a.tx, b.tx),
        l(a.ty, b.ty),
        l(a.opacity, b.opacity).clamp(0.0, 1.0),
        Curves.linear,
      );
    }
  }
  return k.last;
}

class MotionLayer {
  MotionLayer(this.keyframes, {this.part, this.anchor, this.swaps = const []});
  final List<Kf> keyframes;
  final String? part; // fx 파츠
  final String? anchor;
  final List<(double, String)> swaps; // (t, partId | '@base')
}

class AvatarMotionSpec {
  AvatarMotionSpec({
    required this.key,
    required this.duration,
    required this.loop,
    required this.pivot,
    required this.layers,
    this.swap = const {},
    this.blink = false,
  });
  final String key;
  final Duration duration;
  final bool loop;
  final String pivot;
  final Map<String, MotionLayer> layers; // body_group / fx / eyes
  final Map<String, String> swap; // part_swap: eyes/mouth
  final bool blink;

  factory AvatarMotionSpec.parse(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final layers = <String, MotionLayer>{};
    (m['layers'] as Map).forEach((name, l) {
      final lm = l as Map;
      layers[name as String] = MotionLayer(
        [
          for (final k in (lm['keyframes'] as List? ?? const []))
            Kf.fromJson(k as Map),
        ],
        part: lm['part'] as String?,
        anchor: lm['anchor'] as String?,
        swaps: [
          for (final s in (lm['swap'] as List? ?? const []))
            ((s['t'] as num).toDouble(), s['part'] as String),
        ],
      );
    });
    final ps = (m['part_swap'] as Map?) ?? const {};
    return AvatarMotionSpec(
      key: m['key'] as String,
      duration: Duration(milliseconds: (m['duration_ms'] as num).toInt()),
      loop: m['loop'] == true,
      pivot: (m['pivot'] as String?) ?? 'pivot_bottom',
      layers: layers,
      swap: {
        for (final c in const ['eyes', 'mouth', 'brows'])
          if (ps[c] is String) c: ps[c] as String,
      },
      blink: m['blink'] == true,
    );
  }
}

final _motionCache = <String, AvatarMotionSpec?>{};

/// 키에 맞는 모션. 없으면 null (호출측에서 idle 폴백)
Future<AvatarMotionSpec?> loadMotion(String key) async {
  if (_motionCache.containsKey(key)) return _motionCache[key];
  try {
    return _motionCache[key] = AvatarMotionSpec.parse(
      await rootBundle.loadString('assets/avatar/motion/$key.json'),
    );
  } catch (_) {
    return _motionCache[key] = null;
  }
}
