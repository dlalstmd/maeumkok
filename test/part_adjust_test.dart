import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:maeumkok_app/avatar/avatar_manifest.dart';
import 'package:maeumkok_app/avatar/part_adjust.dart';
import 'package:maeumkok_app/screens/avatar_edit_screen.dart';

void main() {
  test('범위 제한과 JSON 왕복', () {
    final a = const PartAdjust(
      dx: 999,
      scale: 9,
      rotate: 270,
      stretchX: 0.1,
    ).clamped();
    expect(a.dx, PartAdjust.maxOffset);
    expect(a.scale, PartAdjust.maxScale);
    expect(a.rotate, -90);
    expect(a.stretchX, PartAdjust.minStretch);
    expect(PartAdjust.fromJson(a.toJson()), a);
    expect(PartAdjust.fromJson('bad'), PartAdjust.none);
  });

  test('저장 시 기본값 제외, 최대 10개, 현재 액세서리 유지', () {
    final m = {
      for (var i = 0; i < 12; i++) 'acc_$i': PartAdjust(dx: i + 1.0),
      'acc_zero': PartAdjust.none,
    };
    final j = adjustsToJson(m, keep: 'acc_11');
    expect(j.length, 10);
    expect(j.containsKey('acc_11'), isTrue);
    expect(j.containsKey('acc_zero'), isFalse);
    expect(parseAdjusts(j)['acc_11']!.dx, 12);
  });

  final m = AvatarManifest.parse(
    File('assets/avatar/manifest.json').readAsStringSync(),
  );
  final hats = m.byCategory('accessory').where((p) => p.subtype == 'hat');
  final pins = m.byCategory('accessory').where((p) => p.subtype == 'hairpin');

  test('v3 액세서리: 최대 4개, 모자는 1개만(교체)', () {
    var l = <String>[];
    l = m.addAccessory(l, hats.first.id);
    l = m.addAccessory(l, hats.elementAt(1).id);
    expect(l, [hats.elementAt(1).id]);
    for (final p in pins.take(4)) {
      l = m.addAccessory(l, p.id);
    }
    expect(l.length, 4);
  });

  test('v2 저장값(accessory) 이전 + 어두운 몸은 눈·입·눈썹 밝은 버전', () {
    final sel = m.normalize({'accessory': 'acc_ribbon', 'body': 'body_mocha'});
    expect(m.accessoriesOf(sel), ['acc_ribbon']);
    expect(m.resolve('eyes', 'eyes_dot', 'body_mocha'), 'eyes_dot_light');
    expect(
      m.resolve('brows', 'brows_arch', 'body_charcoal'),
      'brows_arch_light',
    );
    expect(m.resolve('eyes', 'eyes_dot', 'body_white'), 'eyes_dot');
  });

  test('anchor_rules 범위로 clamp', () {
    final r = m.ruleForPart(hats.first.id);
    final a = const PartAdjust(scale: 3, rotate: 90).clampTo(r);
    expect(a.scale, r.scaleMax);
    expect(a.rotate, r.rotMax);
  });

  testWidgets('편집기: 슬라이더·드래그로 조절하고 avatarAdjust로 저장', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    Map<String, Object?>? saved;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => AvatarEditScreen(
                    uid: 'u',
                    initial: const {'accessories': 'acc_ribbon'},
                    onSave: (d) async => saved = d,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await t.pump(const Duration(seconds: 1));
    await t.dragUntilVisible(
      find.text('꾸미기'),
      find.text('몸 색'),
      const Offset(-150, 0),
    );
    await t.pump();
    await t.tap(find.text('꾸미기'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('adjScale')), findsOneWidget);
    await t.drag(find.byKey(const Key('adjScale')), const Offset(80, 0));
    await t.drag(find.byKey(const Key('avatarPreview')), const Offset(40, 20));
    await t.pump();
    await t.tap(find.text('저장'));
    await t.pump(const Duration(milliseconds: 300));
    final adj = parseAdjusts(saved!['avatarAdjust'])['acc_ribbon']!;
    expect(adj.scale, greaterThan(1));
    expect(adj.dx, greaterThan(0));
    expect(adj.dy, greaterThan(0));
  });
}
