import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/emotions.dart';
import '../core/lucide_map.dart';
import '../core/theme.dart';
import '../services/emotion_service.dart';

/// 감정 타임라인: 날짜별 그룹, 30개씩 페이지네이션, 반응 표시
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.uid, required this.coupleId,
      required this.emotions, this.partnerName});
  final String uid;
  final String coupleId;
  final EmotionService emotions;
  final String? partnerName;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _items = <EmotionEvent>[];
  final _reactions = <String, List<ReactionEvent>>{};
  DocumentSnapshot? _last;
  bool _loading = false;
  bool _done = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _load();
    });
  }

  Future<void> _load() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      final snap = await widget.emotions.page(widget.coupleId, after: _last);
      final evs = snap.docs.map(EmotionEvent.fromDoc).toList();
      final rs = await widget.emotions.reactionsFor(widget.coupleId, evs.map((e) => e.id).toList());
      setState(() {
        _items.addAll(evs);
        for (final r in rs) {
          (_reactions[r.emotionDocId] ??= []).add(r);
        }
        if (snap.docs.isNotEmpty) _last = snap.docs.last;
        _done = snap.docs.length < 30;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.month}월 ${d.day}일 (${wd[d.weekday - 1]})';
  }

  String _hm(DateTime d) {
    final h = d.hour, m = d.minute.toString().padLeft(2, '0');
    return '${h < 12 ? '오전' : '오후'} ${h % 12 == 0 ? 12 : h % 12}:$m';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    String? lastDay;
    for (final e in _items) {
      final t = e.createdAt ?? DateTime.now();
      final day = _dayLabel(t);
      if (day != lastDay) {
        lastDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MkColors.textSub)),
        ));
      }
      rows.add(_tile(e, t));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('타임라인', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      body: _items.isEmpty && !_loading
          ? const Center(child: Text('아직 주고받은 마음이 없어요', style: TextStyle(color: MkColors.textSub)))
          : ListView(controller: _scroll, children: [
              ...rows,
              if (_loading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 24),
            ]),
    );
  }

  Widget _tile(EmotionEvent ev, DateTime t) {
    final e = emotionById(ev.emotionId);
    final mine = ev.senderUid == widget.uid;
    final who = mine ? '나' : (widget.partnerName ?? '상대');
    final rs = _reactions[ev.id] ?? const [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MkColors.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(lucideIcon(e?.icon), color: mine ? MkColors.text : MkColors.accent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$who · ${e?.label ?? ev.emotionId}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_hm(t), style: const TextStyle(fontSize: 12, color: MkColors.textSub)),
              if (rs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final r in rs)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: MkColors.background, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.cornerDownRight, size: 12, color: MkColors.textSub),
                        const SizedBox(width: 4),
                        Text(_reactionLabel(e, r.reactionId), style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                ]),
              ],
            ]),
          ),
          if (!mine && ev.readAt == null)
            const Icon(Icons.circle, size: 8, color: MkColors.accent),
        ]),
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
