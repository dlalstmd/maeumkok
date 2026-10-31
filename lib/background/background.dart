import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 메인 배경 v5 (assets/backgrounds/backgrounds.json, 콕디자인)
class BgItem {
  const BgItem({
    required this.id,
    required this.category,
    required this.name,
    required this.asset,
    required this.ink,
    this.sub,
    this.motion,
    this.timeOfDay,
    this.thumb,
  });
  final String id, category, name, asset, ink;
  final String? sub, motion, timeOfDay, thumb;
  bool get lightInk => ink == 'light';

  /// 앱 asset 경로(카탈로그의 assets/x.svg → assets/backgrounds/x.svg)
  String get path => 'assets/backgrounds/${asset.replaceFirst('assets/', '')}';
  String? get thumbPath => thumb == null
      ? null
      : 'assets/backgrounds/${thumb!.replaceFirst('assets/', '')}';

  factory BgItem.fromJson(Map j) => BgItem(
    id: j['id'] as String,
    category: j['category'] as String,
    name: j['name'] as String,
    asset: j['asset'] as String,
    ink: (j['ink'] as String?) ?? 'dark',
    sub: j['sub'] as String?,
    motion: j['motion'] as String?,
    timeOfDay: j['time_of_day'] as String?,
    thumb: j['thumb'] as String?,
  );
}

class TodSet {
  const TodSet(this.id, this.name, this.slots);
  final String id, name;
  final Map<String, String> slots; // dawn/day/sunset/night → bg id
}

class BgCatalog {
  BgCatalog({
    required this.items,
    required this.todSets,
    required this.slotStarts,
    this.dimDefault = 0.25,
    this.dimMax = 0.6,
    this.blurDefault = 8,
    this.blurMax = 24,
    this.maxPx = 2160,
    this.patternZoom = 2,
  });
  final List<BgItem> items;
  final List<TodSet> todSets;

  /// 슬롯 시작 시(기기 현지 시각): dawn 5, day 9, sunset 17, night 20
  final Map<String, int> slotStarts;
  final double dimDefault, dimMax, blurDefault, blurMax, patternZoom;
  final int maxPx;

  static const categories = {
    'solid': '단색',
    'gradient': '그라데이션',
    'pattern': '패턴',
    'illustration': '일러스트',
  };

  BgItem? byId(String id) {
    for (final b in items) {
      if (b.id == id) return b;
    }
    return null;
  }

