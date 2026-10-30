import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/emotions.dart';
import 'package:maeumkok_app/core/invite_code.dart';

void main() {
  test('emotions.json parses: 40 unique ids, reactions, vibration', () {
    final list = parseEmotions(File('assets/emotions.json').readAsStringSync());
    expect(list.length, 40);
    expect(list.map((e) => e.id).toSet().length, list.length);
    for (final e in list) {
      expect(e.reactions, isNotEmpty, reason: e.id);
      expect(e.vibrationPattern, isNotEmpty, reason: e.id);
      expect(e.vibrationPattern.every((v) => v >= 0), isTrue, reason: e.id);
    }
    kEmotions = list;
    expect(emotionById('happy')?.label, '행복해');
    expect(emotionById('nope'), isNull);
  });

  test('invite code validation', () {
    expect(isValidInviteCode('123456'), isTrue);
    expect(isValidInviteCode('123 456'), isTrue);
    expect(isValidInviteCode('12345'), isFalse);
    expect(isValidInviteCode('abcdef'), isFalse);
  });
}
