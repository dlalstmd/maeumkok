import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('온보딩 4장: 다음×3 → 연결 시작하기 → 완료 저장', (t) async {
    SharedPreferences.setMockInitialValues({});
    var done = false;
    await t.pumpWidget(
      MaterialApp(home: OnboardingScreen(onDone: () => done = true)),
    );
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('말하지 않아도\n마음이 콕, 전해져요'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const Key('obNext')));
      for (var f = 0; f < 10; f++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }
    expect(find.text('연결 시작하기'), findsOneWidget);
    expect(find.text('건너뛰기'), findsNothing);
    await t.tap(find.byKey(const Key('obNext')));
    await t.pump(const Duration(milliseconds: 100));
    expect(done, isTrue);
    expect(await onboardingSeen(), isTrue);
  });

  testWidgets('건너뛰기', (t) async {
    SharedPreferences.setMockInitialValues({});
    var done = false;
    await t.pumpWidget(
      MaterialApp(home: OnboardingScreen(onDone: () => done = true)),
    );
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byKey(const Key('obSkip')));
    await t.pump(const Duration(milliseconds: 100));
    expect(done, isTrue);
  });
}
