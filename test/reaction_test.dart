import 'package:flutter_test/flutter_test.dart';
import 'package:maeumkok_app/core/emotions.dart';
import 'package:maeumkok_app/services/emotion_service.dart';

void main() {
  final all = [
    ReactionEvent('r2', 'B', 'e1', '1'),
    ReactionEvent('r1', 'A', 'e1', '0'),
    ReactionEvent('r0', 'B', 'e0', '2'),
  ];
  test('보낸 사람 화면: 상대(B)가 내 감정 e1에 남긴 반응을 찾는다', () {
    expect(reactionFor(all.where((r) => r.senderUid != 'A'), 'e1')?.id, 'r2');
  });
  test('반응한 사람 화면: 내(B) 반응을 찾는다', () {
    expect(reactionFor(all, 'e0', senderUid: 'B')?.reactionId, '2');
    expect(reactionFor(all, 'e9', senderUid: 'B'), isNull);
  });
  test('반응 id → 문구', () {
    const e = Emotion(
      id: 'sleepy',
      label: '졸려',
      emoji: '',
      category: 'body',
      categoryLabel: '몸',
      icon: '',
      reactions: [Reaction('0', '토닥토닥'), Reaction('1', '얼른 자~')],
      vibrationPattern: [0, 400],
      animationKey: 'doze',
    );
    expect(reactionLabel(e, '1'), '얼른 자~');
    expect(reactionLabel(null, '1'), '1');
  });
}
