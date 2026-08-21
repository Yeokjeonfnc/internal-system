// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/core/map/kakao_map_app_key_io.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_search_view_options.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_geometry.dart';
import 'package:app_flutter/pages/development/dev003/dev003_search_map_model.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';

/// Kakao SDK는 Flutter Web COEP 페이지에서 CORS 차단될 수 있어
/// 별도 HTML(iframe)에서 로드한다. 데이터는 API → postMessage.
Uri salesAreaMapEmbedPageUri() {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  final uri = Uri.parse(
    origin,
  ).resolve(baseHref).resolve('kakao_sales_area_map.html');
  final params = <String, String>{'ui': 'minimal', 'v': '20260821closedzone'};
  final appKey = resolveKakaoMapAppKey(
    localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
  );
  if (appKey.isNotEmpty) {
    params['appkey'] = appKey;
  }
  return uri.replace(queryParameters: params);
}

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
  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  bool _iframeReady = false;
  bool _initSent = false;
  List<SalesAreaMapPoint>? _cachedPoints;
  String? _loadError;
  bool _geometryLoaded = false;
  bool _loadingGeometry = false;
  List<SalesAreaMapPoint>? _geometryPoints;

  @override
  void initState() {
    super.initState();
    syncKakaoMapAppKeyToLocalStorage();
    _viewType =
        'yeokjeon-sales-area-map-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _registerIframe();
    _sub = html.window.onMessage.listen(_onMessage);
    unawaited(SalesAreaApiService().prefetch());
    unawaited(_loadPoints());
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

  Future<void> _syncSalesAreaLayers() async {
    await _ensureGeometryCatalog();
    if (!mounted || !_initSent) return;
    _sendViewOptions();
  }

  void _registerIframe() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..setAttribute('credentialless', '')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..src = salesAreaMapEmbedPageUri().toString();
      _iframe = iframe;
      return iframe;
    });
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
    _postToIframe({
      'op': kSalesAreaOpUpdatePoints,
      'points': src
          .map((p) => p.toJson(includeGeometry: true))
          .toList(growable: false),
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  void filterKeyword(String keyword) {
    if (!_initSent) return;
    _postToIframe({
      'op': kSalesAreaOpFilter,
      'keyword': keyword.trim(),
    });
  }

  void searchAddress(String keyword) {
    if (!_initSent) return;
    final q = keyword.trim();
    if (q.isEmpty) return;
    _postToIframe({
      'op': kSalesAreaOpCmd,
      'cmd': kSalesAreaCmdSearchAddress,
      'keyword': q,
    });
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
        return;
      }
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
    } catch (_) {}
  }

  String _resolveAppKey() => resolveKakaoMapAppKey(
        localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
      );

  void _postToIframe(Map<String, dynamic> payload) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    win.postMessage(
      '$kSalesAreaMapMsgPrefix${jsonEncode(payload)}',
      html.window.location.origin,
    );
  }

  void _postCatalogPoints() {
    final points = _cachedPoints;
    if (points == null) return;
    _postToIframe({
      'op': kSalesAreaOpUpdatePoints,
      'points': points.map((p) => p.toMapPointJson()).toList(growable: false),
      'totalCount': points.length,
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  void _sendInitIfReady() {
    if (!_iframeReady || _initSent) return;
    final appKey = _resolveAppKey();
    if (appKey.isEmpty) {
      widget.onMapError?.call('KAKAO_MAP_KEY_EMPTY');
      return;
    }
    final points = _cachedPoints;
    _postToIframe({
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
        unawaited(_syncSalesAreaLayers());
      } else if (widget.viewOptions.showStores) {
        _sendViewOptions();
      }
    }
  }

  void _sendViewOptions() {
    if (!_initSent) return;
    _postToIframe({
      'op': kSalesAreaOpViewOptions,
      'viewOptions': widget.viewOptions.toJson(),
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '영업지역 데이터를 불러오지 못했습니다.\n$_loadError',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF52606D)),
          ),
        ),
      );
    }
    return HtmlElementView(viewType: _viewType);
  }
}
