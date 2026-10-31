import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/emotions.dart';
import 'package:maeumkok_app/screens/custom_emotion_screen.dart';
import 'package:maeumkok_app/services/emotion_prefs_service.dart';

void main() {
  setUpAll(
    () =>
        loadEmotionsFromString(File('assets/emotions.json').readAsStringSync()),
  );
  tearDown(() => kCustomEmotions = {});

  test('v4.1: 80개, 소분류 12개, 이름 6자 이하, 트리의 id는 모두 존재', () {
    expect(kEmotions.length, 80);
    expect(kCategoryTree.expand((c) => c.subcategories).length, 12);
    expect(kCustomLabelMaxChars, 6);
    for (final e in kEmotions) {
      expect(e.label.characters.length, lessThanOrEqualTo(6), reason: e.id);
    }
    for (final id
        in kCategoryTree
            .expand((c) => c.subcategories)
            .expand((s) => s.emotionIds)) {
      expect(emotionById(id), isNotNull, reason: id);
    }
    expect(kVibrationPresets['heart'], isNotEmpty);
  });

  test('빠진 miss_you 기록도 표시된다', () {
    expect(kEmotions.any((e) => e.id == 'miss_you'), isFalse);
    expect(emotionById('miss_you')?.label, '보고싶어');
    expect(emotionById('miss_you')!.reactions, hasLength(2));
  });

  test('삭제/모르는 커스텀 감정은 메시지 스냅샷으로 표시', () {
    final e = emotionFor('custom_zz', {
      'label': '야근 중',
      'icon': 'lucide:laptop',
      'animationKey': 'rush',
      'vibrationName': 'buzz',
    });
    expect(e!.label, '야근 중');
    expect(e.vibrationPattern, kVibrationPresets['buzz']);
    expect(emotionFor('nope', null), isNull);
  });

  test('커스텀 문서 파싱·스냅샷·반응 기본값', () {
    final c = customFromDoc('custom_1', {
      'label': '치킨',
      'glyphType': 'emoji',
      'emoji': '🍗',
      'category': 'want',
      'vibrationName': 'double',
      'animationKey': 'drool',
      'reactions': [],
    });
    expect(c.custom, isTrue);
    expect(c.usesEmoji, isTrue);
    expect(c.reactions.map((r) => r.label), ['고마워', '나도!']);
    expect(c.toSnapshot(), containsPair('emoji', '🍗'));
    final r = customFromDoc('custom_2', {
      'label': 'x',
      'glyphType': 'icon',
      'icon': 'lucide:mic',
      'reactions': ['힘내'],
    });
    expect(r.reactions.single.label, '힘내');
  });

  test('추천 반응 정리: 1~12자, 최대 3개', () {
    expect(cleanReactions([' a ', '', 'b', 'c', 'd']), ['a', 'b', 'c']);
    expect(cleanReactions(['열세글자가넘는추천반응문구야']), isEmpty);
  });

  test('즐겨찾기: 중복·삭제·없는 감정 제거, 최대 24', () {
    kCustomEmotions = {
      'custom_del': customFromDoc('custom_del', {
        'label': 'd',
        'glyphType': 'icon',
        'deleted': true,
      }),
    };
    final ids = [
      'happy',
      'happy',
      'custom_del',
      'ghost',
      ...kEmotions.map((e) => e.id),
    ];
    final f = cleanFavorites(ids);
    expect(f.first, 'happy');
    expect(f, isNot(contains('custom_del')));
    expect(f.length, kMaxFavorites);
  });

  test('최근: 맨 앞, 중복 제거, 최대 12', () {
    var l = <RecentItem>[];
    for (var i = 0; i < 20; i++) {
      l = pushRecent(l, 'e${i % 15}', DateTime(2026, 1, 1, 0, i));
    }
    l = pushRecent(l, 'e10', DateTime(2026, 2, 1));
    expect(l.length, 12);
    expect(l.first.emotionId, 'e10');
    expect(l.where((r) => r.emotionId == 'e10').length, 1);
  });

  testWidgets('만들기: 이름은 6자에서 막히고 n/6 표시, 저장 시 초안 전달', (t) async {
    CustomEmotionDraft? saved;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) =>
                    CustomEmotionScreen(onSave: (d) async => saved = d),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('우리 감정 만들기'), findsOneWidget);
    await t.enterText(find.byKey(const Key('nameField')), '야근중이에요진짜');
    await t.pump();
    expect(find.text('야근중이에요'), findsNWidgets(2)); // 입력칸 + 미리보기
    expect(find.text('6/6'), findsOneWidget);
    await t.tap(find.byKey(const Key('cat:body')));
    await t.tap(find.byKey(const Key('vib:buzz')));
    await t.pump();
    await t.tap(find.byKey(const Key('saveCustom')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(saved!.label, '야근중이에요');
    expect(saved!.category, 'body');
    expect(saved!.vibrationName, 'buzz');
    expect(saved!.reactions, ['고마워', '나도!']);
  });

  testWidgets('편집: 감정 삭제 → 확인 문구 → 삭제 호출', (t) async {
    var deleted = false;
    final e = customFromDoc('custom_1', {
      'label': '야근 중',
      'glyphType': 'icon',
      'icon': 'lucide:laptop',
      'category': 'body',
    });
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => CustomEmotionScreen(
                  initial: e,
                  partnerName: '지우',
                  onSave: (_) async {},
                  onDelete: () async => deleted = true,
                ),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    await t.scrollUntilVisible(
      find.byKey(const Key('deleteCustom')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await t.pump();
    await t.tap(find.byKey(const Key('deleteCustom')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('지우와 나 모두에게서 사라지고'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirmDelete')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(deleted, isTrue);
  });
}
