import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../background/background.dart' show isSystemEvent;
import '../avatar/touch_reactions.dart';
import '../avatar/part_adjust.dart';
import '../core/emotions.dart';
import '../core/theme.dart';
import '../services/emotion_prefs_service.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';
import 'custom_emotion_screen.dart';
import 'favorites_reorder_screen.dart';

/// 메인 (v2_04a/b): 상대 아바타 + 마지막 마음 + 하단 시트 감정 그리드
class CoupleHomeScreen extends StatefulWidget {
  const CoupleHomeScreen({
    super.key,
    required this.uid,
    required this.coupleId,
    required this.emotions,
    required this.notify,
    this.partnerName,
    this.partnerAvatar = const {},
    this.partnerAdjusts = const {},
    this.prefs,
    this.myAvatar = const {},
    this.touchHaptics = true,
  });

  /// users/{uid}.prefs.touchHaptics (기본 true)
  final bool touchHaptics;

  /// 즐겨찾기·최근·우리 감정(없으면 해당 기능 비활성: 테스트용)
  final EmotionPrefsService? prefs;
  final Map<String, String> myAvatar;
  final Map<String, PartAdjust> partnerAdjusts;
  final String uid;
  final String coupleId;
  final EmotionService emotions;
  final NotifyService notify;
  final String? partnerName;
  final Map<String, String> partnerAvatar;

  @override
  State<CoupleHomeScreen> createState() => _CoupleHomeScreenState();
}

class _CoupleHomeScreenState extends State<CoupleHomeScreen> {
  StreamSubscription<List<EmotionEvent>>? _sub;
  StreamSubscription<List<ReactionEvent>>? _reactSub;
  List<ReactionEvent> _reacts = const [];
  final _seenReacts = <String>{};
  bool _firstReacts = true;
  String? _error;
  final _seen = <String>{};
  bool _first = true;
  List<EmotionEvent> _list = const [];
  String? _selected;
  String? _playKey;
  Object? _playToken;
  final _prefSubs = <StreamSubscription<Object?>>[];
  List<Emotion> _customs = const [];
  List<String> _favs = const [];
  List<RecentItem> _recent = const [];
  bool _favsLoaded = false;

  /// 0 즐겨찾기, 1 최근, 2.. 카테고리(kCategoryTree 순서)
  int _tab = 2;

  /// 카테고리 탭의 소분류 칩 id, '__ours' = 우리 감정
  String? _subcat;

  @override
  void initState() {
    super.initState();
    widget.notify.init();
    final pr = widget.prefs;
    if (pr != null) {
      _prefSubs.add(
        pr.watchCustoms(widget.coupleId).listen((list) {
          kCustomEmotions = {for (final e in list) e.id: e};
          if (mounted) setState(() => _customs = list);
        }, onError: (Object e) => _showError(e)),
      );
      _prefSubs.add(
        pr.watchFavorites(widget.uid).listen((l) {
          if (!mounted) return;
          setState(() {
            _favs = l;
            if (!_favsLoaded && l.isNotEmpty) _tab = 0;
            _favsLoaded = true;
          });
        }, onError: (Object e) => _showError(e)),
      );
      _prefSubs.add(
        pr.watchRecent(widget.uid).listen((l) {
          if (mounted) setState(() => _recent = l);
        }, onError: (Object e) => _showError(e)),
      );
    }
    _sub = widget.emotions.watchEmotions(widget.coupleId, limit: 20).listen((
      all,
    ) {
      // 시스템 이벤트(배경 변경)는 타임라인 전용
      final list = all.where((e) => !isSystemEvent(e.emotionId)).toList();
      for (final ev in all) {
        if (isSystemEvent(ev.emotionId)) continue;
        if (_seen.add(ev.id) && !_first && ev.senderUid != widget.uid) {
          final e = emotionFor(ev.emotionId, ev.snapshot);
          if (e != null) {
            _playKey = e.animationKey;
            _playToken = ev.id;
            widget.notify.vibrateFor(e);
            widget.notify.showEmotion(e, from: widget.partnerName ?? '상대');
          }
        }
        if (ev.senderUid != widget.uid && ev.readAt == null) {
          widget.emotions.markRead(widget.coupleId, ev.id);
        }
      }
      _first = false;
      if (mounted) setState(() => _list = list);
    }, onError: (Object e) => _showError(e));
    // 반응은 화면 상태에서 한 번만 구독한다(빌드마다 새 스트림을 만들지 않음).
    _reactSub = widget.emotions
        .watchReactions(widget.coupleId, limit: 50)
        .listen((list) {
          for (final r in list) {
            if (_seenReacts.add(r.id) &&
                !_firstReacts &&
                r.senderUid != widget.uid) {
              final ev = _list.where((x) => x.id == r.emotionDocId).firstOrNull;
              final e = ev == null
                  ? null
                  : emotionFor(ev.emotionId, ev.snapshot);
              _playKey = 'jump';
              _playToken = r.id;
              widget.notify.showReaction(
                reactionLabel(e, r.reactionId),
                from: widget.partnerName ?? '상대',
              );
            }
          }
          _firstReacts = false;
          if (mounted) setState(() => _reacts = list);
        }, onError: (Object e) => _showError(e));
  }

