import 'dart:math' as math;

import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';

/// 상세 지도 보기 옵션 기본값 — 가맹점 표시 Y, 영업지역(주변 구역) 표시 N.
const SalesAreaEditorViewOptions kSalesAreaEditorViewDefaults =
    SalesAreaEditorViewOptions(showStores: true, showSearchMarkers: true);

/// 영업지역 상세 지도 — 보기 옵션(체크박스).
class SalesAreaEditorViewOptions {
  const SalesAreaEditorViewOptions({
    this.showSalesAreas = false,
    this.showReferenceDistance = false,
    this.showStores = true,
    this.showRoadView = false,
    this.showSearchMarkers = true,
  });

  final bool showSalesAreas;
  final bool showReferenceDistance;
  final bool showStores;
  final bool showRoadView;
  final bool showSearchMarkers;

  SalesAreaEditorViewOptions copyWith({
    bool? showSalesAreas,
    bool? showReferenceDistance,
    bool? showStores,
    bool? showRoadView,
    bool? showSearchMarkers,
  }) {
    return SalesAreaEditorViewOptions(
      showSalesAreas: showSalesAreas ?? this.showSalesAreas,
      showReferenceDistance: showReferenceDistance ?? this.showReferenceDistance,
      showStores: showStores ?? this.showStores,
      showRoadView: showRoadView ?? this.showRoadView,
      showSearchMarkers: showSearchMarkers ?? this.showSearchMarkers,
    );
  }

  Map<String, dynamic> toJson() => {
        'showSalesAreas': showSalesAreas,
        'showReferenceDistance': showReferenceDistance,
        'showStores': showStores,
        'showRoadView': showRoadView,
        'showSearchMarkers': showSearchMarkers,
      };
}

/// 브랜드 라벨·좌표 기준 근처 가맹점·영업지역 필터.
abstract final class SalesAreaEditorMapMath {
  static const int defaultReferenceRadiusM = 500;
  static const int nearbyZonesRadiusM = 8000;
  /// bounds 수신 전 초기 가맹점 표시용(화면 줌 전 근처 탐색).
  static const int storeFallbackRadiusM = 8000;

