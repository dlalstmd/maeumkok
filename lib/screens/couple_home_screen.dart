import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../avatar/avatar_view.dart';
import '../core/emotions.dart';
import '../core/lucide_map.dart';
import '../core/theme.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';

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
  });
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
  final _seen = <String>{};
  bool _first = true;
  List<EmotionEvent> _list = const [];
  String? _selected;
  String? _playKey;
  Object? _playToken;

  @override
  void initState() {
    super.initState();
    widget.notify.init();
    _sub = widget.emotions.watchEmotions(widget.coupleId, limit: 20).listen((
      list,
    ) {
      for (final ev in list) {
        if (_seen.add(ev.id) && !_first && ev.senderUid != widget.uid) {
          final e = emotionById(ev.emotionId);
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
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
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

  Future<void> _send(Emotion e) async {
    setState(() => _selected = e.id);
    await widget.emotions.sendEmotion(widget.coupleId, widget.uid, e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${e.label} 마음을 보냈어요'),
          duration: const Duration(seconds: 1),
        ),
      );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _selected = null);
    });
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
              GestureDetector(
                onTap: () => setState(() {
                  _playKey = 'jump';
                  _playToken = Object();
                }),
                child: LiveAvatar(
                  selection: widget.partnerAvatar,
                  size: 240,
                  playKey: _playKey,
                  playToken: _playToken,
                ),
              ),
              const SizedBox(height: 24),
              if (lastFromPartner != null) _lastChip(lastFromPartner),
              if (lastFromPartner != null) _reactions(lastFromPartner),
              if (lastMine != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '내가 보낸 ${emotionById(lastMine.emotionId)?.label ?? ''} · ${lastMine.readAt != null ? '읽음' : '전송됨'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: MkColors.textSub,
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 76 / 80,
                    children: [for (final e in kEmotions) _emotionCard(e)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emotionCard(Emotion e) {
    final sel = _selected == e.id;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _send(e),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: sel ? MkColors.accent : MkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? MkColors.accent : MkColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lucideIcon(e.icon),
              size: 26,
              color: sel ? Colors.white : MkColors.text,
            ),
            const SizedBox(height: 8),
            Text(
              e.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : MkColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lastChip(EmotionEvent ev) {
    final e = emotionById(ev.emotionId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lucideIcon(e?.icon), size: 14),
          const SizedBox(width: 6),
          Text(
            '마지막 마음 · ${e?.label ?? ev.emotionId} · ${_ago(ev.createdAt)}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _reactions(EmotionEvent ev) {
    final e = emotionById(ev.emotionId);
    if (e == null) return const SizedBox.shrink();
    return StreamBuilder<List<ReactionEvent>>(
      stream: widget.emotions.watchReactions(widget.coupleId, limit: 20),
      builder: (context, snap) {
        final mine = (snap.data ?? const <ReactionEvent>[])
            .where((r) => r.emotionDocId == ev.id && r.senderUid == widget.uid)
            .firstOrNull;
        if (mine != null) {
          final label = e.reactions
              .where((r) => r.id == mine.reactionId)
              .firstOrNull
              ?.label;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '↳ ${label ?? ''}',
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
                  ),
                  onPressed: () => widget.emotions.react(
                    widget.coupleId,
                    widget.uid,
                    ev.id,
                    r.id,
                  ),
                  child: Text(r.label, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        );
      },
    );
  }
}