  void _showError(Object e) {
    if (mounted) setState(() => _error = '불러오지 못했어요: $e');
  }

  Future<void> _react(EmotionEvent ev, String reactionId) async {
    try {
      await widget.emotions.react(
        widget.coupleId,
        widget.uid,
        ev.id,
        reactionId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('반응을 보내지 못했어요: $e')));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reactSub?.cancel();
    for (final s in _prefSubs) {
      s.cancel();
    }
    _burst.flushNow();
    super.dispose();
  }

  String _ago(DateTime? t) {
    if (t == null) return '방금';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '방금';
    if (d.inHours < 1) return '${d.inMinutes}분 전';
    if (d.inDays < 1) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }

  late final _burst = TapBurst(onFlush: _flush);

  /// 탭은 막지 않고 모아서(마지막 탭 후 1초) 문서 1개로 보낸다.
  void _send(Emotion e) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = e.id;
      _burst.tap(e.id);
    });
  }

  Future<void> _flush(String emotionId, int count) async {
    if (mounted) setState(() {});
    final e = emotionById(emotionId);
    try {
      await widget.emotions.sendEmotion(
        widget.coupleId,
        widget.uid,
        emotionId,
        count: count,
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('보내지 못했어요: $err')));
      return;
    }
    final pr = widget.prefs;
    if (pr != null) {
      _recent = pushRecent(_recent, emotionId, DateTime.now());
      pr.saveRecent(widget.uid, _recent).catchError((_) {});
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${e?.label ?? emotionId} 마음을 보냈어요${count > 1 ? ' x$count' : ''}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    if (_burst.pendingId == null) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final lastFromPartner = _list
        .where((e) => e.senderUid != widget.uid)
        .firstOrNull;
    final lastMine = _list.where((e) => e.senderUid == widget.uid).firstOrNull;
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TouchAvatar(
                selection: widget.partnerAvatar,
                adjusts: widget.partnerAdjusts,
                size: 240,
                playKey: _playKey,
                playToken: _playToken,
                haptics: widget.touchHaptics,
                semanticsLabel: '${widget.partnerName ?? '상대'} 아바타, 탭하면 반응해요',
              ),
              const SizedBox(height: 24),
              if (lastFromPartner != null) _lastChip(lastFromPartner),
              if (lastFromPartner != null) _reactions(lastFromPartner),
              if (lastMine != null) _myLastLine(lastMine),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MkColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.27,
          minChildSize: 0.27,
          maxChildSize: 0.85,
          snap: true,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: MkColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MkColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.chevronUp, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '올려서 마음 보내기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                if (widget.prefs != null) ..._sheetHeader(),
                ..._sheetBody(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── v4 바텀시트 ──────────────────────────────────────────────
  List<Emotion> get _activeCustoms =>
      _customs.where((e) => !e.deleted).toList();

  List<Widget> _sheetHeader() {
    final tabs = <String>[
      '★ 즐겨찾기',
      '최근',
      for (final c in kCategoryTree) c.label,
    ];
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (var i = 0; i < tabs.length; i++)
                GestureDetector(
                  key: Key('tab:$i'),
                  onTap: () => setState(() {
                    _tab = i;
                    _subcat = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: _tab == i ? MkColors.text : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _tab == i
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: _tab == i ? MkColors.text : MkColors.textSub,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_tab >= 2 && _tab - 2 < kCategoryTree.length)
        SliverToBoxAdapter(child: _subcatChips(kCategoryTree[_tab - 2])),
      if (_tab == 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                Text(
                  '${_favs.length}/$kMaxFavorites',
                  style: const TextStyle(fontSize: 12, color: MkColors.textSub),
                ),
                const Spacer(),
                if (_favs.isNotEmpty)
                  TextButton(
                    key: const Key('reorderFavs'),
                    onPressed: _openReorder,
                    child: const Text(
                      '순서 편집',
                      style: TextStyle(color: MkColors.textSub),
                    ),
                  ),
              ],
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
    ];
  }

  Widget _subcatChips(CategoryNode c) {
    Widget chip(String? id, String label, {bool dot = false}) {
      final sel = _subcat == id;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          key: Key('sub:${id ?? 'all'}'),
          onTap: () => setState(() => _subcat = id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? MkColors.text : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot) ...[
                  const CircleAvatar(
                    radius: 3,
                    backgroundColor: MkColors.accent,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: sel ? Colors.white : MkColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          chip(null, '전체'),
          chip('__ours', '우리 감정', dot: true),
          for (final sc in c.subcategories) chip(sc.id, sc.label),
        ],
      ),
    );
  }

  /// 현재 탭의 감정 목록(카테고리 탭은 우리 감정이 앞에)
  List<Emotion> _tabEmotions() {
    if (widget.prefs == null) return kEmotions;
    if (_tab == 0) {
      return [for (final id in cleanFavorites(_favs)) emotionById(id)!];
    }
    if (_tab == 1) return const [];
    final c = kCategoryTree[_tab - 2];
    final ours = _activeCustoms.where((e) => e.category == c.id).toList();
    if (_subcat == '__ours') return ours;
    final ids = _subcat == null
        ? [for (final sc in c.subcategories) ...sc.emotionIds]
        : c.subcategories
              .where((sc) => sc.id == _subcat)
              .expand((sc) => sc.emotionIds)
              .toList();
    return [
      if (_subcat == null) ...ours,
      for (final id in ids) ?emotionById(id),
    ];
  }

  Widget _grid(List<Widget> children) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    sliver: SliverGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 76 / 80,
      children: children,
    ),
  );

  List<Widget> _sheetBody() {
    if (_tab == 1 && widget.prefs != null) return _recentBody();
    final list = _tabEmotions();
    return [
      _grid([
        for (final e in list) _emotionCard(e),
        if (widget.prefs != null && (_tab != 0 || _favs.length < kMaxFavorites))
          _makeTile(),
      ]),
    ];
  }

  List<Widget> _recentBody() {
    final items = _recent
        .where((r) => emotionById(r.emotionId)?.deleted == false)
        .take(kMaxRecent)
        .toList();
    if (items.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                '아직 보낸 마음이 없어요',
                style: TextStyle(color: MkColors.textSub),
              ),
            ),
          ),
        ),
      ];
    }
    final now = DateTime.now();
    String day(DateTime t) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(t.year, t.month, t.day)).inDays;
      return d == 0 ? '오늘' : (d == 1 ? '어제' : '${t.month}월 ${t.day}일');
    }

    final groups = <String, List<Emotion>>{};
    for (final r in items) {
      groups
          .putIfAbsent(day(r.sentAt), () => [])
          .add(emotionById(r.emotionId)!);
    }
    return [
      for (final g in groups.entries) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              g.key,
              style: const TextStyle(fontSize: 12, color: MkColors.textSub),
            ),
          ),
        ),
        _grid([for (final e in g.value) _emotionCard(e)]),
      ],
    ];
  }

  Widget _makeTile() => InkWell(
    key: const Key('makeCustom'),
    borderRadius: BorderRadius.circular(16),
    onTap: () => _openEditor(),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MkColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.plus, size: 22, color: MkColors.textSub),
          SizedBox(height: 8),
          Text('만들기', style: TextStyle(fontSize: 12, color: MkColors.textSub)),
        ],
      ),
    ),
  );

  Future<void> _toggleFav(Emotion e) async {
    final pr = widget.prefs!;
    final cur = cleanFavorites(_favs);
    if (cur.contains(e.id)) {
      cur.remove(e.id);
    } else {
      if (cur.length >= kMaxFavorites) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('즐겨찾기는 최대 $kMaxFavorites개까지예요')),
        );
        return;
      }
      cur.add(e.id);
    }
    setState(() => _favs = cur);
    try {
      await pr.saveFavorites(widget.uid, cur);
    } catch (err) {
      _showError(err);
    }
  }

  Future<void> _openReorder() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FavoritesReorderScreen(
        order: cleanFavorites(_favs),
        onSave: (o) async {
          setState(() => _favs = o);
          await widget.prefs!.saveFavorites(widget.uid, o);
        },
      ),
    ),
  );

  Future<void> _openEditor([Emotion? e]) async {
    final pr = widget.prefs!;
    if (e == null && _activeCustoms.length >= kMaxCustomEmotions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('우리 감정은 최대 $kMaxCustomEmotions개까지예요')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => CustomEmotionScreen(
          initial: e,
          initialCategory: _tab >= 2 ? kCategoryTree[_tab - 2].id : 'mood',
          avatar: widget.myAvatar,
          partnerName: widget.partnerName ?? '상대',
          onPreview: widget.notify.vibrateFor,
          onSave: (d) => pr.saveCustom(
            widget.coupleId,
            widget.uid,
            id: e?.id,
            label: d.label,
            glyphType: d.glyphType,
            icon: d.icon,
            emoji: d.emoji,
            category: d.category,
            vibrationName: d.vibrationName,
            animationKey: d.animationKey,
            reactions: d.reactions,
          ),
          onDelete: e == null ? null : () => _deleteCustom(e),
        ),
      ),
    );
  }

  Future<void> _deleteCustom(Emotion e) async {
    await widget.prefs!.deleteCustom(widget.coupleId, e.id);
    if (_favs.contains(e.id)) {
      final f = [..._favs]..remove(e.id);
      setState(() => _favs = f);
      await widget.prefs!.saveFavorites(widget.uid, f);
    }
  }

  Future<void> _longPress(Emotion e) async {
    if (widget.prefs == null) return;
    final fav = _favs.contains(e.id);
    final a = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: EmotionGlyph(e, size: 22),
              title: Text(
                e.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              key: const Key('menu:fav'),
              leading: Icon(
                fav ? Icons.star_rounded : Icons.star_border_rounded,
              ),
              title: Text(fav ? '즐겨찾기에서 빼기' : '즐겨찾기 추가'),
              onTap: () => Navigator.pop(c, 'fav'),
            ),
            ListTile(
              key: const Key('menu:send'),
              leading: const Icon(LucideIcons.send),
              title: const Text('바로 보내기'),
              onTap: () => Navigator.pop(c, 'send'),
            ),
            if (e.custom) ...[
              ListTile(
                key: const Key('menu:edit'),
                leading: const Icon(LucideIcons.pencil),
                title: const Text('편집'),
                onTap: () => Navigator.pop(c, 'edit'),
              ),
              ListTile(
                key: const Key('menu:delete'),
                leading: const Icon(LucideIcons.trash2, color: MkColors.danger),
                title: const Text(
                  '삭제',
                  style: TextStyle(color: MkColors.danger),
                ),
                onTap: () => Navigator.pop(c, 'delete'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || a == null) return;
    switch (a) {
      case 'fav':
        await _toggleFav(e);
      case 'send':
        _send(e);
        _burst.flushNow();
      case 'edit':
        await _openEditor(e);
      case 'delete':
        if (await confirmDeleteCustom(
          context,
          e.label,
          widget.partnerName ?? '상대',
        )) {
          await _deleteCustom(e);
        }
    }
  }

  Widget _emotionCard(Emotion e) {
    final sel = _selected == e.id;
    final n = _burst.pendingId == e.id ? _burst.count : 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _emotionCardBody(e, sel)),
        if (e.custom)
          Positioned(
            right: 8,
            top: 8,
            child: SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sel ? MkColors.accent : MkColors.customDot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        if (n > 1)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              key: Key('burst:${e.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MkColors.text,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emotionCardBody(Emotion e, bool sel) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      key: Key('emo:${e.id}'),
      onTap: () => _send(e),
      onLongPress: () => _longPress(e),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: sel ? MkColors.accentSoft : MkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: sel ? 2 : 1,
            color: sel ? MkColors.accent : MkColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmotionGlyph(e, selected: sel),
            const SizedBox(height: 8),
            Text(
              e.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: sel ? MkColors.accent : MkColors.text,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lastChip(EmotionEvent ev) {
    final e = emotionFor(ev.emotionId, ev.snapshot);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmotionGlyph(e, size: 14),
          const SizedBox(width: 6),
          Text(
            '마지막 마음 · ${e?.label ?? ev.emotionId}${ev.count > 1 ? ' x${ev.count}' : ''} · ${_ago(ev.createdAt)}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _myLastLine(EmotionEvent mine) {
    final e = emotionFor(mine.emotionId, mine.snapshot);
    final r = reactionFor(
      _reacts.where((x) => x.senderUid != widget.uid),
      mine.id,
    );
    final status = r != null
        ? '상대 반응: ${reactionLabel(e, r.reactionId)}'
        : (mine.readAt != null ? '읽음' : '전송됨');
    return Padding(
      key: const Key('myLastLine'),
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '내가 보낸 ${e?.label ?? ''}${mine.count > 1 ? ' x${mine.count}' : ''} · $status',
        style: TextStyle(
          fontSize: r != null ? 14 : 12,
          color: r != null ? MkColors.text : MkColors.textSub,
          fontWeight: r != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _reactions(EmotionEvent ev) {
    final e = emotionFor(ev.emotionId, ev.snapshot);
    if (e == null) return const SizedBox.shrink();
    final mine = reactionFor(_reacts, ev.id, senderUid: widget.uid);
    if (mine != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '↳ 내 반응: ${reactionLabel(e, mine.reactionId)}',
          key: const Key('myReaction'),
          style: const TextStyle(fontSize: 13, color: MkColors.textSub),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        children: [
          for (final r in e.reactions)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: MkColors.text,
                side: const BorderSide(color: MkColors.border),
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => _react(ev, r.id),
              child: Text(r.label, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// 같은 감정 연타를 모은다: 마지막 탭 후 [debounce] 뒤 [onFlush](id, count).
/// 다른 감정을 누르면 이전 묶음을 즉시 보낸다. 최대 [kMaxBurst].
class TapBurst {
  TapBurst({required this.onFlush, this.debounce = const Duration(seconds: 1)});
  final void Function(String emotionId, int count) onFlush;
  final Duration debounce;
  String? pendingId;
  int count = 0;
  Timer? _timer;

  void tap(String id) {
    if (pendingId != null && pendingId != id) flushNow();
    pendingId = id;
    count = (count + 1).clamp(1, kMaxBurst);
    _timer?.cancel();
    _timer = Timer(debounce, flushNow);
  }

  void flushNow() {
    _timer?.cancel();
    _timer = null;
    final id = pendingId;
    final n = count;
    pendingId = null;
    count = 0;
    if (id != null && n > 0) onFlush(id, n);
  }
}
