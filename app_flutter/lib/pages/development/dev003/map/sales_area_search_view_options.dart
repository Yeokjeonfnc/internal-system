/// 영업지역 검색 지도 — 보기 옵션(체크박스).
class SalesAreaSearchViewOptions {
  const SalesAreaSearchViewOptions({
    this.showSalesAreas = false,
    this.showStores = true,
    this.showRoadView = false,
    this.showSearchMarkers = true,
    this.brandCd,
  });

  final bool showSalesAreas;
  final bool showStores;
  final bool showRoadView;
  final bool showSearchMarkers;
  final String? brandCd;

  SalesAreaSearchViewOptions copyWith({
    bool? showSalesAreas,
    bool? showStores,
    bool? showRoadView,
    bool? showSearchMarkers,
    String? brandCd,
    bool clearBrandCd = false,
  }) {
    return SalesAreaSearchViewOptions(
      showSalesAreas: showSalesAreas ?? this.showSalesAreas,
      showStores: showStores ?? this.showStores,
      showRoadView: showRoadView ?? this.showRoadView,
      showSearchMarkers: showSearchMarkers ?? this.showSearchMarkers,
      brandCd: clearBrandCd ? null : (brandCd ?? this.brandCd),
    );
  }

  Map<String, dynamic> toJson() => {
        'showSalesAreas': showSalesAreas,
        'showStores': showStores,
        'showRoadView': showRoadView,
        'showSearchMarkers': showSearchMarkers,
        'brandCd': brandCd ?? '',
      };

  @override
  bool operator ==(Object other) {
    return other is SalesAreaSearchViewOptions &&
        other.showSalesAreas == showSalesAreas &&
        other.showStores == showStores &&
        other.showRoadView == showRoadView &&
        other.showSearchMarkers == showSearchMarkers &&
        other.brandCd == brandCd;
  }

  @override
  int get hashCode =>
      Object.hash(showSalesAreas, showStores, showRoadView, showSearchMarkers, brandCd);
}

const SalesAreaSearchViewOptions kSalesAreaSearchViewDefaults =
    SalesAreaSearchViewOptions(showStores: true, showSearchMarkers: false);
