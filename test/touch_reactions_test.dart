import 'dart:io';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/avatar/avatar_motion.dart';
import 'package:maeumkok_app/avatar/touch_reactions.dart';

void main() {
  final table = TouchTable.parse(
    File('assets/avatar/touch_reactions.json').readAsStringSync(),
  );
  const box = Size(240, 240);

  test('표: 제스처 8 × 존 3 = 24 조합, 모션 파일 존재', () {
    expect(table.table.length, 24);
    for (final vs in table.table.values) {
      for (final v in vs) {
        expect(
          File('assets/avatar/motion/${v.motionKey}.json').existsSync(),
          isTrue,
          reason: v.motionKey,
        );
      }
    }
    expect(table.variants('swipe_left', TouchZone.head).first.dir, -1);
  });

  test('존 판정: 얼굴 > 머리 > 몸, 밖은 null', () {
    expect(zoneAt(const Offset(120, 30), box), TouchZone.head);
    expect(zoneAt(const Offset(120, 110), box), TouchZone.face);
    expect(zoneAt(const Offset(20, 110), box), TouchZone.body);
    expect(zoneAt(const Offset(120, 220), box), TouchZone.body);
    expect(zoneAt(const Offset(300, 120), box), isNull);
  });

  test('변형: 직전 변형 반복 없음', () {
    final p = VariantPicker(Random(1));
    final vs = table.variants('tap', TouchZone.face);
    String? prev;
    for (var i = 0; i < 30; i++) {
      final v = p.pick('k', vs)!;
      expect(v.id, isNot(prev));
      prev = v.id;
    }
  });

  test('햅틱: 120ms 간격, 같은 조합 350ms, 10초 8회 한도, 3초 쉬면 리셋, 끄기', () {
    final g = HapticGovernor();
    expect(g.decide('tap:head', Haptic.light, 0), Haptic.light);
    expect(g.decide('tap:body', Haptic.light, 100), isNull); // <120
    expect(g.decide('tap:head', Haptic.light, 300), isNull); // 같은 조합 <350
    var n = 1;
    for (var t = 400; t < 9000; t += 400) {
      if (g.decide('tap:x$t', Haptic.light, t) != null) n++;
    }
    expect(n, 8);
    expect(g.decide('tap:y', Haptic.light, 13000), Haptic.light); // 3초 무입력 리셋
    g.enabled = false;
    expect(g.decide('tap:z', Haptic.light, 14000), isNull);
  });

  test('연타 6회/3초 → 어지러움 1회, 8초 비활성·selection 강등', () {
    final g = HapticGovernor();
    var eggs = 0;
    for (var i = 0; i < 6; i++) {
      if (g.registerTap(i * 200)) eggs++;
    }
    expect(eggs, 1);
    for (var i = 0; i < 10; i++) {
      expect(g.registerTap(2000 + i * 100), isFalse);
    }
    expect(g.decide('tap:head', Haptic.light, 5000), Haptic.selection);
  });

  test('제스처 판정: 탭·더블탭·스와이프 위·쓰다듬기', () async {
    final out = <String>[];
    final c = GestureClassifier(
      onGesture: (g, _, {strokeTick = false}) => out.add(g),
    );
    c.down(const Offset(100, 100), 0);
    c.up(const Offset(101, 100), 100);
    c.down(const Offset(100, 100), 250);
    c.up(const Offset(100, 100), 330);
    expect(out, ['tap', 'double_tap']);
    out.clear();
    c.down(const Offset(100, 200), 1000);
    c.move(const Offset(100, 150), 1040);
    c.up(const Offset(100, 100), 1080);
    expect(out, ['swipe_up']);
    out.clear();
    c.down(const Offset(100, 50), 2000);
    var x = 100.0, t = 2000;
    for (final dx in [30.0, -30.0, 30.0, -30.0]) {
      for (var i = 0; i < 6; i++) {
        x += dx / 6;
        t += 30;
        c.move(Offset(x, 50), t);
      }
    }
    c.up(Offset(x, 50), t + 10);
    expect(out.where((g) => g == 'stroke'), isNotEmpty);
    expect(out.last, 'release');
    c.dispose();
  });

  test('slide 방향 반전, scale_x/y 파싱', () {
    final s = AvatarMotionSpec.parse(
      File('assets/avatar/motion/squish.json').readAsStringSync(),
    );
    final k = sampleKfs(s.layers['body_group']!.keyframes, 0.35);
    expect(k.sx, closeTo(1.12, 1e-6));
    expect(k.sy, closeTo(0.86, 1e-6));
    final sl = AvatarMotionSpec.parse(
      File('assets/avatar/motion/slide.json').readAsStringSync(),
    );
    final a = sampleKfs(sl.layers['body_group']!.keyframes, 0.3);
    expect(sl.baseDir, -1); // 원본은 왼쪽 → 오른쪽(dir 1)이면 반전
    expect(a.mirrored(1).tx, a.tx);
    expect(a.mirrored(-1).tx, -a.tx);
  });
}