  TodSet? todById(String id) {
    for (final t in todSets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// 현지 시각 → 슬롯
  String slotAt(DateTime local) {
    final h = local.hour;
    final order = slotStarts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    var cur = order.last.key; // 자정~첫 슬롯 전은 마지막(night)
    for (final e in order) {
      if (h >= e.value) cur = e.key;
    }
    return cur;
  }

  static BgCatalog parse(String json) {
    final d = jsonDecode(json) as Map;
    final slots = <String, int>{};
    ((d['time_slots_local'] as Map?) ?? const {}).forEach((k, v) {
      slots[k as String] = int.parse((v as String).substring(0, 2));
    });
    final photo = (d['photo'] as Map?) ?? const {};
    num n(Object? x, num def) => x is num ? x : def;
    final dr = (photo['dim_range'] as List?) ?? const [0, 0.6];
    final br = (photo['blur_range'] as List?) ?? const [0, 24];
    return BgCatalog(
      items: [
        for (final b in (d['backgrounds'] as List).cast<Map>())
          BgItem.fromJson(b),
      ],
      todSets: [
        for (final t
            in ((d['time_of_day_sets'] as List?) ?? const []).cast<Map>())
          TodSet(
            t['id'] as String,
            t['name'] as String,
            (t['slots'] as Map).cast<String, String>(),
          ),
      ],
      slotStarts: slots.isEmpty
          ? const {'dawn': 5, 'day': 9, 'sunset': 17, 'night': 20}
          : slots,
      dimDefault: n(photo['dim_default'], 0.25).toDouble(),
      dimMax: n(dr.last, 0.6).toDouble(),
      blurDefault: n(photo['blur_default'], 8).toDouble(),
      blurMax: n(br.last, 24).toDouble(),
      maxPx: n(photo['max_px'], 2160).toInt(),
      patternZoom: n(
        ((d['thumbnail_rule'] as Map?)?['pattern'] as Map?)?['zoom'],
        2,
      ).toDouble(),
    );
  }

  static BgCatalog? _cache;
  static Future<BgCatalog> load() async => _cache ??= parse(
    await rootBundle.loadString('assets/backgrounds/backgrounds.json'),
  );
}

class BgPhoto {
  const BgPhoto({
    required this.url,
    required this.path,
    this.dim = 0.25,
    this.blur = 8,
    this.lightInk = true,
  });
  final String url, path;
  final double dim, blur;

  /// 글자색 자동(dim≥0.35 또는 평균 휘도<0.5 → light)
  final bool lightInk;

  Map<String, Object?> toJson() => {
    'url': url,
    'path': path,
    'dim': dim,
    'blur': blur,
    'lightInk': lightInk,
  };
  static BgPhoto? fromJson(Object? j) {
    if (j is! Map || j['url'] is! String) return null;
    return BgPhoto(
      url: j['url'] as String,
      path: (j['path'] as String?) ?? '',
      dim: ((j['dim'] as num?) ?? 0.25).toDouble(),
      blur: ((j['blur'] as num?) ?? 8).toDouble(),
      lightInk: j['lightInk'] != false,
    );
  }

  BgPhoto copyWith({
    double? dim,
    double? blur,
    bool? lightInk,
    String? url,
    String? path,
  }) => BgPhoto(
    url: url ?? this.url,
    path: path ?? this.path,
    dim: dim ?? this.dim,
    blur: blur ?? this.blur,
    lightInk: lightInk ?? this.lightInk,
  );
}

/// 글자색 자동 규칙
bool autoLightInk(double dim, double avgLuminance) =>
    dim >= 0.35 || avgLuminance < 0.5;

/// users/{uid}.background · couples/{id}.background
class BgChoice {
  const BgChoice({
    required this.type,
    required this.id,
    this.photo,
    this.motion = true,
    this.updatedBy,
  });
  final String type; // preset | tod | photo
  final String id;
  final BgPhoto? photo;
  final bool motion;
  final String? updatedBy;

  static const fallback = BgChoice(type: 'tod', id: 'tod_gradient');

  Map<String, Object?> toJson(String uid) => {
    'type': type,
    'id': id,
    'photo': photo?.toJson(),
    'motion': motion,
    'updatedBy': uid,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static BgChoice fromJson(Object? j) {
    if (j is! Map || j['type'] is! String || j['id'] is! String)
      return fallback;
    return BgChoice(
      type: j['type'] as String,
      id: j['id'] as String,
      photo: BgPhoto.fromJson(j['photo']),
      motion: j['motion'] != false,
      updatedBy: j['updatedBy'] as String?,
    );
  }

  BgChoice copyWith({String? type, String? id, BgPhoto? photo, bool? motion}) =>
      BgChoice(
        type: type ?? this.type,
        id: id ?? this.id,
        photo: photo ?? this.photo,
        motion: motion ?? this.motion,
      );
}

/// 지금 보여줄 배경(사진이면 item null)
class ResolvedBg {
  const ResolvedBg({
    this.item,
    this.photo,
    required this.lightInk,
    this.motion,
  });
  final BgItem? item;
  final BgPhoto? photo;
  final bool lightInk;
  final String? motion;
}

ResolvedBg resolveBg(BgCatalog c, BgChoice ch, DateTime local) {
  if (ch.type == 'photo' && ch.photo != null) {
    return ResolvedBg(photo: ch.photo, lightInk: ch.photo!.lightInk);
  }
  BgItem? it;
  if (ch.type == 'tod') {
    final set = c.todById(ch.id) ?? c.todById('tod_gradient');
    final id = set?.slots[c.slotAt(local)];
    if (id != null) it = c.byId(id);
  } else {
    it = c.byId(ch.id);
  }
  it ??=
      c.byId(c.todById('tod_gradient')?.slots[c.slotAt(local)] ?? '') ??
      (c.items.isEmpty ? null : c.items.first);
  return ResolvedBg(
    item: it,
    lightInk: it?.lightInk ?? false,
    motion: it?.motion,
  );
}

/// 같이 쓰기면 커플 배경, 아니면 내 배경
BgChoice effectiveChoice({
  required Object? mine,
  required Map<String, dynamic>? couple,
}) {
  if (couple?['backgroundShared'] == true && couple?['background'] != null) {
    return BgChoice.fromJson(couple!['background']);
  }
  return BgChoice.fromJson(mine);
}

class BackgroundService {
  BackgroundService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _dbArg = db,
      _storage = storage;
  final FirebaseFirestore? _dbArg;
  final FirebaseStorage? _storage;
  FirebaseFirestore get _db => _dbArg ?? FirebaseFirestore.instance;
  FirebaseStorage get _st => _storage ?? FirebaseStorage.instance;

  Future<void> saveMine(String uid, BgChoice c) =>
      _db.collection('users').doc(uid).update({'background': c.toJson(uid)});

  /// 같이 쓰기 켜기/끄기
  Future<void> setShared(
    String coupleId,
    String uid,
    bool on,
    BgChoice current,
  ) => _db.collection('couples').doc(coupleId).update({
    'backgroundShared': on,
    if (on) 'background': current.toJson(uid),
  });

  /// 같이 쓰기 중 변경: 커플 배경 + 타임라인 기록(푸시 없음)
  Future<void> saveShared(String coupleId, String uid, BgChoice c) async {
    final b = _db.batch();
    b.update(_db.collection('couples').doc(coupleId), {
      'background': c.toJson(uid),
    });
    b.set(
      _db.collection('couples').doc(coupleId).collection('emotions').doc(),
      {
        'senderUid': uid,
        'emotionId': kBgChangedEventId,
        'count': 1,
        'snapshot': {
          'label': '배경을 바꿨어요',
          'icon': 'lucide:image',
          'animationKey': '',
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await b.commit();
  }

  /// 내 사진 업로드(개인 Storage). 이미 2160px 이하 JPEG로 줄인 바이트.
  Future<BgPhoto> uploadMine(
    String uid,
    Uint8List jpg, {
    double dim = 0.25,
    double blur = 8,
  }) async {
    final id = 'photo_${DateTime.now().millisecondsSinceEpoch}';
    final path = 'users/$uid/backgrounds/$id.jpg';
    final ref = _st.ref(path);
    await ref.putData(jpg, SettableMetadata(contentType: 'image/jpeg'));
    final lum = await averageLuminance(jpg);
    return BgPhoto(
      url: await ref.getDownloadURL(),
      path: path,
      dim: dim,
      blur: blur,
      lightInk: autoLightInk(dim, lum),
    );
  }

  /// 같이 쓰기 확인 후 couples 경로로 복사
  Future<BgPhoto> copyToCouple(String coupleId, BgPhoto p) async {
    final data = await _st.ref(p.path).getData(12 * 1024 * 1024);
    if (data == null) throw StateError('사진을 불러오지 못했어요');
    final path = 'couples/$coupleId/backgrounds/${p.path.split('/').last}';
    final ref = _st.ref(path);
    await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
    return p.copyWith(url: await ref.getDownloadURL(), path: path);
  }
}

/// 타임라인 전용 시스템 이벤트(푸시·진동·반응 없음)
const kBgChangedEventId = 'sys_bg_changed';
bool isSystemEvent(String emotionId) => emotionId.startsWith('sys_');

Future<double> averageLuminance(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 32);
    final img = (await codec.getNextFrame()).image;
    final data = await img.toByteData();
    if (data == null) return 0.5;
    var sum = 0.0;
    final n = data.lengthInBytes ~/ 4;
    for (var i = 0; i < n; i++) {
      final r = data.getUint8(i * 4),
          g = data.getUint8(i * 4 + 1),
          b = data.getUint8(i * 4 + 2);
      sum += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
    }
    return n == 0 ? 0.5 : sum / n;
  } catch (_) {
    return 0.5;
  }
}

/// 헤더·아이콘 색
Color inkColor(bool light, {bool sub = false}) => light
    ? (sub ? const Color(0xB8FFFFFF) : Colors.white)
    : (sub ? const Color(0xFF6B6B6B) : const Color(0xFF111111));

/// 메인 배경 그리기: SVG cover / 사진(흐림·어둡게) + 은은한 움직임 + 아바타 뒤 scrim
class MainBackground extends StatefulWidget {
  const MainBackground({
    super.key,
    required this.resolved,
    this.motion = true,
    this.scrimCenter = const Alignment(0, -0.45),
    this.thumb = false,
  });
  final ResolvedBg resolved;
  final bool motion;
  final Alignment scrimCenter;
  final bool thumb;

  @override
  State<MainBackground> createState() => _MainBackgroundState();
}

class _MainBackgroundState extends State<MainBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    _foreground = s == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MainBackground old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _animate =>
      widget.motion &&
      !widget.thumb &&
      _foreground &&
      widget.resolved.motion != null &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  void _sync() {
    if (!mounted) return;
    if (_animate) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop(); // 정지 프레임
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resolved;
    Widget base;
    if (r.photo != null) {
      final p = r.photo!;
      base = Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: p.blur / 2,
              sigmaY: p.blur / 2,
            ),
            child: Image.network(
              p.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF2B2B2B)),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: p.dim)),
        ],
      );
    } else if (r.item != null) {
      base = SvgPicture.asset(r.item!.path, fit: BoxFit.cover);
    } else {
      base = const ColoredBox(color: Color(0xFFFAFAFA));
    }
    final motion = r.motion;
    Widget out = base;
    if (motion != null && !widget.thumb) {
      out = AnimatedBuilder(
        animation: _c,
        builder: (_, child) => _withMotion(motion, _c.value, child!),
        child: base,
      );
    }
    if (widget.thumb) return ClipRect(child: out);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(child: out),
        // 아바타 뒤 radial scrim 18%
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: widget.scrimCenter,
                radius: 0.6,
                colors: [
                  (r.lightInk ? Colors.black : Colors.white).withValues(
                    alpha: 0.18,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (motion != null && _particles(motion) > 0)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(
                painter: _ParticlePainter(motion, _c.value, r.lightInk),
              ),
            ),
          ),
      ],
    );
  }

  /// t: 0~1 (60초 주기)
  Widget _withMotion(String m, double t, Widget child) {
    final w = 2 * math.pi;
    switch (m) {
      case 'drift': // 60초 주기 8px
        return Transform.translate(
          offset: Offset(8 * math.sin(w * t), 8 * math.cos(w * t)),
          child: Transform.scale(scale: 1.04, child: child),
        );
      case 'gradient_shift': // 20초 주기 ±6%
        return Transform.translate(
          offset: Offset(0, 0.06 * 300 * math.sin(w * t * 3)),
          child: Transform.scale(scale: 1.15, child: child),
        );
      case 'clouds_drift': // 40초 주기
        return Transform.translate(
          offset: Offset(10 * math.sin(w * t * 1.5), 0),
          child: Transform.scale(scale: 1.06, child: child),
        );
      case 'waves': // y ±3px 6초
        return Transform.translate(
          offset: Offset(0, 3 * math.sin(w * t * 10)),
          child: Transform.scale(scale: 1.02, child: child),
        );
      case 'aurora': // opacity 0.5↔0.8 10초 근사
      case 'rain':
        return Opacity(opacity: 0.9 + 0.1 * math.sin(w * t * 6), child: child);
      default:
        return child;
    }
  }
}

