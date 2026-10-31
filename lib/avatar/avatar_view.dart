import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'avatar_manifest.dart';
import 'avatar_motion.dart';
import 'part_adjust.dart';

/// 레이어별 변환 (512 캔버스 단위)
typedef LayerFx = Kf;

/// 파츠 SVG를 manifest 레이어 순서대로 Stack.
/// [overrides]로 eyes/mouth 교체, [fxPart]로 fx 표시. 대비 규칙 자동 적용.
class AvatarLayers extends StatelessWidget {
  const AvatarLayers({
    super.key,
    required this.manifest,
    required this.selection,
    this.overrides = const {},
    this.fxPart,
    this.body,
    this.fx,
    this.size = 220,
    this.adjusts = const {},
  });
  final Map<String, PartAdjust> adjusts;
  final AvatarManifest manifest;
  final Map<String, String> selection;
  final Map<String, String> overrides;
  final String? fxPart;
  final Kf? body; // body_group 변환
  final Kf? fx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = manifest;
    final sel = m.normalize(selection);
    final recolors = m.recolorsFor(sel);
    final unit = size / 512;
    final pv = m.anchors['pivot_bottom'] ?? (256.0, 404.0);
    final pivot = Alignment(pv.$1 / 256 - 1, pv.$2 / 256 - 1);
    final group = <Widget>[];
    Widget? shadow, fxW;
    final accs = m.accessoriesOf(sel);
    for (final cat in m.layerOrder) {
      if (cat.startsWith('acc_')) {
        for (final id in accs) {
          if (m.accLayerOf(id) != cat) continue;
          final p = m.parts[id];
          if (p == null) continue;
          final rule = m.ruleForPart(id);
          final adj = (adjusts[id] ?? PartAdjust.none).clampTo(rule);
          final a = rule.anchor;
          group.add(
            adjustPart(
              _Part(part: p, key: ValueKey('$cat:$id')),
              adj,
              unit,
              Alignment(a.$1 / 256 - 1, a.$2 / 256 - 1),
              ValueKey('adj:$id'),
            ),
          );
        }
        continue;
      }
      String? id = cat == 'fx' ? fxPart : (overrides[cat] ?? sel[cat]);
      if (id == null) continue;
      id = m.resolve(cat, id, sel['body']);
      final p = m.parts[id];
      if (p == null) continue;
      final Widget w = _Part(
        part: p,
        recolor: recolors[cat],
        key: ValueKey('$cat:$id'),
      );
      if (cat == 'shadow') {
        shadow = w;
      } else if (cat == 'fx') {
        fxW = _xf(w, fx, unit, Alignment.center);
      } else {
        group.add(w);
      }
    }
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?shadow,
          _xf(Stack(fit: StackFit.expand, children: group), body, unit, pivot),
          ?fxW,
        ],
      ),
    );
  }

  static Widget _xf(Widget w, Kf? k, double unit, Alignment pivot) {
    if (k == null) return w;
    return Opacity(
      opacity: k.opacity,
      child: Transform.translate(
        offset: Offset(k.tx * unit, k.ty * unit),
        child: Transform.rotate(
          angle: k.rotate * math.pi / 180,
          alignment: pivot,
          child: Transform.scale(scale: k.scale, alignment: pivot, child: w),
        ),
      ),
    );
  }
}

/// 액세서리 조절값 적용: 기준점(anchor) 중심으로 회전·크기·가로 늘이기·좌우 반전 후 이동
Widget adjustPart(
  Widget w,
  PartAdjust a,
  double unit, [
  Alignment pivot = Alignment.center,
  Key? key,
]) {
  if (a.isIdentity) return KeyedSubtree(key: key, child: w);
  return Transform.translate(
    key: key,
    offset: Offset(a.dx * unit, a.dy * unit),
    child: Transform.rotate(
      angle: a.radians,
      alignment: pivot,
      child: Transform(
        alignment: pivot,
        transform: Matrix4.diagonal3Values(
          a.scale * a.stretchX * (a.flipX ? -1 : 1),
          a.scale,
          1,
        ),
        child: w,
      ),
    ),
  );
}

class _Part extends StatelessWidget {
  const _Part({super.key, required this.part, this.recolor});
  final AvatarPart part;
  final Map<String, String>? recolor;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: loadPartSvg(part),
    builder: (context, s) => s.hasData
        ? SvgPicture.string(applyRecolor(s.data!, recolor))
        : const SizedBox.shrink(),
  );
}

