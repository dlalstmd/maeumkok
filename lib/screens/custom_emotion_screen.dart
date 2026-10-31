import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../avatar/avatar_view.dart';
import '../core/emotions.dart';
import '../core/lucide_map.dart';
import '../core/theme.dart';
import '../services/emotion_prefs_service.dart';

/// 우리 감정 만들기/편집 (v4_custom_01/02)
class CustomEmotionScreen extends StatefulWidget {
  const CustomEmotionScreen({
    super.key,
    this.initial,
    this.initialCategory = 'mood',
    required this.onSave,
    this.onDelete,
    this.onPreview,
    this.avatar = const {},
    this.partnerName = '상대',
  });
  final Emotion? initial;
  final String initialCategory;
  final Future<void> Function(CustomEmotionDraft d) onSave;
  final Future<void> Function()? onDelete;
  final void Function(Emotion e)? onPreview;
  final Map<String, String> avatar;
  final String partnerName;

  @override
  State<CustomEmotionScreen> createState() => _CustomEmotionScreenState();
}

class CustomEmotionDraft {
  CustomEmotionDraft({
    required this.label,
    required this.glyphType,
    this.icon,
    this.emoji,
    required this.category,
    required this.vibrationName,
    required this.animationKey,
    required this.reactions,
  });
  final String label;
  final String glyphType;
  final String? icon;
  final String? emoji;
  final String category;
  final String vibrationName;
  final String animationKey;
  final List<String> reactions;
}

/// 삭제 확인 다이얼로그(v4 문구). true면 삭제.
Future<bool> confirmDeleteCustom(
  BuildContext context,
  String label,
  String partnerName,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('‘$label’을 삭제할까요?'),
      content: Text('$partnerName와 나 모두에게서 사라지고 즐겨찾기에서도 빠져요. 보낸 기록은 남아요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('취소', style: TextStyle(color: MkColors.text)),
        ),
        TextButton(
          key: const Key('confirmDelete'),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('삭제', style: TextStyle(color: MkColors.danger)),
        ),
      ],
    ),
  );
  return ok == true;
}

class _CustomEmotionScreenState extends State<CustomEmotionScreen> {
  late final _name = TextEditingController(text: widget.initial?.label ?? '');
  late String _glyph = (widget.initial?.usesEmoji ?? false) ? 'emoji' : 'icon';
  late String _icon = widget.initial?.icon ?? kCustomIcons.first;
  late String _emoji = (widget.initial?.emoji.isNotEmpty ?? false)
      ? widget.initial!.emoji
      : kCustomEmojis.first;
  late String _cat = widget.initial?.category ?? widget.initialCategory;
  late String _vib = widget.initial?.vibrationName ?? 'short';
  late String _motion = widget.initial?.animationKey ?? 'joy_bounce';
  late final List<String> _reactions = widget.initial == null
      ? [...kDefaultReactionTexts]
      : [for (final r in widget.initial!.reactions) r.label];
  bool _saving = false;
  Object? _playToken;

  bool get _editing => widget.initial != null;
  bool get _valid => _name.text.trim().isNotEmpty;

