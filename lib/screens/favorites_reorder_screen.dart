import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/emotions.dart';
import '../core/theme.dart';
import 'custom_emotion_screen.dart';

/// 즐겨찾기 순서 편집: 손잡이로 끌어 순서 변경, ★ 눌러 빼기, 완료로 저장.
class FavoritesReorderScreen extends StatefulWidget {
  const FavoritesReorderScreen({
    super.key,
    required this.order,
    required this.onSave,
  });
  final List<String> order;
  final Future<void> Function(List<String> order) onSave;
  @override
  State<FavoritesReorderScreen> createState() => _FavoritesReorderScreenState();
}

class _FavoritesReorderScreenState extends State<FavoritesReorderScreen> {
  late final List<String> _order = [...widget.order];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MkColors.background,
    appBar: AppBar(
      title: const Text('즐겨찾기 순서 편집'),
      actions: [
        TextButton(
          key: const Key('reorderDone'),
          onPressed: () async {
            await widget.onSave(_order);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('완료', style: TextStyle(color: MkColors.accent)),
        ),
      ],
    ),
    body: ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _order.length,
      onReorderItem: (a, b) => setState(() {
        _order.insert(b, _order.removeAt(a));
      }),
      itemBuilder: (_, i) {
        final e = emotionById(_order[i]);
        return ListTile(
          key: ValueKey(_order[i]),
          leading: ReorderableDragStartListener(
            index: i,
            child: const Icon(
              LucideIcons.gripVertical,
              color: MkColors.textSub,
            ),
          ),
          title: Row(
            children: [
              EmotionGlyph(e, size: 20),
              const SizedBox(width: 10),
              Text(e?.label ?? _order[i]),
            ],
          ),
          trailing: IconButton(
            key: Key('unfav:${_order[i]}'),
            icon: const Icon(Icons.star_rounded, color: MkColors.accent),
            onPressed: () => setState(() => _order.removeAt(i)),
          ),
        );
      },
    ),
  );
}
