// 화면/API에서 오는 날짜 문자열·표시용 포맷 공통 처리.

/// `trim` 후 비어 있거나 `'-'`이면 null, 그 외는 [DateTime.parse] 시도.
DateTime? tryParseLooseDate(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty || t == '-') return null;
  try {
    return DateTime.parse(t);
  } catch (_) {
    return null;
  }
}

/// `yyyy-MM-dd`. [d]가 null이면 `'-'`.
String formatYmdOrDash(DateTime? d) {
  if (d == null) return '-';
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