  static int referenceRadiusMeters(String brandLabel) {
    final m = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(brandLabel);
    if (m != null) {
      return int.tryParse(m.group(1)!) ?? defaultReferenceRadiusM;
    }
    return defaultReferenceRadiusM;
  }

  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  static List<SalesAreaMapPoint> storesInBounds({
    required List<SalesAreaMapPoint> all,
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    int? excludeStoreIdx,
  }) {
    final minLat = math.min(swLat, neLat);
    final maxLat = math.max(swLat, neLat);
    final minLng = math.min(swLng, neLng);
    final maxLng = math.max(swLng, neLng);
    final out = <SalesAreaMapPoint>[];
    for (final p in all) {
      if (p.storeIdx == null || p.storeIdx == excludeStoreIdx) continue;
      final lat = p.lat;
      final lng = p.lng;
      if (lat == null || lng == null) continue;
      if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) continue;
      out.add(p);
    }
    return out;
  }

  static List<SalesAreaMapPoint> nearbyStores({
    required List<SalesAreaMapPoint> all,
    required double centerLat,
    required double centerLng,
    required int radiusM,
    int? excludeStoreIdx,
    String? regionCd,
    String? brandCd,
  }) {
    final out = <SalesAreaMapPoint>[];
    for (final p in all) {
      if (p.storeIdx == null || p.storeIdx == excludeStoreIdx) continue;
      final lat = p.lat;
      final lng = p.lng;
      if (lat == null || lng == null) continue;
      if (regionCd != null &&
          regionCd.isNotEmpty &&
          p.regionCd.isNotEmpty &&
          p.regionCd != regionCd) {
        continue;
      }
      if (brandCd != null &&
          brandCd.isNotEmpty &&
          p.brandCd.isNotEmpty &&
          p.brandCd != brandCd) {
        continue;
      }
      if (haversineMeters(centerLat, centerLng, lat, lng) <= radiusM) {
        out.add(p);
      }
    }
    return out;
  }

  static List<Map<String, dynamic>> zonesInBoundsJson({
    required List<SalesAreaMapPoint> all,
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    int? excludeZoneIdx,
  }) {
    final minLat = math.min(swLat, neLat);
    final maxLat = math.max(swLat, neLat);
    final minLng = math.min(swLng, neLng);
    final maxLng = math.max(swLng, neLng);
    final out = <Map<String, dynamic>>[];
    for (final p in all) {
      if (p.zoneIdx == null || p.zoneIdx == excludeZoneIdx) continue;
      final g = p.geometry;
      if (g == null) continue;
      if (!geometryIntersectsBounds(
        geometry: g,
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        pointLat: p.lat,
        pointLng: p.lng,
      )) {
        continue;
      }
      out.add({
        'zoneIdx': p.zoneIdx,
        'zoneNm': p.zoneNm,
        'geometryType': p.geometryType,
        'geometryData': g.toJson(),
      });
    }
    return out;
  }

  /// 폴리곤·원 bbox/꼭짓점 기준 — 중심 좌표만 보면 줌 인 시 영역이 사라지는 문제 방지.
  static bool geometryIntersectsBounds({
    required SalesAreaGeometry geometry,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    double? pointLat,
    double? pointLng,
  }) {
    bool pointIn(double lat, double lng) =>
        lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

    if (pointLat != null && pointLng != null && pointIn(pointLat, pointLng)) {
      return true;
    }

    if (geometry.isValidCircle && geometry.center != null && geometry.radius != null) {
      final c = geometry.center!;
      final r = geometry.radius!;
      final latDelta = r / 111320.0;
      final lngScale = math.cos(c.lat * math.pi / 180.0).abs();
      final lngDelta = r / (111320.0 * (lngScale < 0.01 ? 0.01 : lngScale));
      return !(c.lat + latDelta < minLat ||
          c.lat - latDelta > maxLat ||
          c.lng + lngDelta < minLng ||
          c.lng - lngDelta > maxLng);
    }

    final paths = geometry.paths;
    final hasPolygonPaths = paths != null && paths.length >= 3;
    if ((geometry.isValidPolygon || hasPolygonPaths) && paths != null) {
      for (final p in paths) {
        if (pointIn(p.lat, p.lng)) return true;
      }
      var pMinLat = double.infinity;
      var pMaxLat = -double.infinity;
      var pMinLng = double.infinity;
      var pMaxLng = -double.infinity;
      for (final p in paths) {
        pMinLat = math.min(pMinLat, p.lat);
        pMaxLat = math.max(pMaxLat, p.lat);
        pMinLng = math.min(pMinLng, p.lng);
        pMaxLng = math.max(pMaxLng, p.lng);
      }
      if (!pMinLat.isFinite) {
        return pointLat != null &&
            pointLng != null &&
            pointIn(pointLat, pointLng);
      }
      return !(pMaxLat < minLat ||
          pMinLat > maxLat ||
          pMaxLng < minLng ||
          pMinLng > maxLng);
    }

    return pointLat != null &&
        pointLng != null &&
        pointIn(pointLat, pointLng);
  }

  /// 동일 행정구역(region_cd) 영업지역 — [영업지역표시]용.
  static List<Map<String, dynamic>> zonesInRegionJson({
    required List<SalesAreaMapPoint> all,
    required String regionCd,
    String? brandCd,
    int? excludeZoneIdx,
  }) {
    final out = <Map<String, dynamic>>[];
    for (final p in all) {
      if (p.zoneIdx == null || p.zoneIdx == excludeZoneIdx) continue;
      final g = p.geometry;
      if (g == null) continue;
      if (regionCd.isNotEmpty &&
          p.regionCd.isNotEmpty &&
          p.regionCd != regionCd) {
        continue;
      }
      if (brandCd != null &&
          brandCd.isNotEmpty &&
          p.brandCd.isNotEmpty &&
          p.brandCd != brandCd) {
        continue;
      }
      out.add({
        'zoneIdx': p.zoneIdx,
        'zoneNm': p.zoneNm,
        'geometryType': p.geometryType,
        'geometryData': g.toJson(),
      });
    }
    return out;
  }

  static List<Map<String, dynamic>> nearbyZonesJson({
    required List<SalesAreaMapPoint> all,
    required double centerLat,
    required double centerLng,
    required int radiusM,
    int? excludeZoneIdx,
  }) {
    final out = <Map<String, dynamic>>[];
    for (final p in all) {
      if (p.zoneIdx == null || p.zoneIdx == excludeZoneIdx) continue;
      final g = p.geometry;
      if (g == null) continue;
      final lat = p.lat;
      final lng = p.lng;
      if (lat == null || lng == null) continue;
      if (haversineMeters(centerLat, centerLng, lat, lng) > radiusM) continue;
      out.add({
        'zoneIdx': p.zoneIdx,
        'zoneNm': p.zoneNm,
        'geometryType': p.geometryType,
        'geometryData': g.toJson(),
      });
    }
    return out;
  }
}
