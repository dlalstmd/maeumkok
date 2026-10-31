import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'avatar_view.dart';
import 'part_adjust.dart';

/// 아바타 터치 반응 v5 (assets/avatar/touch_reactions.json, 콕디자인)
enum TouchZone { head, face, body }

enum Haptic { selection, light, medium }

class TouchVariant {
  const TouchVariant({
    required this.id,
    required this.motionKey,
    required this.haptic,
    this.weight = 1,
    this.face = const {},
    this.fx,
    this.dir = 1,
  });
  final String id, motionKey;
  final Haptic haptic;
  final double weight;
  final Map<String, String> face;
  final String? fx;
  final double dir;

  factory TouchVariant.fromJson(Map j) => TouchVariant(
    id: j['id'] as String,
    motionKey: j['motion_key'] as String,
    haptic: Haptic.values.firstWhere(
      (h) => h.name == j['haptic'],
      orElse: () => Haptic.light,
    ),
    weight: (j['weight'] as num?)?.toDouble() ?? 1,
    face: ((j['face_override'] as Map?) ?? const {}).cast<String, String>(),
    fx: j['fx'] as String?,
    dir: ((j['params'] as Map?)?['dir'] as num?)?.toDouble() ?? 1,
  );
}

class TouchTable {
  TouchTable(this.table);
  final Map<String, List<TouchVariant>> table; // 'gesture:zone'

  static TouchTable parse(String json) {
    final d = jsonDecode(json) as Map;
    final t = <String, List<TouchVariant>>{};
    for (final r in (d['table'] as List).cast<Map>()) {
      t['${r['gesture']}:${r['zone']}'] = [
        for (final v in (r['variants'] as List).cast<Map>())
          TouchVariant.fromJson(v),
      ];
    }
    return TouchTable(t);
  }

  static TouchTable? _cache;
  static Future<TouchTable> load() async => _cache ??= parse(
    await rootBundle.loadString('assets/avatar/touch_reactions.json'),
  );

  List<TouchVariant> variants(String gesture, TouchZone z) =>
      table['$gesture:${z.name}'] ?? const [];
}

/// 정규화 좌표(0~1)로 존 판정. 겹치면 얼굴 > 머리 > 몸. 밖이면 null.
TouchZone? zoneAt(Offset p, Size box, {double slop = 12}) {
  final sx = slop / box.width, sy = slop / box.height;
  final x = p.dx / box.width, y = p.dy / box.height;
  if (x < -sx || x > 1 + sx || y < -sy || y > 1 + sy) return null;
  if (y >= 0.32 - sy && y <= 0.62 + sy && x >= 0.18 - sx && x <= 0.82 + sx) {
    return TouchZone.face;
  }
  if (y <= 0.32) return TouchZone.head;
  return TouchZone.body;
}

/// 가중 랜덤, 같은 제스처·존에서 직전 변형 제외
class VariantPicker {
  VariantPicker([math.Random? r]) : _r = r ?? math.Random();
  final math.Random _r;
  final _last = <String, String>{};

  TouchVariant? pick(String key, List<TouchVariant> vs) {
    if (vs.isEmpty) return null;
    var pool = vs.where((v) => v.id != _last[key]).toList();
    if (pool.isEmpty) pool = vs;
    final total = pool.fold<double>(0, (a, v) => a + v.weight);
    var x = _r.nextDouble() * total;
    for (final v in pool) {
      x -= v.weight;
      if (x <= 0) return _remember(key, v);
    }
    return _remember(key, pool.last);
  }

  TouchVariant _remember(String key, TouchVariant v) {
    _last[key] = v.id;
    return v;
  }
}

/// 햅틱 쿨다운·한도·연타 이스터에그 (시간은 ms, 테스트에서 주입)
class HapticGovernor {
  HapticGovernor({this.enabled = true});
  bool enabled;
  int? _lastAny;
  final _lastKey = <String, int>{};
  int? _lastStroke;
  final _window = <int>[];
  int? _lastInput;
  bool _overLimit = false;
  final _taps = <int>[];
  int _eggOffUntil = 0;
  int? _strokeStart;
  final _strokeTicks = <int>[];

  /// 연타(3초 6회) → true면 wobble_dizzy 1회. 이후 8초는 이스터에그 끄고 햅틱 selection 강등.
  bool registerTap(int now) {
    _taps
      ..add(now)
      ..removeWhere((t) => now - t > 3000);
    if (now >= _eggOffUntil && _taps.length >= 6) {
      _eggOffUntil = now + 8000;
      _taps.clear();
      return true;
    }
    return false;
  }

  bool demotedAt(int now) => now < _eggOffUntil;

  void strokeEnd() {
    _strokeStart = null;
    _strokeTicks.clear();
  }

