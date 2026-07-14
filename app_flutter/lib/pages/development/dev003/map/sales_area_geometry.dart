// 영업지역 geometry — sale_zone_mst.geometry_data JSON.

class SalesAreaGeometry {
  const SalesAreaGeometry({
    required this.type,
    this.paths,
    this.center,
    this.radius,
  });

  factory SalesAreaGeometry.fromJson(dynamic raw) {
    if (raw is! Map) return const SalesAreaGeometry(type: '');
    List<SalesAreaLatLng>? paths;
    final pathsRaw = raw['paths'];
    if (pathsRaw is List) {
      paths = pathsRaw
          .map((p) => SalesAreaLatLng.fromJson(p))
          .where((p) => p != null)
          .cast<SalesAreaLatLng>()
          .toList();
    }
    SalesAreaLatLng? center;
    final centerRaw = raw['center'];
    if (centerRaw is Map) {
      center = SalesAreaLatLng.fromJson(centerRaw);
    }
    final radius = (raw['radius'] as num?)?.toDouble();
    var type = (raw['type'] ?? '').toString().toUpperCase();
    if (type.isEmpty && paths != null && paths.length >= 3) {
      type = 'POLYGON';
    }
    if (type.isEmpty && center != null && radius != null && radius > 0) {
      type = 'CIRCLE';
    }
    return SalesAreaGeometry(
      type: type,
      paths: paths,
      center: center,
      radius: radius,
    );
  }

  final String type;
  final List<SalesAreaLatLng>? paths;
  final SalesAreaLatLng? center;
  final double? radius;

  Map<String, dynamic> toJson() {
    if (type == 'CIRCLE' && center != null && radius != null) {
      return {'type': 'CIRCLE', 'center': center!.toJson(), 'radius': radius};
    }
    return {
      'type': 'POLYGON',
      'paths': (paths ?? []).map((p) => p.toJson()).toList(),
    };
  }

  bool get isValidPolygon =>
      type == 'POLYGON' && paths != null && paths!.length >= 3;

  bool get isValidCircle =>
      type == 'CIRCLE' && center != null && radius != null && radius! > 0;
}

class SalesAreaLatLng {
  const SalesAreaLatLng({required this.lat, required this.lng});

  static SalesAreaLatLng? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return SalesAreaLatLng(lat: lat, lng: lng);
  }

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class SalesAreaMapPoint {
  const SalesAreaMapPoint({
    this.zoneIdx,
    this.storeIdx,
    required this.storeNm,
    required this.zoneNm,
    this.lat,
    this.lng,
    this.regionCd = '',
    this.brandCd = '',
    this.geometryType,
    this.geometry,
  });

  static double? _jsonDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory SalesAreaMapPoint.fromJson(Map<String, dynamic> j) {
    SalesAreaGeometry? geometry;
    final g = j['geometryData'];
    if (g is Map<String, dynamic>) {
      geometry = SalesAreaGeometry.fromJson(g);
    }
    return SalesAreaMapPoint(
      zoneIdx: (j['zoneIdx'] as num?)?.toInt(),
      storeIdx: (j['storeIdx'] as num?)?.toInt(),
      storeNm: (j['storeNm'] ?? '').toString(),
      zoneNm: (j['zoneNm'] ?? '').toString(),
      lat: _jsonDouble(j['lat']),
      lng: _jsonDouble(j['lng']),
      regionCd: (j['regionCd'] ?? '').toString(),
      brandCd: (j['brandCd'] ?? '').toString(),
      geometryType: (j['geometryType'] as String?)?.toUpperCase(),
      geometry: geometry,
    );
  }

  final int? zoneIdx;
  final int? storeIdx;
  final String storeNm;
  final String zoneNm;
  final double? lat;
  final double? lng;
  final String regionCd;
  final String brandCd;
  final String? geometryType;
  final SalesAreaGeometry? geometry;

  Map<String, dynamic> toJson({bool includeGeometry = true}) => {
    'zoneIdx': zoneIdx,
    'storeIdx': storeIdx,
    'storeNm': storeNm,
    'zoneNm': zoneNm,
    'lat': lat,
    'lng': lng,
    'geometryType': geometryType,
    if (includeGeometry && geometry != null) 'geometryData': geometry!.toJson(),
  };

  /// 지도 iframe postMessage용 — geometry·빈 문자열 제외(대량 전송 경량화).
  Map<String, dynamic> toMapPointJson() {
    final m = <String, dynamic>{'lat': lat, 'lng': lng};
    if (zoneIdx != null) m['zoneIdx'] = zoneIdx;
    if (storeIdx != null) m['storeIdx'] = storeIdx;
    if (storeNm.isNotEmpty) m['storeNm'] = storeNm;
    if (brandCd.isNotEmpty) m['brandCd'] = brandCd;
    if (geometryType != null && geometryType!.isNotEmpty) {
      m['geometryType'] = geometryType;
    }
    return m;
  }
}

/// 가맹점명·영업지역명 부분 일치 검색(공백 무시).
List<SalesAreaMapPoint> filterSalesAreaMapPoints(
  List<SalesAreaMapPoint> points,
  String keyword,
) {
  final term = keyword.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  if (term.isEmpty) return points;
  return points
      .where((p) {
        final store = p.storeNm.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final zone = p.zoneNm.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        return store.contains(term) || zone.contains(term);
      })
      .toList(growable: false);
}
