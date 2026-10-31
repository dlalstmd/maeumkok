import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../avatar/avatar_view.dart';
import '../background/background.dart';
import '../core/theme.dart';

/// 배경 고르기 (shots/v5_bg_01_picker 기준)
class BackgroundPickerScreen extends StatefulWidget {
  const BackgroundPickerScreen({
    super.key,
    required this.uid,
    required this.initial,
    this.coupleId,
    this.shared = false,
    this.myAvatar = const {},
    this.partnerName,
    this.service,
    this.catalog,
    this.pickPhoto,
  });
  final String uid;
  final String? coupleId;
  final BgChoice initial;
  final bool shared;
  final Map<String, String> myAvatar;
  final String? partnerName;
  final BackgroundService? service;
  final BgCatalog? catalog; // 테스트 주입
  final Future<BgPhoto?> Function()? pickPhoto; // 테스트 주입

  @override
  State<BackgroundPickerScreen> createState() => _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<BackgroundPickerScreen> {
  BgCatalog? _cat;
  late BgChoice _draft = widget.initial;
  late bool _shared = widget.shared;
  String _filter = 'all';
  bool _busy = false;
  BackgroundService get _svc => widget.service ?? BackgroundService();

  static const _filters = {
    'all': '전체',
    'solid': '단색',
    'gradient': '그라데이션',
    'pattern': '패턴',
    'illustration': '일러스트',
    'tod': '시간대 · 내 사진',
  };

  @override
  void initState() {
    super.initState();
    if (widget.catalog != null) {
      _cat = widget.catalog;
    } else {
      BgCatalog.load().then((c) {
        if (mounted) setState(() => _cat = c);
      });
    }
  }

  ResolvedBg get _resolved => resolveBg(_cat!, _draft, DateTime.now());

  Future<bool> _confirmSharePhoto() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('내 사진을 같이 쓸까요?'),
          content: Text(
            '같이 쓰기를 켜면 이 사진이 ${widget.partnerName ?? '상대'}에게도 공유돼요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소'),
            ),
            TextButton(
              key: const Key('confirmSharePhoto'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('공유하기'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      var c = _draft;
      final cid = widget.coupleId;
      if (_shared && cid != null) {
        if (c.type == 'photo' &&
            c.photo != null &&
            !c.photo!.path.startsWith('couples/')) {
          if (!await _confirmSharePhoto()) {
            setState(() => _busy = false);
            return;
          }
          c = c.copyWith(photo: await _svc.copyToCouple(cid, c.photo!));
        }
        if (!widget.shared) {
          await _svc.setShared(cid, widget.uid, true, c);
        } else {
          await _svc.saveShared(cid, widget.uid, c);
        }
      } else {
        if (widget.shared && cid != null) {
          await _svc.setShared(cid, widget.uid, false, c);
        }
        await _svc.saveMine(widget.uid, c);
      }
      if (mounted) Navigator.pop(context, c);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('배경을 저장하지 못했어요: $e')));
      }
    }
  }

  Future<void> _uploadPhoto() async {
    BgPhoto? p;
    setState(() => _busy = true);
    try {
      if (widget.pickPhoto != null) {
        p = await widget.pickPhoto!();
      } else {
        final cat = _cat!;
        final x = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: cat.maxPx.toDouble(),
          maxHeight: cat.maxPx.toDouble(),
          imageQuality: 85,
        );
        if (x != null) {
          p = await _svc.uploadMine(
            widget.uid,
            await x.readAsBytes(),
            dim: cat.dimDefault,
            blur: cat.blurDefault,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('사진을 올리지 못했어요: $e')));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (p != null)
        _draft = _draft.copyWith(type: 'photo', id: 'photo_upload', photo: p);
    });
    if (p != null) _adjustPhoto();
  }

  void _adjustPhoto() {
    final cat = _cat!;
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final p = _draft.photo!;
          void upd(BgPhoto n) {
            setState(() => _draft = _draft.copyWith(photo: n));
            set(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '사진 조절',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('어둡게 ${(p.dim * 100).round()}%'),
                  Slider(
                    key: const Key('dimSlider'),
                    value: p.dim.clamp(0, cat.dimMax),
                    max: cat.dimMax,
                    activeColor: MkColors.accent,
                    onChanged: (v) => upd(
                      p.copyWith(
                        dim: v,
                        lightInk: v >= 0.35 ? true : p.lightInk,
                      ),
                    ),
                  ),
                  Text('흐림 ${p.blur.round()}'),
                  Slider(
                    key: const Key('blurSlider'),
                    value: p.blur.clamp(0, cat.blurMax),
                    max: cat.blurMax,
                    activeColor: MkColors.accent,
                    onChanged: (v) => upd(p.copyWith(blur: v)),
                  ),
                  Text(
                    '글자색은 자동으로 정해져요 (${p.lightInk ? '밝은 글자' : '어두운 글자'})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: MkColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = _cat;
    return Scaffold(
      appBar: AppBar(
        title: const Text('배경'),
        centerTitle: true,
        actions: [
          TextButton(
            key: const Key('applyBg'),
            onPressed: cat == null || _busy ? null : _apply,
            child: const Text(
              '적용',
              style: TextStyle(
                color: MkColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: cat == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _header(),
                    _chips(),
                    for (final e in BgCatalog.categories.entries)
                      if (_filter == 'all' || _filter == e.key)
                        _section(e.value, [
                          for (final b in cat.items)
                            if (b.category == e.key) b,
                        ]),
                    if (_filter == 'all' || _filter == 'tod') _todSection(cat),
                  ],
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _header() {
    final tod = _draft.type == 'tod';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 90,
              height: 152,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MainBackground(resolved: _resolved, motion: _draft.motion),
                  Center(
                    child: IgnorePointer(
                      child: LiveAvatar(selection: widget.myAvatar, size: 64),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _toggle(
                  LucideIcons.sparkles,
                  '은은한 움직임',
                  _draft.motion,
                  'motionToggle',
                  (v) => setState(() => _draft = _draft.copyWith(motion: v)),
                ),
                _toggle(LucideIcons.sunMoon, '시간대 따라 바꾸기', tod, 'todToggle', (
                  v,
                ) {
                  setState(() {
                    if (v) {
                      _draft = _draft.copyWith(type: 'tod', id: 'tod_gradient');
                    } else {
                      final it = _resolved.item;
                      _draft = _draft.copyWith(
                        type: 'preset',
                        id: it?.id ?? 'solid_01',
                      );
                    }
                  });
                }),
                if (widget.coupleId != null)
                  _toggle(
                    LucideIcons.users,
                    '둘이 같이 쓰기',
                    _shared,
                    'sharedToggle',
                    (v) => setState(() => _shared = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    IconData icon,
    String label,
    bool v,
    String key,
    ValueChanged<bool> on,
  ) => SizedBox(
    height: 30,
    child: Row(
      children: [
        Icon(icon, size: 16, color: MkColors.charcoal),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            key: Key(key),
            value: v,
            activeTrackColor: MkColors.accent,
            onChanged: on,
          ),
        ),
      ],
    ),
  );

  Widget _chips() => SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final e in _filters.entries)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: Key('bgf:${e.key}'),
              label: Text(e.value),
              selected: _filter == e.key,
              showCheckmark: false,
              selectedColor: MkColors.accent,
              backgroundColor: const Color(0xFFF2F2F2),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                color: _filter == e.key ? Colors.white : MkColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _filter = e.key),
            ),
          ),
      ],
    ),
  );

  Widget _sectionTitle(String t, int n, String filter) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 8, 8),
    child: Row(
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        InkWell(
          onTap: () => setState(() => _filter = filter),
          child: Row(
            children: [
              Text(
                '$n개',
                style: const TextStyle(fontSize: 12, color: MkColors.textSub),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: MkColors.textSub,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, List<BgItem> items) {
    final key = items.isEmpty ? 'all' : items.first.category;
    final grid = _filter != 'all';
    final tiles = [
      for (final b in items)
        _tile(
          key: 'bg:${b.id}',
          selected: _draft.type == 'preset' && _draft.id == b.id,
          motion: b.motion != null,
          onTap: () => setState(
            () => _draft = _draft.copyWith(type: 'preset', id: b.id),
          ),
          child: BgThumb(b, zoom: _cat!.patternZoom),
          label: b.name,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, items.length, key),
        if (grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: tiles),
          )
        else
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => tiles[i],
            ),
          ),
      ],
    );
  }

  Widget _todSection(BgCatalog cat) {
    final now = DateTime.now();
    final photoSel = _draft.type == 'photo';
    final tiles = <Widget>[
      _tile(
        key: 'bg:photo_upload',
        selected: false,
        dashed: true,
        onTap: _uploadPhoto,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imagePlus, color: MkColors.charcoal),
            SizedBox(height: 6),
            Text(
              '사진 올리기',
              style: TextStyle(fontSize: 11, color: MkColors.textSub),
            ),
          ],
        ),
      ),
      if (_draft.photo != null)
        _tile(
          key: 'bg:photo',
          selected: photoSel,
          onTap: () {
            setState(
              () => _draft = _draft.copyWith(type: 'photo', id: 'photo_upload'),
            );
            _adjustPhoto();
          },
          child: MainBackground(
            resolved: ResolvedBg(photo: _draft.photo, lightInk: true),
            thumb: true,
          ),
          label: '내 사진',
        ),
      for (final t in cat.todSets)
        _tile(
          key: 'bg:${t.id}',
          selected: _draft.type == 'tod' && _draft.id == t.id,
          badge: '하루',
          onTap: () =>
              setState(() => _draft = _draft.copyWith(type: 'tod', id: t.id)),
          child: Builder(
            builder: (_) {
              final it = cat.byId(t.slots[cat.slotAt(now)] ?? '');
              return it == null ? const SizedBox() : BgThumb(it);
            },
          ),
          label: t.name,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('시간대 · 내 사진', cat.todSets.length + 1, 'tod'),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => tiles[i],
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required String key,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    String? label,
    bool motion = false,
    bool dashed = false,
    String? badge,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: Key(key),
        onTap: onTap,
        child: Container(
          width: 68,
          height: 114,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? MkColors.accent : const Color(0xFFE6E6E6),
              width: selected ? 2 : 1,
              style: dashed ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(selected ? 8 : 9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                if (selected)
                  const Positioned(
                    left: 5,
                    top: 5,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: MkColors.accent,
                      child: Icon(
                        LucideIcons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (motion)
                  const Positioned(
                    right: 4,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xCCFFFFFF),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 10,
                        color: MkColors.charcoal,
                      ),
                    ),
                  ),
                if (badge != null)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE6FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.sunMoon,
                            size: 9,
                            color: MkColors.charcoal,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              color: MkColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