  /// 실제로 울릴 강도(null = 생략)
  Haptic? decide(
    String key,
    Haptic h,
    int now, {
    bool stroke = false,
    bool egg = false,
  }) {
    if (_lastInput != null && now - _lastInput! >= 3000) {
      _overLimit = false;
      _window.clear();
    }
    _lastInput = now;
    if (!enabled) return null;
    if (_overLimit) return null;
    if (_lastAny != null && now - _lastAny! < 120) return null;
    if (!egg &&
        _lastKey[key] != null &&
        now - _lastKey[key]! < 350 &&
        !stroke) {
      return null;
    }
    if (stroke) {
      if (_lastStroke != null && now - _lastStroke! < 250) return null;
      _strokeStart ??= now;
      _strokeTicks
        ..add(now)
        ..removeWhere((t) => now - t > 1000);
      if (_strokeTicks.length > 4) return null;
      final dur = now - _strokeStart!;
      if (dur > 1500) {
        // 0.5초 간격으로 감쇠, 3초 넘으면 중단
        if (dur > 3000) return null;
        if (_lastStroke != null && now - _lastStroke! < 500) return null;
      }
      _lastStroke = now;
    }
    _window
      ..add(now)
      ..removeWhere((t) => now - t > 10000);
    if (_window.length > 8) {
      _overLimit = true;
      return null;
    }
    _lastAny = now;
    _lastKey[key] = now;
    if (!egg && demotedAt(now)) return Haptic.selection;
    return h;
  }
}

void fireHaptic(Haptic h) => switch (h) {
  Haptic.selection => HapticFeedback.selectionClick(),
  Haptic.light => HapticFeedback.lightImpact(),
  Haptic.medium => HapticFeedback.mediumImpact(),
};

/// 제스처 판정: tap / double_tap / long_press / stroke / swipe_*
class GestureClassifier {
  GestureClassifier({required this.onGesture});

  /// (gesture, 시작 위치)
  final void Function(String gesture, Offset start, {bool strokeTick})
  onGesture;
  Offset? _down, _last;
  int _downAt = 0, _lastAt = 0;
  int? _lastTapAt;
  Timer? _lp;
  bool _longFired = false, _stroking = false;
  int _dirChanges = 0;
  double _segStartX = 0;
  int _dir = 0;
  final _pts = <(int, Offset)>[];

  void down(Offset p, int now) {
    _down = p;
    _last = p;
    _downAt = now;
    _lastAt = now;
    _longFired = false;
    _stroking = false;
    _dirChanges = 0;
    _dir = 0;
    _segStartX = p.dx;
    _pts
      ..clear()
      ..add((now, p));
    _lp?.cancel();
    _lp = Timer(const Duration(milliseconds: 500), () {
      if (_down != null && (_last! - _down!).distance < 10) {
        _longFired = true;
        onGesture('long_press', _down!);
      }
    });
  }

  void move(Offset p, int now) {
    if (_down == null) return;
    final prev = _last!;
    _last = p;
    _pts.add((now, p));
    _pts.removeWhere((e) => now - e.$1 > 120);
    if ((p - _down!).distance >= 10) _lp?.cancel();
    final dx = p.dx - prev.dx;
    final dt = math.max(1, now - _lastAt);
    _lastAt = now;
    final speed = dx.abs() / dt * 1000;
    final d = dx > 0 ? 1 : (dx < 0 ? -1 : 0);
    if (d != 0 && d != _dir) {
      if (_dir != 0 && (p.dx - _segStartX).abs() >= 24) _dirChanges++;
      if (_dir != 0) _segStartX = prev.dx;
      _dir = d;
    }
    if (_dirChanges >= 2 && speed < 1200) {
      _stroking = true;
      onGesture('stroke', _down!, strokeTick: true);
      _dirChanges = 1; // 다음 방향 전환마다 틱
    }
  }

  /// 반환: 손 뗐을 때 판정된 제스처(없으면 null)
  void up(Offset p, int now) {
    _lp?.cancel();
    final start = _down;
    _down = null;
    if (start == null || _longFired || _stroking) {
      if (_stroking || _longFired) onGesture('release', start ?? p);
      return;
    }
    final delta = p - start;
    final dur = now - _downAt;
    if (dur < 200 && delta.distance < 10) {
      final dbl = _lastTapAt != null && now - _lastTapAt! <= 300;
      _lastTapAt = dbl ? null : now;
      onGesture(dbl ? 'double_tap' : 'tap', start);
      return;
    }
    // 스와이프: 거리 ≥60, 속도 ≥800px/s, 주 방향 ±30°
    final v = delta.distance / math.max(1, dur) * 1000;
    if (delta.distance >= 60 && v >= 800) {
      final ang = math.atan2(delta.dy, delta.dx) * 180 / math.pi;
      String? g;
      if (ang.abs() <= 30) g = 'swipe_right';
      if ((ang.abs() - 180).abs() <= 30) g = 'swipe_left';
      if ((ang - 90).abs() <= 30) g = 'swipe_down';
      if ((ang + 90).abs() <= 30) g = 'swipe_up';
      if (g != null) onGesture(g, start);
    }
  }

