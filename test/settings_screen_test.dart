import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/screens/settings_screen.dart';

void main() {
  testWidgets('계정 삭제는 확인 후 호출된다', (t) async {
    var called = 0;
    await t.pumpWidget(MaterialApp(
        home: SettingsScreen(
            email: 'a@b.c',
            onSignOut: () async {},
            onDeleteAccount: () async => called++)));
    await t.tap(find.byKey(const Key('deleteAccount')));
    await t.pumpAndSettle();
    await t.tap(find.text('취소'));
    await t.pumpAndSettle();
    expect(called, 0);
    await t.tap(find.byKey(const Key('deleteAccount')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('confirmDelete')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(called, 1);
  });
}
