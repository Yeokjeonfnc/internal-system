/// 활동 관리(act002) 목록 상단 필터 스냅샷.
class Act002Filter {
  const Act002Filter({
    this.brandCd = '전체',
    required this.rangeStart,
    required this.rangeEnd,
    this.keyword = '',
  });

  final String brandCd;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String keyword;

  Act002Filter copyWith({
    String? brandCd,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? keyword,
  }) {
    return Act002Filter(
      brandCd: brandCd ?? this.brandCd,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      keyword: keyword ?? this.keyword,
    );
  }
}
