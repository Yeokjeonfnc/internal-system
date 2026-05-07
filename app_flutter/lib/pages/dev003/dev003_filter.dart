// 영업지역 목록(sal001) 필터 상태.

class SalesAreaFilter {
  const SalesAreaFilter({
    this.salesAreaKeyword = '',
    this.brand = '전체',
    this.region = '전체',
    this.strategicOpeningOnly = false,
    this.includeNonFranchise = false,
    this.includeUnsetArea = false,
    this.rangeStart,
    this.rangeEnd,
  });

  /// 영업지역명·물건명 통합 검색(부분 일치, OR).
  final String salesAreaKeyword;
  final String brand;
  final String region;
  final bool strategicOpeningOnly;
  final bool includeNonFranchise;
  final bool includeUnsetArea;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  SalesAreaFilter copyWith({
    String? salesAreaKeyword,
    String? brand,
    String? region,
    bool? strategicOpeningOnly,
    bool? includeNonFranchise,
    bool? includeUnsetArea,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool clearRange = false,
  }) {
    return SalesAreaFilter(
      salesAreaKeyword: salesAreaKeyword ?? this.salesAreaKeyword,
      brand: brand ?? this.brand,
      region: region ?? this.region,
      strategicOpeningOnly: strategicOpeningOnly ?? this.strategicOpeningOnly,
      includeNonFranchise: includeNonFranchise ?? this.includeNonFranchise,
      includeUnsetArea: includeUnsetArea ?? this.includeUnsetArea,
      rangeStart: clearRange ? null : rangeStart ?? this.rangeStart,
      rangeEnd: clearRange ? null : rangeEnd ?? this.rangeEnd,
    );
  }
}
