/// 활동관리결재(act003) 목록 상단 필터.
class Act003Filter {
  const Act003Filter({
    this.brandCd = '전체',
    required this.rangeStart,
    required this.rangeEnd,
    this.keyword = '',
  });

  final String brandCd;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String keyword;

  Act003Filter copyWith({
    String? brandCd,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? keyword,
  }) {
    return Act003Filter(
      brandCd: brandCd ?? this.brandCd,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      keyword: keyword ?? this.keyword,
    );
  }
}
