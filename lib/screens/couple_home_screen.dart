import 'dart:async';

import 'package:flutter/material.dart';

import '../core/emotions.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';

class CoupleHomeScreen extends StatefulWidget {
  const CoupleHomeScreen({
    super.key,
    required this.uid,
    required this.coupleId,
    required this.emotions,
    required this.notify,
  });
  final String uid;
  final String coupleId;
  final EmotionService emotions;
  final NotifyService notify;

  @override
  State<CoupleHomeScreen> createState() => _CoupleHomeScreenState();
}

class _CoupleHomeScreenState extends State<CoupleHomeScreen> {
  StreamSubscription<List<EmotionEvent>>? _sub;
  final _seen = <String>{};
  bool _first = true;

  @override
  void initState() {
    super.initState();
    widget.notify.init();
    _sub = widget.emotions.watchEmotions(widget.coupleId).listen((list) {
      for (final ev in list) {
        if (_seen.add(ev.id) && !_first && ev.senderUid != widget.uid) {
          final e = emotionById(ev.emotionId);
          if (e != null) {
            widget.notify.vibrateFor(e);
            widget.notify.showEmotion(e);
          }
        }
      }
      _first = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<EmotionEvent>>(
            stream: widget.emotions.watchEmotions(widget.coupleId),
            builder: (context, snap) {
              final list = snap.data ?? const <EmotionEvent>[];
              if (list.isEmpty) {
                return const Center(child: Text('아직 주고받은 마음이 없어요'));
              }
              return StreamBuilder<List<ReactionEvent>>(
                stream: widget.emotions.watchReactions(widget.coupleId),
                builder: (context, rs) {
                  final reactions = rs.data ?? const <ReactionEvent>[];
                  return ListView.builder(
                    reverse: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) => _tile(list[i], reactions),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final e in kEmotions)
                      ActionChip(
                        label: Text('${e.emoji} ${e.label}'),
                        onPressed: () => widget.emotions.sendEmotion(
                          widget.coupleId,
                          widget.uid,
                          e.id,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(EmotionEvent ev, List<ReactionEvent> reactions) {
    final e = emotionById(ev.emotionId);
    final mine = ev.senderUid == widget.uid;
    final myReaction = reactions.where((r) => r.emotionDocId == ev.id).toList();
    if (!mine && ev.readAt == null) {
      widget.emotions.markRead(widget.coupleId, ev.id);
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                '${e?.emoji ?? '💬'} ${e?.label ?? ev.emotionId}',
                style: const TextStyle(fontSize: 18),
              ),
              if (mine)
                Text(
                  ev.readAt != null ? '읽음' : '전송됨',
                  style: const TextStyle(fontSize: 12),
                ),
              for (final r in myReaction)
                Text(
                  '↳ ${_reactionLabel(e, r.reactionId)}',
                  style: const TextStyle(fontSize: 13),
                ),
              if (!mine && e != null && myReaction.isEmpty)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final r in e.reactions)
                      OutlinedButton(
                        onPressed: () => widget.emotions.react(
                          widget.coupleId,
                          widget.uid,
                          ev.id,
                          r.id,
                        ),
                        child: Text(r.label),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _reactionLabel(Emotion? e, String id) {
    for (final r in e?.reactions ?? const <Reaction>[]) {
      if (r.id == id) return r.label;
    }
    return id;
  }
}
