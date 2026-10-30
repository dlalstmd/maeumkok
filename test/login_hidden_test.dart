import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/screens/login_screen.dart';
import 'package:maeumkok_app/services/auth_service.dart';

class _FakeAuth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('로고 5번 탭 시 심사용 로그인 표시', (t) async {
    await t.pumpWidget(MaterialApp(home: LoginScreen(auth: _FakeAuth())));
    expect(find.byKey(const Key('reviewEmail')), findsNothing);
    for (var i = 0; i < 4; i++) {
      await t.tap(find.byKey(const Key('logo')));
    }
    await t.pump();
    expect(find.byKey(const Key('reviewEmail')), findsNothing);
    await t.tap(find.byKey(const Key('logo')));
    await t.pump();
    expect(find.byKey(const Key('reviewEmail')), findsOneWidget);
  });
}
