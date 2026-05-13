// 영업지역 목록(sal001) 필터 상태.

class SalesAreaFilter {
  const SalesAreaFilter({
    this.keyword = '',
    this.brandCd = '전체',
    this.regionCd = '전체',
    this.strategicOpeningOnly = false,
    this.includeNonFranchise = true,
    this.includeUnsetArea = true,
    required this.rangeStart,
    required this.rangeEnd,
  });

  /// 영업지역명·물건명 통합 검색(부분 일치, OR).
  final String keyword;
  final String brandCd;
  final String regionCd;
  final bool strategicOpeningOnly;
  final bool includeNonFranchise;
  final bool includeUnsetArea;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  SalesAreaFilter copyWith({
    String? keyword,
    String? brandCd,
    String? regionCd,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool? strategicOpeningOnly,
    bool? includeNonFranchise,
    bool? includeUnsetArea,
  }) {
    return SalesAreaFilter(
      keyword: keyword ?? this.keyword,
      brandCd: brandCd ?? this.brandCd,
      regionCd: regionCd ?? this.regionCd,
      strategicOpeningOnly: strategicOpeningOnly ?? this.strategicOpeningOnly,
      includeNonFranchise: includeNonFranchise ?? this.includeNonFranchise,
      includeUnsetArea: includeUnsetArea ?? this.includeUnsetArea,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }
}
