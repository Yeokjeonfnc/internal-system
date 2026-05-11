// 가맹점 목록(str001) 필터 상태.

class StoreFilter {
  const StoreFilter({
    this.storeKeyword = '',
    this.brandCd = '전체',
    this.regionNms = const <String>{},
    this.storeStatus = const <String>{},
  });

  /// 가맹점명·가맹점코드 통합 검색어 (부분 일치, OR).
  final String storeKeyword;
  final String brandCd;

  /// [Store.region]과 매칭. 비어 있으면 지역 조건 없음(전체).
  final Set<String> regionNms;

  /// 비어 있으면 계약상태 조건 없음(전체). 1개 이상이면 해당 상태들만 OR 매칭.
  final Set<String> storeStatus;

  StoreFilter copy({
    String? storeKeyword,
    String? brandCd,
    Set<String>? regionNms,
    Set<String>? storeStatus,
    bool clearStatuses = false,
    bool clearRegions = false,
  }) {
    return StoreFilter(
      storeKeyword: storeKeyword ?? this.storeKeyword,
      brandCd: brandCd ?? this.brandCd,
      regionNms: clearRegions ? <String>{} : regionNms ?? this.regionNms,
      storeStatus: clearStatuses ? <String>{} : storeStatus ?? this.storeStatus,
    );
  }
}
