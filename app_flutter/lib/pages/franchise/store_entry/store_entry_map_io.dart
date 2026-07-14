import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:app_flutter/core/api/api_base_url_config.dart';
import 'package:app_flutter/core/map/kakao_map_app_key.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

const String kStoreEntryMapMsgPrefix = 'yj_se_v1|';

class StoreEntryMapFrame extends StatefulWidget {
  const StoreEntryMapFrame({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onAddressResolved,
  });

  final double latitude;
  final double longitude;
  final ValueChanged<String>? onAddressResolved;

  @override
  State<StoreEntryMapFrame> createState() => StoreEntryMapFrameState();
}

class StoreEntryMapFrameState extends State<StoreEntryMapFrame> {
  WebViewController? _controller;
  bool _ready = false;
  bool _mapError = false;
  String? _mapErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void didUpdateWidget(covariant StoreEntryMapFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _sendCenter();
    }
  }

  Future<void> _init() async {
    try {
      final controller = await _createController();
      await _loadHtml(controller);
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e, st) {
      debugPrint('[StoreEntryMap] init failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _mapError = true;
        _mapErrorMessage = '지도를 표시할 수 없습니다.';
      });
    }
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
      ..setBackgroundColor(const Color(0xFFE8EAED))
      ..addJavaScriptChannel(
        'YjStoreEntryMap',
        onMessageReceived: (m) => _onMessage(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint(
              '[StoreEntryMap] ${error.errorCode} ${error.description} '
              '${error.url}',
            );
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

  Future<void> _loadHtml(WebViewController controller) async {
    var html = await rootBundle.loadString('web/kakao_store_entry_map.html');
    final key = resolveKakaoMapAppKey();
    final inject =
        '<script>window.__yjForceMinimalUi=true;window.YJ_KAKAO_MAP_APP_KEY=${jsonEncode(key)};</script>';
    html = html.replaceFirst('<head>', '<head>$inject');

    final base = resolveKakaoMapWebViewBaseUrl();
    final uri = Uri.parse(base).replace(
      path: '/kakao_store_entry_map.html',
      queryParameters: const {'ui': 'minimal', 'bridge': 'webview'},
    );
    await controller.loadHtmlString(html, baseUrl: uri.toString());
  }

  void _onMessage(String raw) {
    if (!raw.startsWith(kStoreEntryMapMsgPrefix)) return;
    try {
      final msg = jsonDecode(raw.substring(kStoreEntryMapMsgPrefix.length));
      if (msg is! Map) return;
      final op = msg['op'];
      if (op == 'READY') {
        _ready = true;
        _sendInit();
      }
      if (op == 'LOCATION') {
        final address = (msg['address'] ?? '').toString();
        if (address.isNotEmpty) {
          widget.onAddressResolved?.call(address);
        }
      }
    } catch (_) {}
  }

  void _sendInit() {
    final key = resolveKakaoMapAppKey();
    _post({
      'op': 'INIT',
      'appKey': key,
      'lat': widget.latitude,
      'lng': widget.longitude,
    });
  }

  void _sendCenter() {
    if (!_ready) return;
    _post({
      'op': 'SET_CENTER',
      'lat': widget.latitude,
      'lng': widget.longitude,
    });
  }

  Future<void> _post(Map<String, dynamic> payload) async {
    final c = _controller;
    if (c == null) return;
    final wire = '$kStoreEntryMapMsgPrefix${jsonEncode(payload)}';
    await c.runJavaScript('window.__yjSeDispatch(${jsonEncode(wire)});');
  }

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return ColoredBox(
        color: const Color(0xFFE8EAED),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _mapErrorMessage ?? '지도를 표시할 수 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: FormStylePalette.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return const ColoredBox(
        color: Color(0xFFE8EAED),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return WebViewWidget(controller: c);
  }
}
