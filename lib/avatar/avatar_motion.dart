/// emotions.json `animation_key` → 1차 Flutter 모션(flutter_animate) 매핑.
/// 콕디자인 모션 스펙이 오면 이 표만 조정한다.
enum AvatarMotion { bounce, droop, shake, nod, pulse, wobble, sway }

class MotionSpec {
  const MotionSpec(this.motion, {this.fx, this.eyes, this.mouth});
  final AvatarMotion motion;
  final String? fx; // fx 파츠 id
  final String? eyes; // 표정 오버라이드
  final String? mouth;
}

const _table = <String, MotionSpec>{
  'joy_bounce': MotionSpec(AvatarMotion.bounce, fx: 'fx_sparkle', eyes: 'eyes_smile', mouth: 'mouth_grin'),
  'jump': MotionSpec(AvatarMotion.bounce, eyes: 'eyes_smile', mouth: 'mouth_grin'),
  'cheer': MotionSpec(AvatarMotion.bounce, fx: 'fx_sparkle', eyes: 'eyes_sparkle'),
  'cheers': MotionSpec(AvatarMotion.bounce, fx: 'fx_sparkle', eyes: 'eyes_smile'),
  'sparkle': MotionSpec(AvatarMotion.pulse, fx: 'fx_sparkle', eyes: 'eyes_sparkle'),
  'flex': MotionSpec(AvatarMotion.pulse, fx: 'fx_sparkle', mouth: 'mouth_grin'),
  'cry': MotionSpec(AvatarMotion.droop, fx: 'fx_tear', eyes: 'eyes_teary', mouth: 'mouth_flat'),
  'droop': MotionSpec(AvatarMotion.droop, eyes: 'eyes_teary', mouth: 'mouth_flat'),
  'longing': MotionSpec(AvatarMotion.droop, eyes: 'eyes_teary'),
  'slump': MotionSpec(AvatarMotion.droop, eyes: 'eyes_line', mouth: 'mouth_flat'),
  'sigh': MotionSpec(AvatarMotion.droop, eyes: 'eyes_line', mouth: 'mouth_o'),
  'fume': MotionSpec(AvatarMotion.shake, fx: 'fx_steam', mouth: 'mouth_pout'),
  'pout': MotionSpec(AvatarMotion.shake, mouth: 'mouth_pout'),
  'shiver': MotionSpec(AvatarMotion.shake, eyes: 'eyes_x', mouth: 'mouth_flat'),
  'sweat': MotionSpec(AvatarMotion.shake, fx: 'fx_sweat', mouth: 'mouth_o'),
  'rush': MotionSpec(AvatarMotion.shake, fx: 'fx_sweat'),
  'doze': MotionSpec(AvatarMotion.nod, fx: 'fx_zzz', eyes: 'eyes_sleepy'),
  'sleep_wave': MotionSpec(AvatarMotion.nod, fx: 'fx_zzz', eyes: 'eyes_sleepy'),
  'lie_down': MotionSpec(AvatarMotion.nod, fx: 'fx_zzz', eyes: 'eyes_line'),
  'dream': MotionSpec(AvatarMotion.sway, fx: 'fx_zzz', eyes: 'eyes_line'),
  'daydream': MotionSpec(AvatarMotion.sway, eyes: 'eyes_sparkle'),
  'heart_pop': MotionSpec(AvatarMotion.pulse, fx: 'fx_heart', eyes: 'eyes_smile'),
  'kiss': MotionSpec(AvatarMotion.pulse, fx: 'fx_heart', mouth: 'mouth_pout'),
  'arms_open': MotionSpec(AvatarMotion.bounce, fx: 'fx_heart', eyes: 'eyes_smile'),
  'sick_wobble': MotionSpec(AvatarMotion.wobble, fx: 'fx_sweat', eyes: 'eyes_line', mouth: 'mouth_flat'),
  'head_hold': MotionSpec(AvatarMotion.wobble, eyes: 'eyes_x', mouth: 'mouth_flat'),
  'tummy': MotionSpec(AvatarMotion.wobble, mouth: 'mouth_o'),
  'tummy_pat': MotionSpec(AvatarMotion.wobble, eyes: 'eyes_smile'),
  'drool': MotionSpec(AvatarMotion.sway, mouth: 'mouth_o'),
};

MotionSpec motionFor(String? animationKey) =>
    _table[animationKey] ?? const MotionSpec(AvatarMotion.sway);
