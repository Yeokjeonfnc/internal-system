import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';

/// 영업지역 API — 백엔드 `DevController` `/sales-areas*`.
abstract final class SalesAreaApiPaths {
  static const String list = '/sales-areas';
  static const String mapPoints = '/sales-areas/map-points';
  static String storeDetail(int storeIdx) => '/sales-areas/stores/$storeIdx';
  static String zoneDetail(int zoneIdx) => '/sales-areas/zones/$zoneIdx';
  static String propertyDetail(int propIdx) => '/sales-areas/properties/$propIdx';
  static const String save = '/sales-areas/save';
  static const String zoneInfo = '/sales-areas/zone-info';
}

class SalesAreaApiService extends BaseRepository {
  static List<SalesAreaMapPoint>? _mapPointsLiteCache;
  static List<SalesAreaMapPoint>? _mapPointsGeometryCache;
  static Future<List<SalesAreaMapPoint>>? _liteFetchFuture;
  static Future<List<SalesAreaMapPoint>>? _geometryFetchFuture;
  static Future<void>? _prefetchFuture;

  /// 지도 화면 진입 전·직후 백그라운드 선로드 (lite 포인트).
  Future<void> prefetch({bool includeGeometry = false}) {
    return _prefetchFuture ??= _prefetchImpl(includeGeometry).whenComplete(() {
      _prefetchFuture = null;
    });
  }

  Future<void> _prefetchImpl(bool includeGeometry) async {
    await fetchMapPoints();
    if (includeGeometry) {
      await fetchMapPoints(includeGeometry: true);
    }
  }

  Future<List<SalesAreaRow>> fetchList() async {
    try {
      final r = await client.get(SalesAreaApiPaths.list);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        throw StateError('HTTP ${r.statusCode}');
      }
      if (!envelopeSuccess(r.data)) {
        throw StateError(envelopeMessage(r.data)?.trim().isNotEmpty == true
            ? envelopeMessage(r.data)!
            : 'success=false');
      }
      return parseDataList(r.data, SalesAreaRow.fromJson);
    } on DioException catch (e) {
      debugPrint('SalesAreaApiService.fetchList Dio: $e');
      final code = e.response?.statusCode;
      final tail = e.message ?? 'Dio';
      if (code != null) {
        throw StateError('HTTP $code: $tail');
      }
      throw StateError(
        '$tail — 연결 실패 시 PC면 localhost, Android 에뮬레이터면 10.0.2.2 등 API 주소를 확인하세요.',
      );
    }
  }

  Future<List<SalesAreaMapPoint>> fetchMapPoints({
    bool includeGeometry = false,
  }) async {
    if (includeGeometry) {
      if (_mapPointsGeometryCache != null) return _mapPointsGeometryCache!;
      return _geometryFetchFuture ??=
          _fetchMapPointsFromNetwork(includeGeometry: true).then((list) {
        _mapPointsGeometryCache = list;
        return list;
      }).whenComplete(() => _geometryFetchFuture = null);
    }
    if (_mapPointsLiteCache != null) return _mapPointsLiteCache!;
    return _liteFetchFuture ??=
        _fetchMapPointsFromNetwork(includeGeometry: false).then((list) {
      _mapPointsLiteCache = list;
      return list;
    }).whenComplete(() => _liteFetchFuture = null);
  }

  Future<List<SalesAreaMapPoint>> _fetchMapPointsFromNetwork({
    required bool includeGeometry,
  }) async {
    try {
      final r = await client.get(
        SalesAreaApiPaths.mapPoints,
        queryParameters: includeGeometry ? {'includeGeometry': 'true'} : null,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        throw StateError('HTTP ${r.statusCode}');
      }
      if (!envelopeSuccess(r.data)) {
        throw StateError(envelopeMessage(r.data) ?? 'success=false');
      }
      return parseDataList(r.data, SalesAreaMapPoint.fromJson);
    } on DioException catch (e) {
      debugPrint('SalesAreaApiService.fetchMapPoints Dio: $e');
      rethrow;
    }
  }

  static void invalidateMapPointsCache() {
    _mapPointsLiteCache = null;
    _mapPointsGeometryCache = null;
  }

  Future<SalesAreaRow> fetchDetailByStore(int storeIdx) async {
    return getData(
      SalesAreaApiPaths.storeDetail(storeIdx),
      fromJson: SalesAreaRow.fromJson,
    );
  }

  Future<SalesAreaRow> fetchDetailByZone(int zoneIdx) async {
    return getData(
      SalesAreaApiPaths.zoneDetail(zoneIdx),
      fromJson: SalesAreaRow.fromJson,
    );
  }

  Future<SalesAreaRow> fetchDetailByProperty(int propIdx) async {
    return getData(
      SalesAreaApiPaths.propertyDetail(propIdx),
      fromJson: SalesAreaRow.fromJson,
    );
  }

  /// [SalesAreaRow.id] → 상세 API.
  Future<SalesAreaRow> fetchDetailByRowId(int rowId) async {
    if (rowId > 0) return fetchDetailByStore(rowId);
    if (rowId > -1000000) return fetchDetailByZone(-rowId);
    return fetchDetailByProperty(-rowId - 1000000);
  }

  Future<SalesAreaRow> save({
    int? zoneIdx,
    int? propIdx,
    int? storeIdx,
    required String zoneNm,
    required String geometryType,
    required SalesAreaGeometry geometryData,
    String? brandCd,
    double? latitude,
    double? longitude,
  }) async {
    return postData(
      SalesAreaApiPaths.save,
      data: {
        'zoneIdx': ?zoneIdx,
        'propIdx': ?propIdx,
        'storeIdx': ?storeIdx,
        'zoneNm': zoneNm,
        'geometryType': geometryType,
        'geometryData': geometryData.toJson(),
        if (brandCd?.isNotEmpty == true) 'brandCd': brandCd,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      fromJson: SalesAreaRow.fromJson,
    );
  }

  Future<SalesAreaRow> saveZoneInfo({
    int? zoneIdx,
    int? propIdx,
    int? storeIdx,
    required String zoneInfo,
  }) async {
    return postData(
      SalesAreaApiPaths.zoneInfo,
      data: {
        'zoneIdx': ?zoneIdx,
        'propIdx': ?propIdx,
        'storeIdx': ?storeIdx,
        'zoneInfo': zoneInfo,
      },
      fromJson: SalesAreaRow.fromJson,
    );
  }
}
