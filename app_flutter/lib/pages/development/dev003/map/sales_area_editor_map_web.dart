// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/core/map/kakao_map_app_key_io.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';

bool _hasValidMapAddress(String address) {
  final a = address.trim();
  if (a.isEmpty || a == '(-)' || a == '-') return false;
  return true;
}

/// 빨간 핀 — [가맹점 표시] ON 이고 물건·주소 좌표가 있을 때만 (영업지역 geometry 좌표 사용 안 함).
(double?, double?)? _franchisePrimaryPin(SalesAreaRow row) {
  if (row.storeIdx == null || row.propIdx == null) return null;
  if (!_hasValidMapAddress(row.mapAddress)) return null;
  final lat = row.latitude;
  final lng = row.longitude;
  if (lat == null || lng == null) return null;
  return (lat, lng);
}

Uri salesAreaEditorEmbedPageUri() {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  final uri = Uri.parse(
    origin,
  ).resolve(baseHref).resolve('kakao_sales_area_editor.html');
  final params = <String, String>{};
  final appKey = resolveKakaoMapAppKey(
    localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
  );
  if (appKey.isNotEmpty) {
    params['appkey'] = appKey;
  }
  // HTML 변경 시 캐시 무효화 (Flutter Web iframe).
  params['v'] = '20260608zonegeom';
  return uri.replace(queryParameters: params);
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
  final SalesAreaRow? initialDetail;

  @override
  State<SalesAreaEditorMapFrame> createState() =>
      SalesAreaEditorMapFrameState();
}

class SalesAreaEditorMapFrameState extends State<SalesAreaEditorMapFrame> {
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  bool _iframeReady = false;
  bool _initSent = false;
  SalesAreaRow? _detail;
  bool _saving = false;
  List<SalesAreaMapPoint>? _mapPoints;
  List<SalesAreaMapPoint>? _mapPointsWithGeometry;
  Future<void>? _geometryCatalogFuture;
  ({double swLat, double swLng, double neLat, double neLng})? _mapBounds;
  double? _searchCenterLat;
  double? _searchCenterLng;
  Timer? _boundsDebounce;
  DateTime? _lastBoundsViewOptionsAt;

