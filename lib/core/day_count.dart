/// 메인 상단 날짜 표시 (SHARED.md 5번: dDayFormat, countStartAsDayOne)
enum DDayFormat { dPlus, days, monthsDays, hidden }

DDayFormat parseDDayFormat(Object? v) => DDayFormat.values.firstWhere(
  (f) => f.name == v,
  orElse: () => DDayFormat.dPlus,
);

DateTime _d(DateTime t) => DateTime(t.year, t.month, t.day);

/// 경과 일수. countStartAsDayOne=true면 시작일 당일이 1일.
int dayCount(DateTime start, DateTime now, {bool countStartAsDayOne = true}) =>
    _d(now).difference(_d(start)).inDays + (countStartAsDayOne ? 1 : 0);

/// (개월, 일). 시작일로부터 꽉 찬 개월 수와 나머지 일수.
(int, int) monthsDays(
  DateTime start,
  DateTime now, {
  bool countStartAsDayOne = true,
}) {
  final s = _d(start), n = _d(now);
  var months = (n.year - s.year) * 12 + n.month - s.month;
  if (n.day < s.day) months--;
  if (months < 0) return (0, 0);
  final anchor = DateTime(s.year, s.month + months, s.day);
  final days = n.difference(anchor).inDays + (countStartAsDayOne ? 1 : 0);
  return (months, days);
}

String? formatDDay(
  DateTime? start,
  DateTime now,
  DDayFormat format, {
  bool countStartAsDayOne = true,
}) {
  if (start == null || format == DDayFormat.hidden) return null;
  final n = dayCount(start, now, countStartAsDayOne: countStartAsDayOne);
  switch (format) {
    case DDayFormat.dPlus:
      return n >= 0 ? 'D+$n' : 'D$n';
    case DDayFormat.days:
      return '$n일째';
    case DDayFormat.monthsDays:
      final (m, d) = monthsDays(
        start,
        now,
        countStartAsDayOne: countStartAsDayOne,
      );
      return m > 0 ? '$m개월 $d일' : '$d일';
    case DDayFormat.hidden:
      return null;
  }
}

String formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