  void dispose() => _lp?.cancel();
}

/// 터치하면 반응하는 아바타(메인 화면). 감정 수신 재생은 [playKey]/[playToken].
class TouchAvatar extends StatefulWidget {
  const TouchAvatar({
    super.key,
    required this.selection,
    this.adjusts = const {},
    this.size = 240,
    this.playKey,
    this.playToken,
    this.haptics = true,
    this.semanticsLabel = '내 아바타, 탭하면 반응해요',
  });
  final Map<String, String> selection;
  final Map<String, PartAdjust> adjusts;
  final double size;
  final String? playKey;
  final Object? playToken;
  final bool haptics;
  final String semanticsLabel;

  @override
  State<TouchAvatar> createState() => _TouchAvatarState();
}

class _TouchAvatarState extends State<TouchAvatar> {
  TouchTable? _table;
  final _picker = VariantPicker();
  late final _gov = HapticGovernor(enabled: widget.haptics);
  late final _cls = GestureClassifier(onGesture: _onGesture);
  String? _key;
  Object? _token;
  bool _touch = false;
  Map<String, String> _face = const {};
  String? _fx;
  double _dir = 1;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    TouchTable.load().then((t) {
      if (mounted) setState(() => _table = t);
    });
  }

  @override
  void didUpdateWidget(TouchAvatar old) {
    super.didUpdateWidget(old);
    _gov.enabled = widget.haptics;
    if (widget.playToken != old.playToken && widget.playToken != null) {
      setState(() {
        _key = widget.playKey;
        _token = widget.playToken;
        _touch = false;
        _face = const {};
        _fx = null;
      });
    }
  }

  @override
  void dispose() {
    _cls.dispose();
    super.dispose();
  }

  void _onGesture(String g, Offset start, {bool strokeTick = false}) {
    final t = _table;
    if (t == null) return;
    if (g == 'release') {
      _gov.strokeEnd();
      return;
    }
    final zone = zoneAt(start, Size.square(widget.size));
    if (zone == null) return;
    final now = _now;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    TouchVariant? v;
    var egg = false;
    if (g == 'tap' && _gov.registerTap(now)) {
      egg = true;
      v = const TouchVariant(
        id: 'egg_dizzy',
        motionKey: 'wobble_dizzy',
        haptic: Haptic.medium,
      );
    } else {
      v = _picker.pick('$g:${zone.name}', t.variants(g, zone));
    }
    if (v == null) return;
    final h = _gov.decide(
      '$g:${zone.name}',
      v.haptic,
      now,
      stroke: g == 'stroke',
      egg: egg,
    );
    if (h != null) fireHaptic(h);
    if (g == 'stroke' && _key != null && _touch && _token != null) {
      // 쓰다듬는 동안은 같은 반응 유지(틱만)
      if (_lastStrokeKey == '$g:${zone.name}') return;
    }
    _lastStrokeKey = g == 'stroke' ? '$g:${zone.name}' : null;
    setState(() {
      _touch = true;
      _key = reduce ? 'squish' : v!.motionKey;
      _face = reduce ? const {} : v!.face;
      _fx = reduce ? null : v!.fx;
      _dir = v!.dir;
      _token = Object();
    });
  }

  String? _lastStrokeKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    button: true,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _cls.down(e.localPosition, _now),
      onPointerMove: (e) => _cls.move(e.localPosition, _now),
      onPointerUp: (e) {
        _cls.up(e.localPosition, _now);
        _lastStrokeKey = null;
      },
      onPointerCancel: (e) => _cls.up(e.localPosition, _now),
      child: RawGestureDetector(
        // 상위 스크롤/시트와 경쟁하지 않도록 수평 드래그만 소비
        gestures: {
          HorizontalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                HorizontalDragGestureRecognizer
              >(
                HorizontalDragGestureRecognizer.new,
                (r) => r.onUpdate = (_) {},
              ),
        },
        child: LiveAvatar(
          selection: widget.selection,
          adjusts: widget.adjusts,
          size: widget.size,
          playKey: _key,
          playToken: _token,
          faceOverride: _face,
          playFx: _fx,
          playDir: _dir,
          playIsTouch: _touch,
        ),
      ),
    ),
  );
}
