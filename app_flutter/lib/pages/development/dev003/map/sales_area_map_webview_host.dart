import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:app_flutter/core/api/api_base_url_config.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_map_protocol.dart';

/// Android/iOS WebView — 번들 HTML(브리지 포함) + 카카오 등록 도메인 origin.
class SalesAreaMapWebViewHost extends StatefulWidget {
  const SalesAreaMapWebViewHost({
    super.key,
    required this.htmlFile,
    required this.assetPath,
    required this.appKey,
    this.queryParams = const {},
    required this.onMessage,
    this.onReady,
  });

  final String htmlFile;
  final String assetPath;
  final String appKey;
  final Map<String, String> queryParams;
  final void Function(Map<String, dynamic> msg) onMessage;
  final VoidCallback? onReady;

  @override
  State<SalesAreaMapWebViewHost> createState() => SalesAreaMapWebViewHostState();
}

class SalesAreaMapWebViewHostState extends State<SalesAreaMapWebViewHost> {
  WebViewController? _controller;
  bool _loading = true;
  bool _readyReceived = false;
  String? _loadHint;
  Timer? _readyWatchdog;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void dispose() {
    _readyWatchdog?.cancel();
    super.dispose();
  }

  Future<void> postPayload(Map<String, dynamic> payload) async {
    final c = _controller;
    if (c == null) return;
    final wire = '$kSalesAreaMapMsgPrefix${jsonEncode(payload)}';
    await c.runJavaScript('window.__yjSaDispatch(${jsonEncode(wire)});');
  }

  Future<WebViewController> _createController() async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF4F6F8))
      ..addJavaScriptChannel(
        'YjSalesAreaMap',
        onMessageReceived: (m) => _onRawMessage(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _armReadyWatchdog();
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            debugPrint(
              '[SalesAreaMapWebView] ${error.errorCode} ${error.description} '
              '${error.url}',
            );
            widget.onMessage({
              'op': 'ERROR',
              'message': error.description,
            });
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );
      await android.setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }

  void _armReadyWatchdog() {
    _readyWatchdog?.cancel();
    if (_readyReceived) return;
    _readyWatchdog = Timer(const Duration(seconds: 6), () {
      if (!mounted || _readyReceived) return;
      widget.onMessage({
        'op': 'ERROR',
        'message':
            '지도 준비 시간 초과. 폰 인터넷·카카오 JS 도메인(${resolveKakaoMapWebViewBaseUrl()}) 확인',
      });
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _loadAssetHtml(WebViewController controller) async {
    var html = await rootBundle.loadString(widget.assetPath);
    final key = widget.appKey.trim();
    final injectParts = <String>['window.__yjForceMinimalUi=true;'];
    if (key.isNotEmpty) {
      injectParts.add('window.YJ_KAKAO_MAP_APP_KEY=${jsonEncode(key)};');
    }
    final inject = '<script>${injectParts.join('')}</script>';
    html = html.replaceFirst('<head>', '<head>$inject');

    final base = resolveKakaoMapWebViewBaseUrl();
    final uri = Uri.parse(base).replace(
      path: '/${widget.htmlFile}',
      queryParameters: {
        'ui': 'minimal',
        'bridge': 'webview',
        ...widget.queryParams,
      },
    );
    await controller.loadHtmlString(html, baseUrl: uri.toString());
    if (mounted) {
      setState(() => _loadHint = 'origin: $uri');
    }
  }

  Future<void> _init() async {
    final controller = await _createController();
    await _loadAssetHtml(controller);

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _loading = true;
    });
  }

  void _onRawMessage(String raw) {
    if (!raw.startsWith(kSalesAreaMapMsgPrefix)) return;
    try {
      final decoded = jsonDecode(raw.substring(kSalesAreaMapMsgPrefix.length));
      if (decoded is! Map) return;
      final msg = Map<String, dynamic>.from(decoded);
      if (msg['op'] == kSalesAreaOpReady) {
        _readyReceived = true;
        _readyWatchdog?.cancel();
        if (mounted) setState(() => _loading = false);
        widget.onReady?.call();
      }
      widget.onMessage(msg);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: c),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (kDebugMode && _loadHint != null)
          Positioned(
            left: 4,
            bottom: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  _loadHint!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const String kSalesAreaSearchMapHtml = 'kakao_sales_area_map.html';
const String kSalesAreaSearchMapAsset = 'web/kakao_sales_area_map.html';
const String kSalesAreaEditorMapHtml = 'kakao_sales_area_editor.html';
const String kSalesAreaEditorMapAsset = 'web/kakao_sales_area_editor.html';