int _particles(String m) => switch (m) {
  'fall_petals' || 'fall_leaves' => 8,
  'snowfall' => 20,
  'twinkle' => 12,
  'shooting_star' => 1,
  _ => 0,
};

/// 입자(최대 20개). 시드 고정이라 프레임마다 같은 입자.
class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.motion, this.t, this.light);
  final String motion;
  final double t;
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final n = _particles(motion);
    final r = math.Random(7);
    final p = Paint();
    for (var i = 0; i < n; i++) {
      final x0 = r.nextDouble() * size.width;
      final ph = r.nextDouble();
      switch (motion) {
        case 'snowfall':
          final y = ((ph + t * 5) % 1) * size.height;
          p.color = Colors.white.withValues(alpha: 0.8);
          canvas.drawCircle(
            Offset(x0 + 6 * math.sin((t * 20 + ph) * 6), y),
            1.5 + r.nextDouble(),
            p,
          );
        case 'fall_petals' || 'fall_leaves':
          final y = ((ph + t * 5) % 1) * (size.height + 20) - 10;
          p.color =
              (motion == 'fall_petals'
                      ? const Color(0xFFF7B6C2)
                      : const Color(0xFFE0A060))
                  .withValues(alpha: 0.7);
          canvas.save();
          canvas.translate(x0 + 14 * math.sin((t * 10 + ph) * 6), y);
          canvas.rotate((t * 20 + ph) * 6);
          canvas.drawOval(const Rect.fromLTWH(-4, -2.5, 8, 5), p);
          canvas.restore();
        case 'twinkle':
          final y = r.nextDouble() * size.height * 0.6;
          final a =
              0.5 + 0.5 * (0.5 + 0.5 * math.sin((t * 20 + ph) * 2 * math.pi));
          p.color = Colors.white.withValues(alpha: 0.1 * a + (light ? 0.5 : 0));
          canvas.drawCircle(Offset(x0, y), 1.2, p);
        case 'shooting_star':
          // 45초마다 1.2초
          final cyc = (t * 60) % 45;
          if (cyc < 1.2) {
            final u = cyc / 1.2;
            p
              ..color = Colors.white.withValues(alpha: 1 - u)
              ..strokeWidth = 1.5;
            final s = Offset(
              size.width * (0.2 + 0.6 * u),
              size.height * (0.1 + 0.15 * u),
            );
            canvas.drawLine(s, s - const Offset(40, 14), p);
          }
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.t != t || o.motion != motion;
}

/// 피커 썸네일: 패턴은 thumb 에셋을 2배 확대, 나머지는 원본
class BgThumb extends StatelessWidget {
  const BgThumb(this.item, {super.key, this.zoom = 2});
  final BgItem item;
  final double zoom;
  @override
  Widget build(BuildContext context) {
    final tp = item.category == 'pattern' ? item.thumbPath : null;
    final pic = SvgPicture.asset(tp ?? item.path, fit: BoxFit.cover);
    return ClipRect(
      child: tp == null ? pic : Transform.scale(scale: zoom, child: pic),
    );
  }
}
