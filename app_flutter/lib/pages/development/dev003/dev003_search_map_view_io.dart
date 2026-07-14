import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_search_map_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_webview_host.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_search_view_options.dart';

class SalesAreaSearchMapFrame extends StatefulWidget {
  const SalesAreaSearchMapFrame({
    super.key,
    this.viewOptions = kSalesAreaSearchViewDefaults,
    this.onStats,
    this.onMapError,
  });

  final SalesAreaSearchViewOptions viewOptions;
  final ValueChanged<SalesAreaMapStats>? onStats;
  final ValueChanged<String>? onMapError;

  @override
  State<SalesAreaSearchMapFrame> createState() => SalesAreaSearchMapFrameState();
}

class SalesAreaSearchMapFrameState extends State<SalesAreaSearchMapFrame> {
  final _hostKey = GlobalKey<SalesAreaMapWebViewHostState>();
  bool _mapReady = false;
  bool _initSent = false;
  List<SalesAreaMapPoint>? _cachedPoints;
  String? _loadError;
  bool _geometryLoaded = false;
  bool _loadingGeometry = false;
  List<SalesAreaMapPoint>? _geometryPoints;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPoints());
    unawaited(SalesAreaApiService().prefetch());
  }

  @override
  void didUpdateWidget(covariant SalesAreaSearchMapFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewOptions != widget.viewOptions) {
      if (widget.viewOptions.showSalesAreas) {
        unawaited(_ensureGeometryCatalog().then((_) {
          if (!mounted || !_initSent) return;
          _sendViewOptions();
        }));
      } else {
        _sendViewOptions();
      }
    }
  }

  Future<void> _loadPoints() async {
    try {
      final points = await SalesAreaApiService().fetchMapPoints();
      if (!mounted) return;
      setState(() {
        _cachedPoints = points;
        _loadError = null;
      });
      if (_initSent) {
        _postCatalogPoints();
      } else {
        _sendInitIfReady();
      }
    } catch (e) {
      if (!mounted) return;
      // API 실패해도 지도(WebView)는 띄운다 — 빈 포인트로 INIT.
      setState(() {
        _cachedPoints = <SalesAreaMapPoint>[];
        _loadError = null;
      });
      widget.onMapError?.call('가맹점 데이터 로드 실패: $e');
      if (_initSent) {
        _postCatalogPoints();
      } else {
        _sendInitIfReady();
      }
    }
  }

  Future<void> _ensureGeometryCatalog() async {
    if (_loadingGeometry) return;
    if (_geometryLoaded && _geometryPoints != null) {
      if (widget.viewOptions.showSalesAreas) {
        _postGeometryUpdate();
      }
      return;
    }
    _loadingGeometry = true;
    try {
      final points = await SalesAreaApiService().fetchMapPoints(
        includeGeometry: true,
      );
      _geometryPoints = points;
      _geometryLoaded = true;
      _postGeometryUpdate(points: points);
    } catch (_) {
      _geometryLoaded = false;
    } finally {
      _loadingGeometry = false;
    }
  }

  void _postGeometryUpdate({List<SalesAreaMapPoint>? points}) {
    final src = points ?? _geometryPoints;
    if (src == null) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpUpdatePoints,
      'points': src
          .map((p) => p.toJson(includeGeometry: true))
          .toList(growable: false),
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  void filterKeyword(String keyword) {
    if (!_initSent) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpFilter,
      'keyword': keyword.trim(),
    });
  }

  void searchAddress(String keyword) {
    if (!_initSent) return;
    final q = keyword.trim();
    if (q.isEmpty) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpCmd,
      'cmd': kSalesAreaCmdSearchAddress,
      'keyword': q,
    });
  }

  void _onHostMessage(Map<String, dynamic> msg) {
    final op = msg['op'];
    if (op == kSalesAreaOpStats) {
      widget.onStats?.call(
        SalesAreaMapStats(
          total: (msg['total'] as num?)?.toInt() ?? 0,
          visible: (msg['visible'] as num?)?.toInt() ?? 0,
          vertices: (msg['vertices'] as num?)?.toInt() ?? 0,
          zoneCount: (msg['zoneCount'] as num?)?.toInt() ?? 0,
        ),
      );
      return;
    }
    if (op == 'ERROR') {
      widget.onMapError?.call((msg['message'] ?? '').toString());
    }
  }

  void _postCatalogPoints() {
    final points = _cachedPoints;
    if (points == null) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpUpdatePoints,
      'points': points.map((p) => p.toMapPointJson()).toList(growable: false),
      'totalCount': points.length,
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  void _sendInitIfReady() {
    if (!_mapReady || _initSent) return;
    final appKey = resolveKakaoMapAppKey();
    if (appKey.isEmpty) {
      widget.onMapError?.call('KAKAO_MAP_KEY_EMPTY');
      return;
    }
    final points = _cachedPoints;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpInit,
      'appKey': appKey,
      'points': points != null
          ? points.map((p) => p.toMapPointJson()).toList(growable: false)
          : const <Map<String, dynamic>>[],
      'totalCount': points?.length ?? 0,
      'viewOptions': widget.viewOptions.toJson(),
    });
    _initSent = true;
    if (points != null) {
      if (widget.viewOptions.showSalesAreas) {
        unawaited(_ensureGeometryCatalog());
      } else if (widget.viewOptions.showStores) {
        _sendViewOptions();
      }
    }
  }

  void _sendViewOptions() {
    if (!_initSent) return;
    _hostKey.currentState?.postPayload({
      'op': kSalesAreaOpViewOptions,
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final appKey = resolveKakaoMapAppKey();
    if (appKey.isEmpty) {
      return const Center(
        child: Text(
          'Kakao Maps 키가 없습니다.\n'
          '빌드: flutter build apk --dart-define-from-file=dart_defines.local.json',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF52606D)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        SalesAreaMapWebViewHost(
          key: _hostKey,
          htmlFile: kSalesAreaSearchMapHtml,
          assetPath: kSalesAreaSearchMapAsset,
          appKey: appKey,
          queryParams: const {'ui': 'minimal', 'v': '20260615rv2'},
          onReady: () {
            _mapReady = true;
            _sendInitIfReady();
          },
          onMessage: _onHostMessage,
        ),
        if (_loadError != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _loadError!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
