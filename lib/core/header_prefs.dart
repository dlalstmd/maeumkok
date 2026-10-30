import 'package:cloud_firestore/cloud_firestore.dart';

import 'day_count.dart';

/// users/{uid} 개인 헤더 설정 (커플 공유 아님)
const kHeaderTextMax = 20;

class HeaderPrefs {
  const HeaderPrefs({
    this.headerText,
    this.startDate,
    this.format = DDayFormat.dPlus,
    this.countStartAsDayOne = true,
  });
  final String? headerText;
  final DateTime? startDate;
  final DDayFormat format;
  final bool countStartAsDayOne;

  factory HeaderPrefs.fromUser(
    Map<String, dynamic>? u, {
    DateTime? coupleCreatedAt,
  }) {
    final raw = u?['startDate'];
    DateTime? start;
    if (raw is String) start = DateTime.tryParse(raw);
    if (raw is Timestamp) start = raw.toDate();
    return HeaderPrefs(
      headerText: u?['headerText'] as String?,
      startDate: start ?? coupleCreatedAt,
      format: parseDDayFormat(u?['dDayFormat']),
      countStartAsDayOne: (u?['countStartAsDayOne'] as bool?) ?? true,
    );
  }

  /// startDate는 'YYYY-MM-DD' 문자열로 저장(시간대 영향 없음)
  Map<String, Object?> toFirestore() => {
    'headerText': (headerText == null || headerText!.trim().isEmpty)
        ? null
        : headerText!.trim(),
    'startDate': startDate == null
        ? null
        : '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
    'dDayFormat': format.name,
    'countStartAsDayOne': countStartAsDayOne,
  };

  String title(String? partnerName) =>
      headerText ?? (partnerName == null ? '마음콕' : '$partnerName랑');

  String? subtitle(DateTime now) {
    final s = startDate;
    final d = formatDDay(
      s,
      now,
      format,
      countStartAsDayOne: countStartAsDayOne,
    );
    if (s == null || d == null) return null;
    return '${formatDate(s)}부터 · $d';
  }
}