  Emotion get _preview => Emotion(
    id: widget.initial?.id ?? 'custom_preview',
    label: _name.text.trim().isEmpty ? '이름' : _name.text.trim(),
    emoji: _glyph == 'emoji' ? _emoji : '',
    category: _cat,
    categoryLabel: kCategoryLabels[_cat] ?? '',
    vibrationPattern: kVibrationPresets[_vib] ?? const [0, 40],
    reactions: const [],
    animationKey: _motion,
    icon: _glyph == 'icon' ? _icon : null,
    vibrationName: _vib,
    custom: true,
  );

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        CustomEmotionDraft(
          label: _name.text.trim(),
          glyphType: _glyph,
          icon: _glyph == 'icon' ? _icon : null,
          emoji: _glyph == 'emoji' ? _emoji : null,
          category: _cat,
          vibrationName: _vib,
          animationKey: _motion,
          reactions: cleanReactions(_reactions),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장하지 못했어요: $e')));
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDeleteCustom(
      context,
      widget.initial!.label,
      widget.partnerName,
    );
    if (!ok || !mounted) return;
    await widget.onDelete!();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addReaction() async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('추천 반응 추가'),
        content: TextField(
          key: const Key('reactionField'),
          controller: c,
          autofocus: true,
          maxLength: kCustomReactionMax,
          decoration: const InputDecoration(hintText: '예: 힘내!'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    if (r != null && r.isNotEmpty) setState(() => _reactions.add(r));
  }

  Widget _section(String t, [Widget? trailing]) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Row(
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );

  Widget _pill(
    String label,
    bool sel,
    VoidCallback onTap, {
    Key? key,
    bool dark = false,
  }) => GestureDetector(
    key: key,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: sel
            ? (dark ? MkColors.text : const Color(0xFFFFEDE6))
            : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: sel
              ? (dark ? Colors.white : MkColors.accent)
              : MkColors.textSub,
          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    return Scaffold(
      backgroundColor: MkColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(_editing ? '우리 감정 편집' : '우리 감정 만들기'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MkColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: LiveAvatar(
                    selection: widget.avatar,
                    size: 64,
                    playKey: _motion,
                    playToken: _playToken,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          EmotionGlyph(p, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              p.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '미리보기 · 둘 다 볼 수 있어요',
                        style: TextStyle(fontSize: 12, color: MkColors.textSub),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('previewPlay'),
                  icon: const Icon(LucideIcons.play, color: MkColors.accent),
                  onPressed: () {
                    setState(() => _playToken = Object());
                    widget.onPreview?.call(p);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'icon', label: Text('아이콘')),
              ButtonSegment(value: 'emoji', label: Text('이모지')),
            ],
            selected: {_glyph},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _glyph = s.first),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in _glyph == 'icon' ? kCustomIcons : kCustomEmojis)
                GestureDetector(
                  key: Key('glyph:$g'),
                  onTap: () =>
                      setState(() => _glyph == 'icon' ? _icon = g : _emoji = g),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MkColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: (_glyph == 'icon' ? _icon : _emoji) == g ? 2 : 1,
                        color: (_glyph == 'icon' ? _icon : _emoji) == g
                            ? MkColors.accent
                            : MkColors.border,
                      ),
                    ),
                    child: _glyph == 'icon'
                        ? Icon(lucideIcon(g), size: 20)
                        : GrayEmoji(g, size: 28),
                  ),
                ),
              if (_glyph == 'emoji')
                SizedBox(
                  width: 84,
                  height: 36,
                  child: TextField(
                    key: const Key('emojiField'),
                    decoration: const InputDecoration(
                      hintText: '키보드',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final c = v.characters;
                      if (c.isNotEmpty) setState(() => _emoji = c.last);
                    },
                  ),
                ),
            ],
          ),
          _section('이름'),
          TextField(
            key: const Key('nameField'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            maxLength: kCustomLabelMax,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            decoration: InputDecoration(
              filled: true,
              fillColor: MkColors.surface,
              hintText: '예: 야근 중',
              suffixText: '${_name.text.characters.length}/$kCustomLabelMax',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          _section('카테고리'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in kCategoryLabels.entries)
                _pill(
                  c.value,
                  _cat == c.key,
                  () => setState(() => _cat = c.key),
                  key: Key('cat:${c.key}'),
                  dark: true,
                ),
            ],
          ),
          _section('진동'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in kVibrationChoices.entries)
                _pill(v.value, _vib == v.key, () {
                  setState(() => _vib = v.key);
                  HapticFeedback.lightImpact();
                }, key: Key('vib:${v.key}')),
            ],
          ),
          _section('움직임'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.6,
            children: [
              for (final m in kMotionChoices.entries)
                GestureDetector(
                  key: Key('motion:${m.key}'),
                  onTap: () => setState(() {
                    _motion = m.key;
                    _playToken = Object();
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MkColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: _motion == m.key ? 2 : 1,
                        color: _motion == m.key
                            ? MkColors.accent
                            : MkColors.border,
                      ),
                    ),
                    child: Text(
                      m.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: _motion == m.key
                            ? MkColors.accent
                            : MkColors.text,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _section(
            '추천 반응',
            Text(
              '${_reactions.length}/$kMaxCustomReactions',
              style: const TextStyle(fontSize: 12, color: MkColors.textSub),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _reactions.length; i++)
                InputChip(
                  label: Text(_reactions[i]),
                  onDeleted: () => setState(() => _reactions.removeAt(i)),
                ),
              if (_reactions.length < kMaxCustomReactions)
                ActionChip(
                  key: const Key('addReaction'),
                  avatar: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('추가'),
                  onPressed: _addReaction,
                ),
            ],
          ),
          if (_editing && widget.onDelete != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton.icon(
                key: const Key('deleteCustom'),
                onPressed: _delete,
                icon: const Icon(LucideIcons.trash2, color: MkColors.danger),
                label: const Text(
                  '감정 삭제',
                  style: TextStyle(color: MkColors.danger),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            key: const Key('saveCustom'),
            style: FilledButton.styleFrom(
              backgroundColor: MkColors.accent,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _valid && !_saving ? _save : null,
            child: Text(_editing ? '저장' : '만들기'),
          ),
        ),
      ),
    );
  }
}

/// 감정 글리프: 아이콘(lucide, 차콜/선택 시 탠저린) 또는 흑백 이모지 칩
class EmotionGlyph extends StatelessWidget {
  const EmotionGlyph(
    this.e, {
    super.key,
    this.size = 24,
    this.color,
    this.selected = false,
  });
  final Emotion? e;
  final double size;
  final Color? color;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final em = e;
    if (em != null && em.usesEmoji && em.emoji.isNotEmpty) {
      return GrayEmoji(
        em.emoji,
        size: size,
        background: selected
            ? const Color(0xFFFFE3D8)
            : const Color(0xFFF2F2F2),
      );
    }
    return Icon(
      lucideIcon(em?.icon),
      size: size,
      color: color ?? (selected ? MkColors.accent : MkColors.charcoal),
    );
  }
}

/// 앱 UI 이모지: grayscale(100%) + 원형 칩(display_rules.custom_emoji)
class GrayEmoji extends StatelessWidget {
  const GrayEmoji(
    this.emoji, {
    super.key,
    this.size = 24,
    this.background = const Color(0xFFF2F2F2),
  });
  final String emoji;
  final double size;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.6, height: 1.1)),
    ),
  );
}
