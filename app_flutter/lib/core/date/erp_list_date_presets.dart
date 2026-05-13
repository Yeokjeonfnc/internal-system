// 목록·필터 화면 공통 — `최근 n개월` 등 일 단위 구간 프리셋.

/// [preset] 라벨에 맞는 `(시작일, 종료일)` — 종료는 오늘 0시 기준.
(DateTime, DateTime) erpPresetDateRange(String preset) {
  final n = DateTime.now();
  final end = DateTime(n.year, n.month, n.day);
  final days = switch (preset) {
    '최근1개월' => 30,
    '최근2개월' => 60,
    '최근3개월' => 90,
    '최근6개월' => 180,
    '최근1년' => 365,
    // 목록 기본 구간 — 오래된 개점일도 조회되게 넉넉히 잡음(실데이터 상한 가정).
    '전체' => 365 * 30,
    _ => 30,
  };
  return (end.subtract(Duration(days: days)), end);
}
