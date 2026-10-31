import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/screens/couple_home_screen.dart';

void main() {
  test('같은 감정 연타는 디바운스 뒤 1번, count 누적(최대 99)', () async {
    final out = <(String, int)>[];
    final b = TapBurst(
      onFlush: (id, n) => out.add((id, n)),
      debounce: const Duration(milliseconds: 50),
    );
    for (var i = 0; i < 5; i++) {
      b.tap('happy');
    }
    expect(b.count, 5);
    expect(out, isEmpty);
    await Future.delayed(const Duration(milliseconds: 120));
    expect(out, [('happy', 5)]);
    for (var i = 0; i < 150; i++) {
      b.tap('sad');
    }
    b.flushNow();
    expect(out.last, ('sad', 99));
  });

  test('다른 감정을 누르면 이전 묶음 즉시 전송', () {
    final out = <(String, int)>[];
    final b = TapBurst(onFlush: (id, n) => out.add((id, n)));
    b
      ..tap('happy')
      ..tap('happy')
      ..tap('sad');
    expect(out, [('happy', 2)]);
    b.flushNow();
    expect(out.last, ('sad', 1));
  });
}
