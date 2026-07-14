// 영업지역 관리 목록 행.

import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';

/// 단일 테이블 행.
class SalesAreaRow {
  const SalesAreaRow({
    required this.id,
    this.storeIdx,
    this.zoneIdx,
    this.propIdx,
    required this.settingDateYmd,
    required this.propertyName,
    required this.regionCd,
    required this.region,
    required this.franchiseLabel,
    required this.storeName,
    required this.brand,
    required this.brandCd,
    required this.areaSettingLabel,
    required this.salesAreaName,
    this.zoneInfo = '',
    required this.isAreaConfigured,
    required this.isStrategicOpening,
    required this.isFranchise,
    required this.mapAddress,
    this.latitude,
    this.longitude,
    this.geometryType,
    this.geometry,
  });

  /// 백엔드 [SalesAreaDto] JSON — 목록→상세 라우팅 키.
  factory SalesAreaRow.fromJson(Map<String, dynamic> j) {
    final storeIdx = (j['storeIdx'] as num?)?.toInt();
    final zoneIdx = (j['zoneIdx'] as num?)?.toInt();
    final propIdx = (j['propIdx'] as num?)?.toInt();
    return SalesAreaRow(
      id: _deriveRowId(storeIdx: storeIdx, zoneIdx: zoneIdx, propIdx: propIdx),
      storeIdx: storeIdx,
      zoneIdx: zoneIdx,
      propIdx: (j['propIdx'] as num?)?.toInt(),
      settingDateYmd: _str(j['settingDateYmd']),
      propertyName: _str(j['propNm']),
      regionCd: _str(j['regionCd']),
      region: _str(j['regionNm']).isNotEmpty
          ? _str(j['regionNm'])
          : _str(j['region']),
      franchiseLabel: _str(j['franchiseLabel']).isEmpty
          ? '-'
          : _str(j['franchiseLabel']),
      storeName: _str(j['storeNm']).isEmpty ? '-' : _str(j['storeNm']),
      brand: _str(j['brandNm']).isEmpty ? '-' : _str(j['brandNm']),
      brandCd: _str(j['brandCd']),
      areaSettingLabel: _str(j['areaSettingLabel']),
      salesAreaName: _str(j['salesAreaName']),
      zoneInfo: _str(j['zoneInfo']),
      isAreaConfigured: _bool(j['isAreaConfigured']),
      isStrategicOpening: _bool(j['isStrategicOpening']),
      isFranchise: _bool(j['isFranchise']),
      mapAddress: _str(j['mapAddress']),
      latitude: _coord(j['latitude']),
      longitude: _coord(j['longitude']),
      geometryType: _str(j['geometryType']).isEmpty
          ? null
          : _str(j['geometryType']),
      geometry: j['geometryData'] is Map
          ? SalesAreaGeometry.fromJson(j['geometryData'])
          : null,
    );
  }

