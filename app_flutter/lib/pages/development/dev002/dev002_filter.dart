// 물건 목록(dev002) 필터 상태.


class PropertyFilter {
  const PropertyFilter({
    this.propertyKeyword = '',
    this.region = '전체',
    this.ownership = '전체',
    this.propStatus = '전체',
    this.regionNms = const <String>{},
  });

  /// 물건명·주소 통합 검색(부분 일치, OR).
  final String propertyKeyword;
  final String region;
  final String ownership;
  final String propStatus;

  final Set<String> regionNms;

  PropertyFilter copy({
    String? propertyKeyword,
    bool clearRegions = false,
    Set<String>? regionNms,
    String? ownership,
    String? propStatus,
    bool clearOwnership = false,
    bool clearStatus = false,
  }) {
    return PropertyFilter(
      propertyKeyword: propertyKeyword ?? this.propertyKeyword,
      regionNms: clearRegions ? <String>{} : regionNms ?? this.regionNms,
      ownership: ownership ?? this.ownership,
      propStatus: propStatus ?? this.propStatus,
    );
  }
}
