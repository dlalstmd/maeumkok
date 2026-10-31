import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/background/background.dart';
import 'package:maeumkok_app/screens/background_picker_screen.dart';

class FakeBg extends BackgroundService {
  final calls = <String>[];
  BgChoice? saved;
  @override
  Future<void> saveMine(String uid, BgChoice c) async {
    calls.add('mine');
    saved = c;
  }

  @override
  Future<void> setShared(
    String coupleId,
    String uid,
    bool on,
    BgChoice current,
  ) async {
    calls.add('shared:$on');
    saved = current;
  }

  @override
  Future<void> saveShared(String coupleId, String uid, BgChoice c) async =>
      calls.add('saveShared');

  @override
  Future<BgPhoto> copyToCouple(String coupleId, BgPhoto p) async {
    calls.add('copy');
    return p.copyWith(path: 'couples/$coupleId/backgrounds/x.jpg');
  }
}

void main() {
  final cat = BgCatalog.parse(
    File('assets/backgrounds/backgrounds.json').readAsStringSync(),
  );

  test('카탈로그: 58개, 세트 4, 기본값', () {
    expect(cat.items.length, 58);
    expect(cat.items.where((b) => b.category == 'pattern').length, 14);
    expect(cat.todSets.length, 4);
    expect(cat.dimDefault, 0.25);
    expect(cat.blurMax, 24);
    expect(cat.maxPx, 2160);
    for (final b in cat.items) {
      expect(File(b.path).existsSync(), isTrue, reason: b.path);
      if (b.thumbPath != null) expect(File(b.thumbPath!).existsSync(), isTrue);
    }
  });

  test('시간대 슬롯(기기 현지 시각)', () {
    String s(int h) => cat.slotAt(DateTime(2026, 1, 1, h));
    expect(
      [s(0), s(4), s(5), s(8), s(9), s(16), s(17), s(19), s(20), s(23)],
      [
        'night',
        'night',
        'dawn',
        'dawn',
        'day',
        'day',
        'sunset',
        'sunset',
        'night',
        'night',
      ],
    );
    final r = resolveBg(cat, BgChoice.fallback, DateTime(2026, 1, 1, 21));
    expect(r.item!.id, 'grad_04');
    expect(r.lightInk, isTrue);
  });

  test('같이 쓰기 꺼짐이면 내 배경, 켜짐이면 커플 배경', () {
    final mine = {'type': 'preset', 'id': 'solid_03'};
    expect(
      effectiveChoice(
        mine: mine,
        couple: {
          'background': {'type': 'preset', 'id': 'solid_13'},
        },
      ).id,
      'solid_03',
    );
    expect(
      effectiveChoice(
        mine: mine,
        couple: {
          'backgroundShared': true,
          'background': {'type': 'preset', 'id': 'solid_13'},
        },
      ).id,
      'solid_13',
    );
    expect(BgChoice.fromJson(null).id, 'tod_gradient');
    expect(autoLightInk(0.4, 0.9), isTrue);
    expect(autoLightInk(0.25, 0.3), isTrue);
    expect(autoLightInk(0.25, 0.8), isFalse);
  });

  test('모든 SVG를 flutter_svg가 읽는다(패턴은 펼친 버전)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final f in Directory(
      'assets/backgrounds',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.svg')) continue;
      final s = f.readAsStringSync();
      expect(s.contains('<pattern'), isFalse, reason: f.path);
      final info = await vg.loadPicture(SvgStringLoader(s), null);
      info.picture.dispose();
    }
  });

  testWidgets('피커: 타일 선택 → 적용하면 내 배경 저장', (t) async {
    final svc = FakeBg();
    await t.pumpWidget(
      MaterialApp(
        home: BackgroundPickerScreen(
          uid: 'u',
          initial: BgChoice.fallback,
          service: svc,
          catalog: cat,
          coupleId: 'c',
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('배경'), findsOneWidget);
    expect(find.text('은은한 움직임'), findsOneWidget);
    expect(find.text('둘이 같이 쓰기'), findsOneWidget);
    await t.tap(find.byKey(const Key('bg:solid_02')));
    await t.pump();
    await t.tap(find.byKey(const Key('applyBg')));
    await t.pump(const Duration(milliseconds: 300));
    expect(svc.calls, ['mine']);
    expect(svc.saved!.type, 'preset');
    expect(svc.saved!.id, 'solid_02');
  });

  testWidgets('피커: 내 사진 + 같이 쓰기 → 확인 후 복사', (t) async {
    final svc = FakeBg();
    await t.pumpWidget(
      MaterialApp(
        home: BackgroundPickerScreen(
          uid: 'u',
          initial: const BgChoice(
            type: 'photo',
            id: 'photo_upload',
            photo: BgPhoto(
              url: 'http://x/y.jpg',
              path: 'users/u/backgrounds/p.jpg',
            ),
          ),
          service: svc,
          catalog: cat,
          coupleId: 'c',
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const Key('sharedToggle')));
    await t.pump();
    await t.tap(find.byKey(const Key('applyBg')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('내 사진을 같이 쓸까요?'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirmSharePhoto')));
    await t.pump(const Duration(milliseconds: 300));
    expect(svc.calls, ['copy', 'shared:true']);
    expect(svc.saved!.photo!.path, startsWith('couples/c/'));
  });
}
