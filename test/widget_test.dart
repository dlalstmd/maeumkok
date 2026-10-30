import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/day_count.dart';
import 'package:maeumkok_app/core/emotions.dart';
import 'package:maeumkok_app/core/header_prefs.dart';
import 'package:maeumkok_app/core/lucide_map.dart';
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

  test('d-day formats', () {
    final s = DateTime(2026, 6, 24);
    final now = DateTime(2026, 10, 30);
    expect(formatDDay(s, now, DDayFormat.dPlus), 'D+129');
    expect(
      formatDDay(s, now, DDayFormat.dPlus, countStartAsDayOne: false),
      'D+128',
    );
    expect(formatDDay(s, now, DDayFormat.days), '129일째');
    expect(
      formatDDay(s, now, DDayFormat.monthsDays, countStartAsDayOne: false),
      '4개월 6일',
    );
    expect(formatDDay(s, now, DDayFormat.hidden), isNull);
    expect(formatDDay(s, DateTime(2026, 6, 24, 23), DDayFormat.dPlus), 'D+1');
  });

  test('header prefs roundtrip', () {
    final p = HeaderPrefs.fromUser({
      'startDate': '2026-06-24',
      'dDayFormat': 'days',
    });
    expect(p.startDate, DateTime(2026, 6, 24));
    expect(p.format, DDayFormat.days);
    expect(p.title('지우'), '지우랑');
    expect(p.toFirestore()['startDate'], '2026-06-24');
    expect(p.subtitle(DateTime(2026, 10, 30)), '2026.06.24부터 · 129일째');
  });

  test('every emotion icon is mapped', () {
    final list = parseEmotions(File('assets/emotions.json').readAsStringSync());
    for (final e in list) {
      expect(
        kLucideIcons.containsKey(e.icon!.replaceFirst('lucide:', '')),
        isTrue,
        reason: e.id,
      );
    }
  });
}
