import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_webview_host.dart';

bool _hasValidMapAddress(String address) {
  final a = address.trim();
  if (a.isEmpty || a == '(-)' || a == '-') return false;
  return true;
}

(double?, double?)? _franchisePrimaryPin(SalesAreaRow row) {
  if (row.storeIdx == null || row.propIdx == null) return null;
  if (!_hasValidMapAddress(row.mapAddress)) return null;
  final lat = row.latitude;
  final lng = row.longitude;
  if (lat == null || lng == null) return null;
  return (lat, lng);
}

class SalesAreaEditorMapFrame extends StatefulWidget {
  const SalesAreaEditorMapFrame({
    super.key,
    required this.row,
    required this.zoneNameController,
    required this.viewOptions,
    required this.onSaved,
    this.readOnly = false,
    this.brandCd,
    this.brandLabel,
    this.onSaveError,
    this.onAddressResolved,
    this.onDetailLoaded,
    this.initialDetail,
  });

  final SalesAreaRow row;
  final bool readOnly;
  final TextEditingController zoneNameController;
  final SalesAreaEditorViewOptions viewOptions;
  final String? brandCd;
  final String? brandLabel;
  final VoidCallback onSaved;
  final void Function(String message)? onSaveError;
  final ValueChanged<String>? onAddressResolved;
  final ValueChanged<SalesAreaRow>? onDetailLoaded;
  /// 이미 로드된 상세(다이얼로그·상세 API) — 중복 조회 생략.
  final SalesAreaRow? initialDetail;

  @override
  State<SalesAreaEditorMapFrame> createState() => SalesAreaEditorMapFrameState();
}

class SalesAreaEditorMapFrameState extends State<SalesAreaEditorMapFrame> {
  final _hostKey = GlobalKey<SalesAreaMapWebViewHostState>();
  bool _mapReady = false;
  bool _initSent = false;
  SalesAreaRow? _detail;
  List<SalesAreaMapPoint>? _mapPoints;
  List<SalesAreaMapPoint>? _mapPointsWithGeometry;
  Future<void>? _geometryCatalogFuture;

  SalesAreaRow get _row => _detail ?? widget.row;

  @override
  void initState() {
    super.initState();
    unawaited(SalesAreaApiService().prefetch());
    final seed = widget.initialDetail;
    if (seed != null) {
      _detail = seed.withMergedStoreDisplay(widget.row);
    } else if (!widget.row.needsSalesAreaDetailFetch) {
      _detail = widget.row;
    } else {
      unawaited(_loadDetail());
    }
    if (widget.viewOptions.showStores) {
      unawaited(_loadMapCatalog());
    }
  }

