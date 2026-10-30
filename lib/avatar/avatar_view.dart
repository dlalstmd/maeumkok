import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'avatar_manifest.dart';
import 'avatar_motion.dart';

/// 파츠 SVG를 manifest 레이어 순서대로 Stack. (512x512 동일 캔버스)
class AvatarLayers extends StatefulWidget {
  const AvatarLayers({super.key, required this.selection, this.eyesOverride, this.mouthOverride,
      this.fx, this.size = 220});
  final Map<String, String> selection;
  final String? eyesOverride;
  final String? mouthOverride;
  final String? fx;
  final double size;

  @override
  State<AvatarLayers> createState() => _AvatarLayersState();
}

class _AvatarLayersState extends State<AvatarLayers> {
  AvatarManifest? _m;

  @override
  void initState() {
    super.initState();
    loadAvatarManifest().then((m) {
      if (mounted) setState(() => _m = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    if (m == null) return SizedBox.square(dimension: widget.size);
    final sel = m.normalize(widget.selection);
    final recolors = m.recolorsFor(sel);
    final ids = <String, String?>{
      ...sel,
      if (widget.eyesOverride != null) 'eyes': widget.eyesOverride,
      if (widget.mouthOverride != null) 'mouth': widget.mouthOverride,
      'fx': widget.fx,
    };
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(fit: StackFit.expand, children: [
        for (final cat in m.layerOrder)
          if (ids[cat] != null && m.parts[ids[cat]] != null)
            _Part(part: m.parts[ids[cat]]!, recolor: recolors[cat], key: ValueKey('$cat:${ids[cat]}')),
      ]),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({super.key, required this.part, this.recolor});
  final AvatarPart part;
  final Map<String, String>? recolor;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: loadPartSvg(part),
        builder: (context, s) =>
            s.hasData ? SvgPicture.string(applyRecolor(s.data!, recolor)) : const SizedBox.shrink(),
      );
}

/// 살아있는 아바타: idle 숨쉬기 + 랜덤 눈깜빡임 + 감정 재생(play)
class LiveAvatar extends StatefulWidget {
  const LiveAvatar({super.key, required this.selection, this.size = 220, this.playKey, this.playToken});
  final Map<String, String> selection;
  final double size;

  /// 재생할 animation_key. playToken이 바뀔 때마다 1회 재생.
  final String? playKey;
  final Object? playToken;

  @override
  State<LiveAvatar> createState() => _LiveAvatarState();
}

class _LiveAvatarState extends State<LiveAvatar> {
  final _rand = math.Random();
  Timer? _blink;
  bool _closed = false;
  MotionSpec? _playing;
  int _playId = 0;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
    if (widget.playToken != null) _play();
  }

  @override
  void didUpdateWidget(LiveAvatar old) {
    super.didUpdateWidget(old);
    if (widget.playToken != null && widget.playToken != old.playToken) _play();
  }

  void _scheduleBlink() {
    _blink = Timer(Duration(milliseconds: 2500 + _rand.nextInt(2500)), () async {
      if (!mounted) return;
      final twice = _rand.nextDouble() < 0.15;
      for (var i = 0; i < (twice ? 2 : 1); i++) {
        setState(() => _closed = true);
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() => _closed = false);
        await Future.delayed(const Duration(milliseconds: 120));
      }
      _scheduleBlink();
    });
  }

  void _play() {
    final id = ++_playId;
    setState(() => _playing = motionFor(widget.playKey));
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && id == _playId) setState(() => _playing = null);
    });
  }

  @override
  void dispose() {
    _blink?.cancel();
    super.dispose();
  }

  Widget _motion(Widget child, AvatarMotion m) {
    final a = child.animate(key: ValueKey(_playId));
    switch (m) {
      case AvatarMotion.bounce:
        return a.moveY(begin: 0, end: -18, duration: 220.ms, curve: Curves.easeOut)
            .then().moveY(begin: 0, end: 18, duration: 220.ms, curve: Curves.easeIn)
            .then().moveY(begin: 0, end: -12, duration: 200.ms, curve: Curves.easeOut)
            .then().moveY(begin: 0, end: 12, duration: 200.ms, curve: Curves.easeIn);
      case AvatarMotion.droop:
        return a.moveY(begin: 0, end: 8, duration: 600.ms, curve: Curves.easeInOut)
            .scaleY(begin: 1, end: 0.96, alignment: Alignment.bottomCenter, duration: 600.ms)
            .then(delay: 800.ms).moveY(begin: 0, end: -8, duration: 500.ms);
      case AvatarMotion.shake:
        return a.shakeX(hz: 8, amount: 3, duration: 1200.ms);
      case AvatarMotion.nod:
        return a.rotate(begin: 0, end: 0.02, alignment: Alignment.bottomCenter, duration: 500.ms)
            .then().rotate(begin: 0, end: -0.02, alignment: Alignment.bottomCenter, duration: 500.ms)
            .then().rotate(begin: 0, end: 0.02, alignment: Alignment.bottomCenter, duration: 500.ms);
      case AvatarMotion.pulse:
        return a.scaleXY(begin: 1, end: 1.08, duration: 250.ms).then().scaleXY(begin: 1, end: 1 / 1.08, duration: 250.ms)
            .then().scaleXY(begin: 1, end: 1.06, duration: 250.ms).then().scaleXY(begin: 1, end: 1 / 1.06, duration: 250.ms);
      case AvatarMotion.wobble:
        return a.rotate(begin: -0.015, end: 0.015, alignment: Alignment.bottomCenter, duration: 700.ms, curve: Curves.easeInOut)
            .then().rotate(begin: 0, end: -0.03, alignment: Alignment.bottomCenter, duration: 700.ms);
      case AvatarMotion.sway:
        return a.moveX(begin: -4, end: 4, duration: 700.ms, curve: Curves.easeInOut)
            .then().moveX(begin: 0, end: -8, duration: 700.ms, curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _playing;
    Widget avatar = AvatarLayers(
      selection: widget.selection,
      size: widget.size,
      eyesOverride: _closed ? 'eyes_line' : p?.eyes,
      mouthOverride: p?.mouth,
      fx: p?.fx,
    );
    if (p != null) avatar = _motion(avatar, p.motion);
    // idle 숨쉬기 2.4s: scaleY 1→1.02
    return avatar
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleY(begin: 1, end: 1.02, alignment: Alignment.bottomCenter, duration: 1200.ms, curve: Curves.easeInOut);
  }
}
