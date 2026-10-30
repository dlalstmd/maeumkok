// 생성됨: emotions.json의 lucide 아이콘 이름 → IconData. 새 아이콘 추가 시 여기에 한 줄 추가.
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Map<String, IconData> kLucideIcons = {
  'angry': LucideIcons.angry,
  'battery-low': LucideIcons.batteryLow,
  'bed': LucideIcons.bed,
  'brain-circuit': LucideIcons.brainCircuit,
  'cake-slice': LucideIcons.cakeSlice,
  'clapperboard': LucideIcons.clapperboard,
  'cloud-lightning': LucideIcons.cloudLightning,
  'cloud-rain': LucideIcons.cloudRain,
  'cookie': LucideIcons.cookie,
  'dumbbell': LucideIcons.dumbbell,
  'eye': LucideIcons.eye,
  'flame': LucideIcons.flame,
  'flower': LucideIcons.flower,
  'footprints': LucideIcons.footprints,
  'frown': LucideIcons.frown,
  'gamepad-2': LucideIcons.gamepad2,
  'hand-heart': LucideIcons.handHeart,
  'heart': LucideIcons.heart,
  'heart-crack': LucideIcons.heartCrack,
  'hourglass': LucideIcons.hourglass,
  'leaf': LucideIcons.leaf,
  'medal': LucideIcons.medal,
  'meh': LucideIcons.meh,
  'message-circle-heart': LucideIcons.messageCircleHeart,
  'moon': LucideIcons.moon,
  'moon-star': LucideIcons.moonStar,
  'party-popper': LucideIcons.partyPopper,
  'phone': LucideIcons.phone,
  'plane': LucideIcons.plane,
  'smile': LucideIcons.smile,
  'snowflake': LucideIcons.snowflake,
  'sparkles': LucideIcons.sparkles,
  'sun': LucideIcons.sun,
  'thermometer': LucideIcons.thermometer,
  'thumbs-up': LucideIcons.thumbsUp,
  'timer': LucideIcons.timer,
  'trophy': LucideIcons.trophy,
  'utensils': LucideIcons.utensils,
  'wine': LucideIcons.wine,
  'zap': LucideIcons.zap,
};

IconData lucideIcon(String? ref) {
  final key = ref?.replaceFirst('lucide:', '');
  return kLucideIcons[key] ?? LucideIcons.circle;
}