  @override
  void initState() {
    super.initState();
    syncKakaoMapAppKeyToLocalStorage();
    _viewType =
        'yeokjeon-sales-area-editor-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..setAttribute('credentialless', '')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..src = salesAreaEditorEmbedPageUri().toString();
      _iframe = iframe;
      return iframe;
    });

    _sub = html.window.onMessage.listen(_onMessage);
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
  void dispose() {
    _boundsDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SalesAreaEditorMapFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  bool get _canOpenMap => true;

  SalesAreaRow get _row => _detail ?? widget.row;

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

  /// iframe INIT 이후 상세(geometry·좌표)가 도착하면 지도에 반영.
  void _syncDetailToMap(SalesAreaRow d, {bool fitViewport = false}) {
    if (!_initSent || !_iframeReady) return;
    final geom = d.geometry;
    if (geom != null && (geom.isValidPolygon || geom.isValidCircle)) {
      _postToIframe({
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
      if (mounted) {
        _sendViewOptions();
      }
    } catch (_) {
      // 근처 가맹점·영업지역 없이 상세만 표시
    }
  }

  Future<void> _ensureGeometryCatalog() async {
    _geometryCatalogFuture ??= _loadGeometryCatalog();
    await _geometryCatalogFuture;
    if (mounted && _initSent) {
      _sendViewOptions();
    }
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

  Future<void> _refreshMapCatalogAfterSave(SalesAreaRow saved) async {
    SalesAreaApiService.invalidateMapPointsCache();
    _mapPoints = null;
    _mapPointsWithGeometry = null;
    _geometryCatalogFuture = null;
    await _loadMapCatalog();
    await _ensureGeometryCatalog();
    if (!mounted || !_initSent) return;
    final geom = saved.geometry;
    if (geom != null) {
      _postToIframe({
        'op': kSalesAreaOpUpdateGeometry,
        'zoneIdx': saved.zoneIdx,
        'zoneNm': saved.salesAreaName.isNotEmpty
            ? saved.salesAreaName
            : widget.zoneNameController.text.trim(),
        'geometryType': saved.geometryType,
        'geometryData': geom.toJson(),
        'lat': saved.latitude,
        'lng': saved.longitude,
        'fitViewport': false,
      });
    }
    _sendViewOptions();
  }

  Map<String, dynamic> _viewLayerPayload(SalesAreaRow d) {
    final lat = _searchCenterLat ?? d.latitude;
    final lng = _searchCenterLng ?? d.longitude;
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
      final stores = _mapBounds != null
          ? SalesAreaEditorMapMath.storesInBounds(
              all: _mapPoints!,
              swLat: _mapBounds!.swLat,
              swLng: _mapBounds!.swLng,
              neLat: _mapBounds!.neLat,
              neLng: _mapBounds!.neLng,
              excludeStoreIdx: d.storeIdx,
            )
          : SalesAreaEditorMapMath.nearbyStores(
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
      if (_mapPointsWithGeometry != null) {
        if (_mapBounds != null) {
          payload['nearbyZones'] = SalesAreaEditorMapMath.zonesInBoundsJson(
            all: _mapPointsWithGeometry!,
            swLat: _mapBounds!.swLat,
            swLng: _mapBounds!.swLng,
            neLat: _mapBounds!.neLat,
            neLng: _mapBounds!.neLng,
            excludeZoneIdx: d.zoneIdx,
          );
        } else if (lat != null && lng != null) {
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
      } else {
        payload['nearbyZones'] = const [];
      }
    }

    return payload;
  }

  void sendCommand(String cmd) {
    if (widget.readOnly || !_initSent) return;
    final d = _row;
    final geom = d.geometry;
    _postToIframe({
      'op': kSalesAreaOpCmd,
      'cmd': cmd,
      'zoneNm': widget.zoneNameController.text.trim(),
      if (d.geometryType != null && d.geometryType!.isNotEmpty)
        'geometryType': d.geometryType,
      if (geom != null) 'geometryData': geom.toJson(),
    });
  }

  /// Web: HtmlElementView(iframe)가 형제 Flutter 위젯 클릭을 가로챌 때 사용.
  void setMapPointerEvents(bool enabled) {
    final iframe = _iframe;
    if (iframe == null) return;
    iframe.style.pointerEvents = enabled ? 'auto' : 'none';
  }

  void searchAddress(String keyword) {
    if (widget.readOnly || !_initSent) return;
    final q = keyword.trim();
    if (q.isEmpty) return;
    _postToIframe({
      'op': kSalesAreaOpCmd,
      'cmd': kSalesAreaCmdSearchAddress,
      'keyword': q,
    });
  }

  void _postToIframe(Map<String, dynamic> payload) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    win.postMessage(
      '$kSalesAreaMapMsgPrefix${jsonEncode(payload)}',
      html.window.location.origin,
    );
  }

  void _onMessage(html.MessageEvent event) {
    if (event.origin != html.window.location.origin) return;
    final raw = event.data;
    if (raw is! String || !raw.startsWith(kSalesAreaMapMsgPrefix)) return;
    try {
      final msg = jsonDecode(raw.substring(kSalesAreaMapMsgPrefix.length));
      if (msg is! Map) return;
      final op = msg['op'];
      if (op == kSalesAreaOpReady) {
        _iframeReady = true;
        _sendInitIfReady();
      } else if (op == kSalesAreaOpSave) {
        unawaited(_handleSaveFromMap(msg));
      } else if (op == kSalesAreaOpAddressSelected) {
        final resolved = (msg['address'] ?? '').toString().trim();
        final lat = (msg['lat'] as num?)?.toDouble();
        final lng = (msg['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _searchCenterLat = lat;
          _searchCenterLng = lng;
          _mapBounds = null;
          _sendViewOptions();
        }
        if (resolved.isNotEmpty) {
          widget.onAddressResolved?.call(resolved);
        }
      } else if (op == kSalesAreaOpMapBounds) {
        final swLat = (msg['swLat'] as num?)?.toDouble();
        final swLng = (msg['swLng'] as num?)?.toDouble();
        final neLat = (msg['neLat'] as num?)?.toDouble();
        final neLng = (msg['neLng'] as num?)?.toDouble();
        if (swLat != null && swLng != null && neLat != null && neLng != null) {
          _mapBounds = (swLat: swLat, swLng: swLng, neLat: neLat, neLng: neLng);
          _scheduleBoundsViewOptions();
        }
      } else if (op == kSalesAreaOpGeometryChanged) {
        final geometryRaw = msg['geometryData'];
        final geometryType = (msg['geometryType'] ?? '').toString();
        if (geometryRaw is Map) {
          final geometry = SalesAreaGeometry.fromJson(
            Map<String, dynamic>.from(geometryRaw),
          );
          final prev = _detail ?? widget.row;
          setState(() {
            _detail = prev.copyWith(
              geometryType: geometryType.isNotEmpty
                  ? geometryType
                  : geometry.type,
              geometry: geometry,
            );
          });
        }
      } else if (op == 'ERROR') {
        widget.onSaveError?.call((msg['message'] ?? '').toString());
      }
    } catch (e) {
      widget.onSaveError?.call('지도 응답 처리 실패: $e');
    }
  }

  void _scheduleBoundsViewOptions() {
    if (!widget.viewOptions.showStores && !widget.viewOptions.showSalesAreas) {
      return;
    }
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || !_initSent) return;
      final now = DateTime.now();
      final last = _lastBoundsViewOptionsAt;
      if (last != null &&
          now.difference(last) < const Duration(milliseconds: 600)) {
        return;
      }
      _lastBoundsViewOptionsAt = now;
      if (widget.viewOptions.showSalesAreas) {
        unawaited(_ensureGeometryCatalog());
      } else {
        _sendViewOptions();
      }
    });
  }

  void _sendInitIfReady() {
    if (!_iframeReady || !_canOpenMap || _initSent) return;
    final appKey = _resolveAppKey();
    if (appKey.isEmpty) {
      widget.onSaveError?.call('KAKAO_MAP_KEY_EMPTY');
      return;
    }
    final d = _row;
    final zoneNm = widget.zoneNameController.text.trim().isNotEmpty
        ? widget.zoneNameController.text.trim()
        : (d.salesAreaName.isNotEmpty ? d.salesAreaName : d.storeName);

    _postToIframe({
      'op': kSalesAreaOpInit,
      'readOnly': widget.readOnly,
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
    if (!_initSent || !_iframeReady) return;
    _postToIframe({'op': kSalesAreaOpSetReadOnly, 'readOnly': widget.readOnly});
  }

  void _sendViewOptions() {
    if (!_initSent || !_iframeReady) return;
    _postToIframe({'op': kSalesAreaOpViewOptions, ..._viewLayerPayload(_row)});
  }

  String _resolveAppKey() => resolveKakaoMapAppKey(
    localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
  );

  Future<void> _handleSaveFromMap(Map<dynamic, dynamic> msg) async {
    if (widget.readOnly || _saving) return;

    final zoneNm = widget.zoneNameController.text.trim();
    if (zoneNm.isEmpty) {
      widget.onSaveError?.call('영업지역명을 입력하세요.');
      return;
    }

    final geometryType = (msg['geometryType'] ?? '').toString();
    // 저장 클릭 시 iframe이 flush한 geometry 우선 (드래그 반영). _detail은 초기 로드값이라 stale.
    SalesAreaGeometry? geometry;
    final geometryRaw = msg['geometryData'];
    if (geometryRaw is Map) {
      final parsed = SalesAreaGeometry.fromJson(
        Map<String, dynamic>.from(geometryRaw),
      );
      if (parsed.isValidPolygon || parsed.isValidCircle) {
        geometry = parsed;
      }
    }
    final syncedRow = _detail ?? widget.row;
    if (geometry == null) {
      final synced = syncedRow.geometry;
      if (synced != null &&
          (synced.isValidPolygon || synced.isValidCircle)) {
        geometry = synced;
      }
    }
    if (geometry == null) {
      widget.onSaveError?.call('지도에서 영역을 그려 주세요.');
      return;
    }

    final d = _row;
    final propIdx = d.propIdx ?? widget.row.propIdx;
    final storeIdx = d.storeIdx ?? widget.row.storeIdx;
    final zoneIdx = d.zoneIdx ?? widget.row.zoneIdx;
    final brandCd = _effectiveBrandCd(d);
    if (brandCd.isEmpty) {
      widget.onSaveError?.call('브랜드를 선택하세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await SalesAreaApiService().save(
        zoneIdx: zoneIdx,
        propIdx: propIdx,
        storeIdx: storeIdx,
        zoneNm: zoneNm,
        geometryType: geometryType.isNotEmpty ? geometryType : geometry.type,
        geometryData: geometry,
        brandCd: brandCd,
      );
      if (!mounted) return;
      setState(() => _detail = saved);
      widget.onDetailLoaded?.call(saved);
      await _refreshMapCatalogAfterSave(saved);
      widget.onSaved();
    } catch (e) {
      widget.onSaveError?.call('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void requestSaveFromMap() => sendCommand(kSalesAreaCmdSave);

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