/// 정적 아바타 (편집기 썸네일 등)
class StaticAvatar extends StatelessWidget {
  const StaticAvatar({
    super.key,
    required this.selection,
    this.size = 72,
    this.adjusts = const {},
  });
  final Map<String, String> selection;
  final Map<String, PartAdjust> adjusts;
  final double size;

  @override
  Widget build(BuildContext context) => FutureBuilder<AvatarManifest>(
    future: loadAvatarManifest(),
    builder: (context, s) => s.hasData
        ? AvatarLayers(
            manifest: s.data!,
            selection: selection,
            size: size,
            adjusts: adjusts,
          )
        : SizedBox.square(dimension: size),
  );
}

/// 살아있는 아바타: idle 루프 + 랜덤 blink + 감정 모션 재생.
/// [playKey]가 [playToken] 변경 시 1회(루프 모션은 ~2.4초) 재생 후 idle 복귀.
class LiveAvatar extends StatefulWidget {
  const LiveAvatar({
    super.key,
    required this.selection,
    this.size = 220,
    this.playKey,
    this.playToken,
    this.adjusts = const {},
  });
  final Map<String, PartAdjust> adjusts;
  final Map<String, String> selection;
  final double size;
  final String? playKey;
  final Object? playToken;

  @override
  State<LiveAvatar> createState() => _LiveAvatarState();
}

class _LiveAvatarState extends State<LiveAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  final _rand = math.Random();
  AvatarManifest? _m;
  AvatarMotionSpec? _idle, _spec;
  Duration _blinkDur = const Duration(milliseconds: 220);
  Timer? _blinkTimer, _endTimer;
  bool _blinking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final m = await loadAvatarManifest();
    final idle = await loadMotion('idle');
    final blink = await loadMotion('blink');
    if (!mounted) return;
    setState(() {
      _m = m;
      _idle = idle;
      if (blink != null) _blinkDur = blink.duration;
    });
    _toIdle();
    _scheduleBlink();
    if (widget.playToken != null) _play();
  }

  @override
  void didUpdateWidget(LiveAvatar old) {
    super.didUpdateWidget(old);
    if (widget.playToken != null && widget.playToken != old.playToken) _play();
  }

  void _toIdle() {
    _endTimer?.cancel();
    setState(() => _spec = _idle);
    final d = _idle?.duration ?? const Duration(milliseconds: 2400);
    _c
      ..duration = d
      ..repeat();
  }

  Future<void> _play() async {
    final key = widget.playKey;
    if (key == null || _m == null) return;
    final spec = await loadMotion(key);
    if (!mounted) return;
    if (spec == null) return _toIdle(); // 모션 없는 키 → idle 유지
    _endTimer?.cancel();
    setState(() => _spec = spec);
    _c.duration = spec.duration;
    final ms = spec.duration.inMilliseconds;
    final cycles = spec.loop ? math.max(1, (2400 / ms).ceil()) : 1;
    _c.repeat(count: cycles);
    _endTimer = Timer(
      spec.duration * cycles + const Duration(milliseconds: 600),
      () {
        if (mounted) _toIdle();
      },
    );
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + _rand.nextInt(3000)),
      () async {
        if (!mounted) return;
        final allowed = _spec == null || _spec == _idle || _spec!.blink;
        if (allowed) {
          final twice = _rand.nextDouble() < 0.15;
          for (var i = 0; i < (twice ? 2 : 1); i++) {
            setState(() => _blinking = true);
            await Future.delayed(_blinkDur);
            if (!mounted) return;
            setState(() => _blinking = false);
            if (twice) await Future.delayed(const Duration(milliseconds: 140));
          }
        }
        _scheduleBlink();
      },
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _endTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    if (m == null) return SizedBox.square(dimension: widget.size);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = _spec;
        final t = _c.value;
        final overrides = <String, String>{...?s?.swap};
        final eyesLayer = s?.layers['eyes'];
        if (eyesLayer != null) {
          for (final (st, part) in eyesLayer.swaps) {
            if (t >= st) {
              if (part == '@base') {
                overrides.remove('eyes');
              } else {
                overrides['eyes'] = part;
              }
            }
          }
        }
        if (_blinking) overrides['eyes'] = 'eyes_line';
        final fx = s?.layers['fx'];
        final bg = s?.layers['body_group'];
        return AvatarLayers(
          manifest: m,
          selection: widget.selection,
          size: widget.size,
          adjusts: widget.adjusts,
          overrides: overrides,
          body: bg == null ? null : sampleKfs(bg.keyframes, t),
          fxPart: fx?.part,
          fx: fx == null ? null : sampleKfs(fx.keyframes, t),
        );
      },
    );
  }
}
