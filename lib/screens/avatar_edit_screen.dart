import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../avatar/avatar_manifest.dart';
import '../avatar/avatar_view.dart';
import '../avatar/part_adjust.dart';
import '../core/theme.dart';
import '../services/couple_service.dart';

/// 아바타 꾸미기. users/{uid}.avatar 에 개인별 저장 (상대 화면에 내 아바타로 보임)
class AvatarEditScreen extends StatefulWidget {
  const AvatarEditScreen({
    super.key,
    required this.uid,
    required this.initial,
    this.initialAdjusts = const {},
    this.onSave,
  });
  final Map<String, PartAdjust> initialAdjusts;

  /// 테스트용 저장 훅(없으면 Firestore users/{uid} 업데이트)
  final Future<void> Function(Map<String, Object?> data)? onSave;
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
  late Map<String, PartAdjust> _adj = Map.of(widget.initialAdjusts);
  PartAdjust? _gestureStart;
  static const _previewSize = 220.0;

  /// 지금 조절 중인 액세서리
  String? _active;
  List<String> get _accs => _m?.accessoriesOf(_sel) ?? const [];
  String? get _acc =>
      _accs.contains(_active) ? _active : (_accs.isEmpty ? null : _accs.last);

  AnchorRule get _rule =>
      _acc == null ? const AnchorRule() : _m!.ruleForPart(_acc!);
  PartAdjust get _cur => (_adj[_acc] ?? PartAdjust.none).clampTo(_rule);
  void _set(PartAdjust a) {
    final id = _acc;
    if (id != null) setState(() => _adj = {..._adj, id: a.clampTo(_rule)});
  }

  void _toggleAccessory(String id) {
    final m = _m!;
    final cur = m.accessoriesOf(_sel);
    List<String> next;
    if (cur.contains(id)) {
      next = [...cur]..remove(id);
    } else {
      next = m.addAccessory(cur, id);
      if (identical(next, cur)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('액세서리는 최대 ${m.maxAccessories}개까지 달 수 있어요')),
          );
        return;
      }
      _active = id;
    }
    setState(() => _sel = {..._sel, kAccessoriesKey: next.join(',')});
  }

  void _pick(String cat, String id) {
    if (cat == 'accessory') return _toggleAccessory(id);
    setState(() => _sel = {..._sel, cat: id});
  }

  bool _isSelected(String cat, String id) =>
      cat == 'accessory' ? _accs.contains(id) : _sel[cat] == id;

  Map<String, String> _previewSel(String cat, String id) {
    if (cat != 'accessory') return {..._sel, cat: id};
    // 썸네일: 해당 액세서리만 얹어 보여줌
    return {..._sel, kAccessoriesKey: id};
  }

  @override
  void initState() {
    super.initState();
    loadAvatarManifest().then(
      (m) => setState(() {
        _m = m;
        _sel = m.normalize(_sel);
      }),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = <String, Object?>{
      'avatar': _sel,
      'avatarAdjust': adjustsToJson(_adj, keep: _acc),
    };
    try {
      if (widget.onSave != null) {
        await widget.onSave!(data);
      } else {
        await CoupleService().userRef(widget.uid).update(data);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장하지 못했어요: $e')));
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '아바타 꾸미기',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving || m == null ? null : _save,
            child: const Text(
              '저장',
              style: TextStyle(
                color: MkColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: m == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    key: const Key('avatarPreview'),
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _acc == null
                        ? null
                        : (_) => _gestureStart = _cur,
                    onScaleUpdate: _acc == null
                        ? null
                        : (d) {
                            final unit = _previewSize / 512;
                            final c = _cur;
                            final st = _gestureStart ?? c;
                            _set(
                              c.copyWith(
                                dx: c.dx + d.focalPointDelta.dx / unit,
                                dy: c.dy + d.focalPointDelta.dy / unit,
                                scale: d.pointerCount > 1
                                    ? st.scale * d.scale
                                    : null,
                                rotate: d.pointerCount > 1
                                    ? st.rotate + d.rotation * 180 / 3.14159265
                                    : null,
                              ),
                            );
                          },
                    child: LiveAvatar(
                      selection: _sel,
                      size: _previewSize,
                      adjusts: _adj,
                    ),
                  ),
                ),
                if (_cat == 'accessory' && _acc != null)
                  Flexible(child: SingleChildScrollView(child: _adjustPanel())),
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
                            labelStyle: TextStyle(
                              color: _cat == c
                                  ? Colors.white
                                  : MkColors.textSub,
                            ),
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
                          onTap: () => _pick(_cat, p.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: MkColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isSelected(_cat, p.id)
                                    ? MkColors.accent
                                    : MkColors.border,
                                width: _isSelected(_cat, p.id) ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: StaticAvatar(
                              adjusts: _adj,
                              selection: _previewSel(_cat, p.id),
                              size: 72,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _slider(
    String label,
    String key,
    double v,
    double min,
    double max,
    String Function(double) fmt,
    void Function(double) on,
  ) => Row(
    children: [
      SizedBox(
        width: 56,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
      Expanded(
        child: Slider(
          key: Key(key),
          value: v.clamp(min, max),
          min: min,
          max: max,
          activeColor: MkColors.accent,
          onChanged: on,
        ),
      ),
      SizedBox(
        width: 48,
        child: Text(
          fmt(v),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, color: MkColors.textSub),
        ),
      ),
    ],
  );

  Widget _adjustPanel() {
    final c = _cur;
    const o = PartAdjust.maxOffset;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
      child: Column(
        children: [
          if (_accs.length > 1)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final id in _accs)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: Key('activeAcc:$id'),
                        label: SizedBox.square(
                          dimension: 28,
                          child: StaticAvatar(
                            selection: {kAccessoriesKey: id, 'body': ''},
                            size: 28,
                          ),
                        ),
                        selected: _acc == id,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _active = id),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                key: const Key('adjFlip'),
                tooltip: '좌우 반전',
                isSelected: c.flipX,
                icon: const Icon(LucideIcons.flipHorizontal2),
                onPressed: () => _set(c.copyWith(flipX: !c.flipX)),
              ),
              const Expanded(
                child: Text(
                  '미리보기를 드래그해 옮기고, 두 손가락으로 크기·회전',
                  style: TextStyle(fontSize: 12, color: MkColors.textSub),
                ),
              ),
              TextButton(
                key: const Key('adjustReset'),
                onPressed: () => _set(PartAdjust.none),
                child: const Text('초기화'),
              ),
            ],
          ),
          _slider(
            '크기',
            'adjScale',
            c.scale,
            PartAdjust.minScale,
            PartAdjust.maxScale,
            (v) => '${(v * 100).round()}%',
            (v) => _set(c.copyWith(scale: v)),
          ),
          _slider(
            '회전',
            'adjRotate',
            c.rotate,
            -180,
            180,
            (v) => '${v.round()}°',
            (v) => _set(c.copyWith(rotate: v)),
          ),
          _slider(
            '가로',
            'adjX',
            c.dx,
            -o,
            o,
            (v) => v.round().toString(),
            (v) => _set(c.copyWith(dx: v)),
          ),
          _slider(
            '세로',
            'adjY',
            c.dy,
            -o,
            o,
            (v) => v.round().toString(),
            (v) => _set(c.copyWith(dy: v)),
          ),
          _slider(
            '모양',
            'adjStretch',
            c.stretchX,
            PartAdjust.minStretch,
            PartAdjust.maxStretch,
            (v) => '${(v * 100).round()}%',
            (v) => _set(c.copyWith(stretchX: v)),
          ),
        ],
      ),
    );
  }
}