  static double? _coord(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _deriveRowId({int? storeIdx, int? zoneIdx, int? propIdx}) {
    return salesAreaRowIdFromKeys(
          storeIdx: storeIdx,
          zoneIdx: zoneIdx,
          propIdx: propIdx,
        ) ??
        0;
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v == null) return false;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// 목록 행 식별(목록→등록 화면 전달).
  /// 가맹점 → `storeIdx`, 전략출점 → `-zoneIdx`, 물건만 → `-1000000 - propIdx`.
  final int id;

  final int? storeIdx;
  final int? zoneIdx;
  final int? propIdx;
  final String settingDateYmd;
  final String propertyName;
  final String regionCd;
  final String region;
  final String franchiseLabel;
  final String storeName;
  final String brand;
  final String brandCd;
  final String areaSettingLabel;
  final String salesAreaName;
  final String zoneInfo;
  final bool isAreaConfigured;
  final bool isStrategicOpening;
  final bool isFranchise;
  final String mapAddress;
  final double? latitude;
  final double? longitude;
  final String? geometryType;
  final SalesAreaGeometry? geometry;

  static const String kClosedStorePrefix = '[폐점]';

  static bool hasClosedPrefix(String name) =>
      name.trim().startsWith(kClosedStorePrefix);

  static String stripClosedPrefix(String name) {
    final trimmed = name.trim();
    if (!hasClosedPrefix(trimmed)) return trimmed;
    return trimmed.substring(kClosedStorePrefix.length).trim();
  }

  /// 목록·상세·지도 공통 — 폐점이면 `[폐점]` 접두사를 붙인다.
  static String formatClosedStoreName(String name, {required bool closed}) {
    final stripped = stripClosedPrefix(name);
    if (stripped.isEmpty || stripped == '-') return name;
    if (!closed) return stripped;
    return '$kClosedStorePrefix $stripped';
  }

  bool get isStoreClosed => hasClosedPrefix(storeName);

  String get displayStoreName => storeName;

  /// 상세 API 없이 지도를 먼저 띄울 수 있는지 (geometry 또는 좌표만 있는 경우).
  bool get canBootstrapMapWithoutDetailFetch {
    final g = geometry;
    if (g != null && (g.isValidPolygon || g.isValidCircle)) return true;
    if (!isAreaConfigured && latitude != null && longitude != null) return true;
    return false;
  }

  /// 지도용 상세 API를 다시 호출해야 하는지.
  bool get needsSalesAreaDetailFetch {
    if (canBootstrapMapWithoutDetailFetch) return false;
    return storeIdx != null || zoneIdx != null || propIdx != null;
  }

  /// 상세 API 응답에 접두사가 빠져도 목록 행 기준으로 폐점 표시를 유지한다.
  SalesAreaRow withMergedStoreDisplay(SalesAreaRow listRow) {
    final closed =
        hasClosedPrefix(listRow.storeName) || hasClosedPrefix(storeName);
    final base = storeName.isNotEmpty && storeName != '-'
        ? storeName
        : listRow.storeName;
    return copyWith(
      storeName: formatClosedStoreName(base, closed: closed),
    );
  }

  SalesAreaRow copyWith({
    int? id,
    int? storeIdx,
    int? zoneIdx,
    int? propIdx,
    String? settingDateYmd,
    String? propertyName,
    String? regionCd,
    String? region,
    String? franchiseLabel,
    String? storeName,
    String? brand,
    String? brandCd,
    String? areaSettingLabel,
    String? salesAreaName,
    String? zoneInfo,
    bool? isAreaConfigured,
    bool? isStrategicOpening,
    bool? isFranchise,
    String? mapAddress,
    double? latitude,
    double? longitude,
    String? geometryType,
    SalesAreaGeometry? geometry,
  }) {
    return SalesAreaRow(
      id: id ?? this.id,
      storeIdx: storeIdx ?? this.storeIdx,
      zoneIdx: zoneIdx ?? this.zoneIdx,
      propIdx: propIdx ?? this.propIdx,
      settingDateYmd: settingDateYmd ?? this.settingDateYmd,
      propertyName: propertyName ?? this.propertyName,
      regionCd: regionCd ?? this.regionCd,
      region: region ?? this.region,
      franchiseLabel: franchiseLabel ?? this.franchiseLabel,
      storeName: storeName ?? this.storeName,
      brand: brand ?? this.brand,
      brandCd: brandCd ?? this.brandCd,
      areaSettingLabel: areaSettingLabel ?? this.areaSettingLabel,
      salesAreaName: salesAreaName ?? this.salesAreaName,
      zoneInfo: zoneInfo ?? this.zoneInfo,
      isAreaConfigured: isAreaConfigured ?? this.isAreaConfigured,
      isStrategicOpening: isStrategicOpening ?? this.isStrategicOpening,
      isFranchise: isFranchise ?? this.isFranchise,
      mapAddress: mapAddress ?? this.mapAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geometryType: geometryType ?? this.geometryType,
      geometry: geometry ?? this.geometry,
    );
  }

  String get detailHeadline {
    if (isFranchise) {
      final store = displayStoreName.trim();
      if (store.isNotEmpty && store != '-') return store;
    }
    final prop = propertyName.trim();
    if (prop.isNotEmpty) return prop;
    return '영업지역';
  }

  String get mapTitle {
    final store = displayStoreName.trim();
    if (store.isNotEmpty && store != '-') return store;
    final prop = propertyName.trim();
    if (prop.isNotEmpty) return prop;
    final area = salesAreaName.trim();
    if (area.isNotEmpty) return area;
    return '영업지역';
  }
}

/// 목록·라우팅용 행 id — [SalesAreaRow.id] 규칙과 동일.
int? salesAreaRowIdFromKeys({int? storeIdx, int? zoneIdx, int? propIdx}) {
  if (storeIdx != null && storeIdx > 0) return storeIdx;
  if (zoneIdx != null && zoneIdx > 0) return -zoneIdx;
  if (propIdx != null && propIdx > 0) return -1000000 - propIdx;
  return null;
}
