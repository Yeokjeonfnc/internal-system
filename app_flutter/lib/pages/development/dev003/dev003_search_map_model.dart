class SalesAreaMapStats {
  const SalesAreaMapStats({
    required this.total,
    required this.visible,
    required this.vertices,
    required this.zoneCount,
  });

  /// 가맹점(개점) 전체 건수.
  final int total;

  /// 검색·필터 후 표시 대상 건수.
  final int visible;

  /// 화면에 그린 영업지역 폴리곤 꼭짓점 수.
  final int vertices;

  /// geometry가 설정된 영업지역(구역) 건수.
  final int zoneCount;
}
