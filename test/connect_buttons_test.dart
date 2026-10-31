import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/theme.dart';

Widget _row({required bool expanded}) {
  Widget wrap(Widget w) => expanded ? Expanded(child: w) : w;
  return MaterialApp(
    theme: buildTheme(),
    home: Scaffold(
      body: Card(
        child: Column(children: [
          Row(children: [
            wrap(FilledButton(onPressed: () {}, child: const Text('수락'))),
            const SizedBox(width: 8),
            wrap(OutlinedButton(onPressed: () {}, child: const Text('거절'))),
          ]),
        ]),
      ),
    ),
  );
}

void main() {
  testWidgets('앱 테마 버튼을 Row에 그냥 넣으면 레이아웃 오류(버그 재현)', (t) async {
    await t.pumpWidget(_row(expanded: false));
    expect(t.takeException(), isNotNull);
  });

  testWidgets('Expanded로 감싸면 수락/거절 버튼이 보이고 눌린다', (t) async {
    await t.pumpWidget(_row(expanded: true));
    expect(t.takeException(), isNull);
    expect(find.text('수락'), findsOneWidget);
    expect(find.text('거절'), findsOneWidget);
    expect(t.getSize(find.byType(FilledButton)).width, greaterThan(50));
    await t.tap(find.text('수락'));
  });
}
