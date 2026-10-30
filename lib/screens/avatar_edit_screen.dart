import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../avatar/avatar_manifest.dart';
import '../avatar/avatar_view.dart';
import '../core/theme.dart';
import '../services/couple_service.dart';

/// 아바타 꾸미기. users/{uid}.avatar 에 개인별 저장 (상대 화면에 내 아바타로 보임)
class AvatarEditScreen extends StatefulWidget {
  const AvatarEditScreen({super.key, required this.uid, required this.initial});
  final String uid;
  final Map<String, String> initial;

  @override
  State<AvatarEditScreen> createState() => _AvatarEditScreenState();
}

class _AvatarEditScreenState extends State<AvatarEditScreen> {
  late Map<String, String> _sel = Map.of(widget.initial);
  String _cat = kCustomizableCategories.first;
  AvatarManifest? _m;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    loadAvatarManifest().then((m) => setState(() {
          _m = m;
          _sel = m.normalize(_sel);
        }));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await CoupleService().userRef(widget.uid).update({'avatar': _sel});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
        title: const Text('아바타 꾸미기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving || m == null ? null : _save,
            child: const Text('저장',
                style: TextStyle(color: MkColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: m == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              const SizedBox(height: 12),
              Center(child: LiveAvatar(selection: _sel, size: 220)),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final c in kCustomizableCategories)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(kCategoryLabels[c] ?? c),
                          selected: _cat == c,
                          showCheckmark: false,
                          selectedColor: MkColors.text,
                          labelStyle: TextStyle(color: _cat == c ? Colors.white : MkColors.textSub),
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          onSelected: (_) => setState(() => _cat = c),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(20),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final p in m.byCategory(_cat))
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _sel = {..._sel, _cat: p.id}),
                        child: Container(
                          decoration: BoxDecoration(
                            color: MkColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _sel[_cat] == p.id ? MkColors.accent : MkColors.border,
                                width: _sel[_cat] == p.id ? 2 : 1),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: AvatarLayers(selection: {..._sel, _cat: p.id}, size: 72),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
    );
  }
}
