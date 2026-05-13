// 영업지역 관리 목록 행.

/// 단일 테이블 행.
class SalesAreaRow {
  const SalesAreaRow({
    required this.id,
    this.storeIdx,
    this.zoneIdx,
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

  /// 백엔드 [SalesAreaDto] JSON — `storeIdx`·`zoneIdx` 기준 목록 키.
  factory SalesAreaRow.fromJson(Map<String, dynamic> j) {
    final storeIdx = (j['storeIdx'] as num?)?.toInt();
    final zoneIdx = (j['zoneIdx'] as num?)?.toInt();
    return SalesAreaRow(
      id: _deriveRowId(storeIdx: storeIdx, zoneIdx: zoneIdx),
      storeIdx: storeIdx,
      zoneIdx: zoneIdx,
      settingDateYmd: _str(j['settingDateYmd']),
      propertyName: _str(j['propNm']),
      region: _str(j['regionNm']),
      franchiseLabel: _str(j['franchiseLabel']).isEmpty ? '-' : _str(j['franchiseLabel']),
      storeName: _str(j['storeNm']).isEmpty ? '-' : _str(j['storeNm']),
      brand: _str(j['brandNm']).isEmpty ? '-' : _str(j['brandNm']),
      areaSettingLabel: _str(j['areaSettingLabel']),
      salesAreaName: _str(j['salesAreaName']),
      isAreaConfigured: _bool(j['isAreaConfigured']),
      isStrategicOpening: _bool(j['isStrategicOpening']),
      isFranchise: _bool(j['isFranchise']),
    );
  }

  static int _deriveRowId({int? storeIdx, int? zoneIdx}) {
    if (storeIdx != null) return storeIdx;
    if (zoneIdx != null) return -zoneIdx;
    return 0;
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v == null) return false;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// 목록 행 식별(목록→등록 화면 전달). 가맹점이 있으면 `storeIdx`, 구역만 있으면 `-zoneIdx`.
  final int id;

  final int? storeIdx;
  final int? zoneIdx;
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
