// 영업지역 관리 목록 행.

/// 단일 테이블 행.
class SalesAreaRow {
  const SalesAreaRow({
    required this.id,
    required this.settingDateYmd,
    required this.propertyName,
    required this.region,
    required this.franchiseLabel,
    required this.storeName,
    required this.brand,
    required this.areaSettingLabel,
    required this.salesAreaName,
    required this.isAreaConfigured,
    required this.isStrategicOpening,
    required this.isFranchise,
  });

  /// 목록 행 식별(목록→등록 화면 전달). 추후 API 키로 대체 예정.
  final int id;
  final String settingDateYmd;
  final String propertyName;
  final String region;
  final String franchiseLabel;
  final String storeName;
  final String brand;
  final String areaSettingLabel;
  final String salesAreaName;
  final bool isAreaConfigured;
  final bool isStrategicOpening;
  final bool isFranchise;
}
