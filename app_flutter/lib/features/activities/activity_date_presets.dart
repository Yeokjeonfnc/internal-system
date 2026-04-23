// 활동일자 프리셋 — 목록·필터 화면에서 공유.

/// `최근 n개월` 프리셋 — 오늘(일 단위)을 끝으로 잡는다.
(DateTime, DateTime) kActivityPresetDateRange(String preset) {
  final n = DateTime.now();
  final end = DateTime(n.year, n.month, n.day);
  final days = switch (preset) {
    '최근1개월' => 30,
    '최근2개월' => 60,
    '최근3개월' => 90,
    '최근6개월' => 180,
    '최근1년' => 365,
    _ => 30,
  };
  return (end.subtract(Duration(days: days)), end);
}
