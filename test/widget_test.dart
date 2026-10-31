import 'dart:convert';

import 'package:maeumkok_app/avatar/avatar_manifest.dart';
import 'package:maeumkok_app/avatar/avatar_motion.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/day_count.dart';
import 'package:maeumkok_app/core/emotions.dart';
import 'package:maeumkok_app/core/header_prefs.dart';
import 'package:maeumkok_app/core/lucide_map.dart';
import 'package:maeumkok_app/core/invite_code.dart';

void main() {
  test('avatar manifest: 기본값 정규화 + charcoal 제약', () {
    final m = AvatarManifest.parse(
      File('assets/avatar/manifest.json').readAsStringSync(),
    );
    final sel = m.normalize({'body': 'body_charcoal', 'eyes': 'nope'});
    expect(sel['eyes'], 'eyes_dot');
    expect(m.resolve('eyes', 'eyes_dot', 'body_charcoal'), 'eyes_dot_light');
    expect(m.resolve('mouth', 'mouth_grin', 'body_mocha'), 'mouth_grin_light');
    expect(m.resolve('eyes', 'eyes_dot', 'body_white'), 'eyes_dot');
    expect(m.byCategory('eyes').any((p) => p.id.endsWith('_light')), isFalse);
    for (final p in m.parts.values) {
      expect(
        File('assets/avatar/${p.file}').existsSync(),
        isTrue,
        reason: p.id,
      );
    }
  });

  test('모든 animation_key에 모션 JSON', () {
    final keys =
        (jsonDecode(File('assets/emotions.json').readAsStringSync())['emotions']
                as List)
            .map((e) => e['animation_key'] as String)
            .toSet()
          ..addAll(['idle', 'blink']);
    for (final k in keys) {
      final spec = AvatarMotionSpec.parse(
        File('assets/avatar/motion/$k.json').readAsStringSync(),
      );
      expect(spec.duration.inMilliseconds, greaterThan(0));
      final bg = spec.layers['body_group'];
      if (bg != null) {
        expect(sampleKfs(bg.keyframes, 0.5).scale, greaterThan(0));
      }
    }
  });

  test('emotions.json parses: 80 unique ids, reactions, vibration', () {
    final list = parseEmotions(File('assets/emotions.json').readAsStringSync());
    expect(list.length, 80);
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