  @override
  void didUpdateWidget(covariant SalesAreaEditorMapFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.readOnly) return;
    if (oldWidget.readOnly != widget.readOnly) {
      _sendReadOnly();
    }
    if (oldWidget.viewOptions.showStores != widget.viewOptions.showStores &&
        widget.viewOptions.showStores &&
        _mapPoints == null) {
      unawaited(_loadMapCatalog());
    }
    if (oldWidget.viewOptions != widget.viewOptions ||
        oldWidget.brandCd != widget.brandCd ||
        oldWidget.brandLabel != widget.brandLabel) {
      if (widget.viewOptions.showSalesAreas) {
        unawaited(_ensureGeometryCatalog());
      } else {
        _sendViewOptions();
      }
    }
  }

  String _effectiveBrandCd(SalesAreaRow d) {
    final override = widget.brandCd?.trim();
    if (override != null && override.isNotEmpty) return override;
    if (d.brandCd.trim().isNotEmpty) return d.brandCd.trim();
    return widget.row.brandCd.trim();
  }

  String _effectiveBrandLabel(SalesAreaRow d) {
    final override = widget.brandLabel?.trim();
    if (override != null && override.isNotEmpty) return override;
    final name = d.brand.trim();
    if (name.isNotEmpty && name != '-') return name;
    final rowName = widget.row.brand.trim();
    if (rowName.isNotEmpty && rowName != '-') return rowName;
    return '';
  }

  Future<void> _loadDetail() async {
    if (widget.initialDetail != null) return;
    final api = SalesAreaApiService();
    try {
      final SalesAreaRow detail;
      final row = widget.row;
      final zoneIdx = row.zoneIdx;
      if (row.storeIdx != null && row.id == row.storeIdx) {
        detail = await api.fetchDetailByStore(row.storeIdx!);
      } else if (zoneIdx != null && row.id == -zoneIdx) {
        detail = await api.fetchDetailByZone(zoneIdx);
      } else if (row.propIdx != null) {
        detail = await api.fetchDetailByProperty(row.propIdx!);
      } else {
        _sendInitIfReady();
        return;
      }
      if (!mounted) return;
      final merged = detail.withMergedStoreDisplay(widget.row);
      setState(() => _detail = merged);
      widget.onDetailLoaded?.call(merged);
      if (_initSent) {
        _syncDetailToMap(merged, fitViewport: true);
        _sendViewOptions();
      } else {
        _sendInitIfReady();
      }
    } catch (e) {
      widget.onSaveError?.call('상세 조회 실패: $e');
      _sendInitIfReady();
    }
  }

  void _syncDetailToMap(SalesAreaRow d, {bool fitViewport = false}) {
    if (!_initSent || !_mapReady) return;
    final geom = d.geometry;
    if (geom != null && (geom.isValidPolygon || geom.isValidCircle)) {
      _hostKey.currentState?.postPayload({
        'op': kSalesAreaOpUpdateGeometry,
        'zoneIdx': d.zoneIdx,
        'zoneNm': d.salesAreaName.isNotEmpty
            ? d.salesAreaName
            : widget.zoneNameController.text.trim(),
        'geometryType': d.geometryType,
        'geometryData': geom.toJson(),
        'lat': d.latitude,
        'lng': d.longitude,
        'fitViewport': fitViewport,
      });
    }
    _sendViewOptions();
  }

  Future<void> _loadMapCatalog() async {
    try {
      _mapPoints = await SalesAreaApiService().fetchMapPoints();
      if (mounted) _sendViewOptions();
    } catch (_) {}
  }

  Future<void> _ensureGeometryCatalog() async {
    _geometryCatalogFuture ??= _loadGeometryCatalog();
    await _geometryCatalogFuture;
    if (mounted && _initSent) _sendViewOptions();
  }

  Future<void> _loadGeometryCatalog() async {
    try {
      _mapPointsWithGeometry = await SalesAreaApiService().fetchMapPoints(
        includeGeometry: true,
      );
    } catch (_) {
      _mapPointsWithGeometry = const [];
    }
  }

  Map<String, dynamic> _viewLayerPayload(SalesAreaRow d) {
    final lat = d.latitude;
    final lng = d.longitude;
    final brandCd = _effectiveBrandCd(d);
    final brandLabel = _effectiveBrandLabel(d);
    final refM = SalesAreaEditorMapMath.referenceRadiusMeters(
      brandLabel.isNotEmpty ? brandLabel : brandCd,
    );
    final opts = widget.viewOptions;

    final payload = <String, dynamic>{
      'viewOptions': opts.toJson(),
      'referenceRadiusM': refM,
      'storeIdx': d.storeIdx,
      'zoneIdx': d.zoneIdx,
      'propIdx': d.propIdx,
      'storeNm': d.displayStoreName,
      'regionCd': d.regionCd,
      'brandCd': brandCd,
      'lat': lat,
      'lng': lng,
    };

    if (opts.showStores) {
      final pin = _franchisePrimaryPin(d);
      if (pin != null) {
        payload['primaryPinLat'] = pin.$1;
        payload['primaryPinLng'] = pin.$2;
      }
    }

    if (opts.showStores && lat != null && lng != null && _mapPoints != null) {
      final stores = SalesAreaEditorMapMath.nearbyStores(
        all: _mapPoints!,
        centerLat: lat,
        centerLng: lng,
        radiusM: SalesAreaEditorMapMath.storeFallbackRadiusM,
        excludeStoreIdx: d.storeIdx,
      );
      payload['nearbyStores'] = stores
          .map(
            (p) => {
              'storeIdx': p.storeIdx,
              'storeNm': p.storeNm,
              'lat': p.lat,
              'lng': p.lng,
              'isClosed': SalesAreaRow.hasClosedPrefix(p.storeNm),
            },
          )
          .toList(growable: false);
    }

    if (opts.showSalesAreas) {
      if (_mapPointsWithGeometry != null && lat != null && lng != null) {
        payload['nearbyZones'] = SalesAreaEditorMapMath.nearbyZonesJson(
          all: _mapPointsWithGeometry!,
          centerLat: lat,
          centerLng: lng,
          radiusM: SalesAreaEditorMapMath.nearbyZonesRadiusM,
          excludeZoneIdx: d.zoneIdx,
        );
      } else {
        payload['nearbyZones'] = const [];
      }
    }

    return payload;
  }

  void sendCommand(String cmd) {}
  void searchAddress(String keyword) {}
  void setMapPointerEvents(bool enabled) {}
  void requestSaveFromMap() {}

  void _sendInitIfReady() {
    if (!_mapReady || _initSent) return;
    final appKey = resolveKakaoMapAppKey();
    if (appKey.isEmpty) {
      widget.onSaveError?.call('KAKAO_MAP_KEY_EMPTY');
      return;
    }
    final d = _row;
    final zoneNm = widget.zoneNameController.text.trim().isNotEmpty
        ? widget.zoneNameController.text.trim()
        : (d.salesAreaName.isNotEmpty ? d.salesAreaName : d.storeName);

    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpInit,
      'readOnly': true,
      'appKey': appKey,
      'storeIdx': d.storeIdx,
      'zoneIdx': d.zoneIdx,
      'propIdx': d.propIdx,
      'zoneNm': zoneNm,
      'storeNm': d.displayStoreName,
      'address': d.mapAddress,
      'lat': d.latitude,
      'lng': d.longitude,
      'geometryType': d.geometryType,
      'geometryData': d.geometry?.toJson(),
      ..._viewLayerPayload(d),
    });
    _initSent = true;
    _sendReadOnly();
    if (widget.viewOptions.showSalesAreas) {
      unawaited(_ensureGeometryCatalog());
    }
    _sendViewOptions();
  }

  void _sendReadOnly() {
    if (!_initSent || !_mapReady) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpSetReadOnly,
      'readOnly': true,
    });
  }

  void _sendViewOptions() {
    if (!_initSent || !_mapReady) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpViewOptions,
      ..._viewLayerPayload(_row),
    });
  }

  @override
  Widget build(BuildContext context) {
    // 앱(Android/iOS): 편집 없이 조회 전용 지도만 WebView 로 표시.
    final appKey = resolveKakaoMapAppKey();
    if (appKey.isEmpty) {
      return const Center(
        child: Text(
          'Kakao Maps 키가 없습니다.\n빌드 시 KAKAO_MAP_JAVASCRIPT_KEY 를 설정하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      );
    }

    return SalesAreaMapWebViewHost(
      key: _hostKey,
      htmlFile: kSalesAreaEditorMapHtml,
      assetPath: kSalesAreaEditorMapAsset,
      appKey: appKey,
      queryParams: const {'v': '20260615app'},
      onReady: () {
        _mapReady = true;
        _sendInitIfReady();
      },
      onMessage: (msg) {
        if (msg['op'] == 'ERROR') {
          widget.onSaveError?.call((msg['message'] ?? '').toString());
        }
      },
    );
  }
}
