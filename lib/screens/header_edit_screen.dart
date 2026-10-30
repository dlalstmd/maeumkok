import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/day_count.dart';
import '../core/header_prefs.dart';
import '../core/theme.dart';
import '../services/couple_service.dart';

/// 상단 문구 편집 (v2_05_header_edit). 내 화면에만 적용.
class HeaderEditScreen extends StatefulWidget {
  const HeaderEditScreen({
    super.key,
    required this.uid,
    required this.initial,
    this.partnerName,
  });
  final String uid;
  final HeaderPrefs initial;
  final String? partnerName;

  @override
  State<HeaderEditScreen> createState() => _HeaderEditScreenState();
}

class _HeaderEditScreenState extends State<HeaderEditScreen> {
  late final _text = TextEditingController(
    text: widget.initial.headerText ?? '',
  );
  late DateTime? _start = widget.initial.startDate;
  late DDayFormat _format = widget.initial.format;
  late bool _dayOne = widget.initial.countStartAsDayOne;
  bool _saving = false;

  HeaderPrefs get _prefs => HeaderPrefs(
    headerText: _text.text,
    startDate: _start,
    format: _format,
    countStartAsDayOne: _dayOne,
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    await CoupleService().userRef(widget.uid).update(_prefs.toFirestore());
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _formatLabel(DDayFormat f) {
    final s = _start ?? DateTime.now();
    return switch (f) {
      DDayFormat.hidden => '숨김',
      _ => formatDDay(s, DateTime.now(), f, countStartAsDayOne: _dayOne)!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = HeaderPrefs(
      headerText: _text.text.trim().isEmpty ? null : _text.text.trim(),
      startDate: _start,
      format: _format,
      countStartAsDayOne: _dayOne,
    );
    final sub = p.subtitle(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '상단 문구 편집',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MkColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '미리보기 · 내 화면에만 보여요',
                  style: TextStyle(fontSize: 12, color: MkColors.textSub),
                ),
                const SizedBox(height: 12),
                if (sub != null)
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MkColors.textSub,
                    ),
                  ),
                Text(
                  p.title(widget.partnerName),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Label('문구'),
          TextField(
            controller: _text,
            maxLength: kHeaderTextMax,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.partnerName == null
                  ? '예: 오늘도 우리'
                  : '${widget.partnerName}랑',
              counterText: '',
              suffixText: '${_text.text.characters.length}/$kHeaderTextMax',
            ),
          ),
          const SizedBox(height: 20),
          const _Label('시작일'),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _start ?? DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _start = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(LucideIcons.calendar),
              ),
              child: Text(
                _start == null
                    ? '커플 연결일'
                    : '${_start!.year}년 ${_start!.month}월 ${_start!.day}일',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Label('날짜 표시 방식'),
          Row(
            children: [
              for (final f in DDayFormat.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          _formatLabel(f),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: _format == f,
                      showCheckmark: false,
                      selectedColor: MkColors.text,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: _format == f ? Colors.white : MkColors.textSub,
                      ),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _format = f),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('시작일을 1일로 세기'),
            value: _dayOne,
            activeTrackColor: MkColors.accent,
            onChanged: (v) => setState(() => _dayOne = v),
          ),
          const Text(
            '문구와 날짜는 각자 따로 설정돼요. 상대 화면에는 영향 없어요.',
            style: TextStyle(fontSize: 12, color: MkColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}
