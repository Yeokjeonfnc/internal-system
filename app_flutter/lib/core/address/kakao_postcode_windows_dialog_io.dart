import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

import 'kakao_postcode_data.dart'
    show
        KakaoPostcodeResult,
        applyKakaoPostcodeBridgeDecoded,
        kKakaoPostcodeEmbedHtml,
        kKakaoPostcodeWindowsPollPendingScript,
        unwrapKakaoPostWebMessagePayload;

/// Windows 네이티브(WebView2): `file://` 만으로는 호스트 브리지가 불안정할 수 있어
/// **가상 HTTPS 호스트 → 로컬 폴더 매핑** 후 로드한다.
///
/// 크롬에서 Flutter **웹**을 디버깅하면 문맥이 브라우저 탭이라 `chrome.webview=false` 가 정상이다.
/// 네이티브 결과 전달은 [WebviewController.webMessage] 및 `__yjKakaoPostcodePending` 폴링으로 처리한다.
const String _kWindowsKakaoPostcodeVirtualHost = 'yj.postcode.embedded';

Future<KakaoPostcodeResult?> showWindowsKakaoPostcodeDialog(
  BuildContext context,
) async {
  if (!Platform.isWindows) return null;
  if (!context.mounted) return null;

  return showDialog<KakaoPostcodeResult>(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    builder: (dialogContext) {
      final mq = MediaQuery.sizeOf(dialogContext);
      final w = (mq.width - 40).clamp(320.0, 560.0);
      final h = (mq.height * 0.88).clamp(420.0, 720.0);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: w,
          height: h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                child: Row(
                  children: [
                    Text(
                      '주소 검색',
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '닫기',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _KakaoPostcodeWindowsBody(dialogContext: dialogContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _KakaoPostcodeWindowsBody extends StatefulWidget {
  const _KakaoPostcodeWindowsBody({required this.dialogContext});

  final BuildContext dialogContext;

  @override
  State<_KakaoPostcodeWindowsBody> createState() =>
      _KakaoPostcodeWindowsBodyState();
}

class _KakaoPostcodeWindowsBodyState extends State<_KakaoPostcodeWindowsBody> {
  final WebviewController _controller = WebviewController();
  StreamSubscription<dynamic>? _webMsgSub;
  StreamSubscription<LoadingState>? _loadingProbeSub;
  Timer? _pendingPollTimer;
  var _pollBusy = false;
  Directory? _tempEmbedDir;
  var _completed = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final navigator = Navigator.of(widget.dialogContext);
    final messenger = ScaffoldMessenger.maybeOf(widget.dialogContext);

    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.white);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      debugPrint('[yj_kakao_win] WebviewController.initialize() 완료');

      /// JS → 네이티브 WebMessageReceived → Dart [WebviewController.webMessage].
      /// webview_windows 0.4.x 에는 `webMessageReceived` 프로퍼티명 없음(스트림만 제공).
      /// IsWebMessageEnabled 등 별도 노출 API 없음(웹뷰 기본값 사용).
      _webMsgSub = _controller.webMessage.listen((dynamic message) {
        debugPrint(
          '[yj_kakao_win] webMessage 수신 raw=$message (${message.runtimeType})',
        );
        if (!mounted) return;

        final early = unwrapKakaoPostWebMessagePayload(message);
        if (early is Map && early['yjProbe'] == true) {
          debugPrint('[yj_kakao_win] probe 회신 수신 — JS→Dart 통로 정상');
          return;
        }

        try {
          applyKakaoPostcodeBridgeDecoded(
            navigator,
            messenger,
            decoded: message,
            getCompleted: () => _completed,
            setCompleted: (v) => _completed = v,
          );
        } catch (e, stack) {
          debugPrint(
            'Kakao postcode WebView2 webMessage 처리 실패: $e\n$stack\nraw=$message',
          );
          messenger?.showSnackBar(
            const SnackBar(content: Text('주소 정보를 처리하지 못했습니다.')),
          );
        }
      });
      debugPrint('[yj_kakao_win] webMessage 리스너 등록 완료');

      _loadingProbeSub = _controller.loadingState.listen((state) {
        debugPrint('[yj_kakao_win] loadingState=$state');
        if (state != LoadingState.navigationCompleted) return;
        _loadingProbeSub?.cancel();
        _loadingProbeSub = null;
        unawaited(_probeChromeWebviewChannel());
      });

      _tempEmbedDir = Directory.systemTemp.createTempSync('yj_kakao_wv');
      final file = File('${_tempEmbedDir!.path}/kakao_postcode_embed.html');
      await file.writeAsString(kKakaoPostcodeEmbedHtml, flush: true);
      final folder = _tempEmbedDir!.absolute.path;
      await _controller.addVirtualHostNameMapping(
        _kWindowsKakaoPostcodeVirtualHost,
        folder,
        WebviewHostResourceAccessKind.allow,
      );
      final navUri =
          'https://$_kWindowsKakaoPostcodeVirtualHost/kakao_postcode_embed.html';
      debugPrint('[yj_kakao_win] 가상 호스트 로드 $navUri (dir=$folder)');
      await _controller.loadUrl(navUri);

      /// chrome.webview/postMessage 가 막혀 있어도 JS 가 두는 전역 pending 을 executeScript 로 읽는다.
      _startPendingPoll(navigator, messenger);
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _initError =
              e.message ?? 'WebView를 초기화하지 못했습니다. WebView2 런타임을 설치해 주세요.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = '주소 검색 창을 열 수 없습니다.\n$e';
        });
      }
    }

    if (mounted) setState(() {});
  }

  void _startPendingPoll(
    NavigatorState navigator,
    ScaffoldMessengerState? messenger,
  ) {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      unawaited(_consumePendingViaExecuteScript(navigator, messenger));
    });
  }

  Future<void> _consumePendingViaExecuteScript(
    NavigatorState navigator,
    ScaffoldMessengerState? messenger,
  ) async {
    if (!mounted ||
        !_controller.value.isInitialized ||
        _completed ||
        _pollBusy) {
      return;
    }
    _pollBusy = true;
    try {
      final dynamic raw = await _controller.executeScript(
        kKakaoPostcodeWindowsPollPendingScript,
      );
      if (raw == null || !mounted || _completed) return;

      debugPrint('[yj_kakao_win] 폴링 페이로드 raw=$raw');

      final early = unwrapKakaoPostWebMessagePayload(raw);
      if (early is Map && early['yjProbe'] == true) {
        return;
      }

      applyKakaoPostcodeBridgeDecoded(
        navigator,
        messenger,
        decoded: raw,
        getCompleted: () => _completed,
        setCompleted: (v) => _completed = v,
      );
    } catch (_) {
      // 네비게이션 중 스크립트 실패 등은 다음 주기에 재시도
    } finally {
      _pollBusy = false;
    }
  }

  /// 첫 navigation 완료 후 chrome.webview 존재 여부 + 테스트 postMessage 전송.
  Future<void> _probeChromeWebviewChannel() async {
    if (!mounted) return;
    try {
      final dynamic ok = await _controller.executeScript(r'''
(function(){
  var has = !!(window.chrome && window.chrome.webview &&
      typeof window.chrome.webview.postMessage === 'function');
  if (has) {
    try {
      window.chrome.webview.postMessage(JSON.stringify({"yjProbe":true}));
    } catch (e) {}
  }
  return has;
})()
''');
      debugPrint(
        '[yj_kakao_win] executeScript: chrome.webview.postMessage 사용 가능=$ok',
      );
    } catch (e, stack) {
      debugPrint(
        '[yj_kakao_win] chrome.webview probe executeScript 실패: $e\n$stack',
      );
    }
  }

  @override
  void dispose() {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
    _loadingProbeSub?.cancel();
    _webMsgSub?.cancel();
    final dir = _tempEmbedDir;
    _tempEmbedDir = null;
    unawaited(() async {
      try {
        if (_controller.value.isInitialized) {
          await _controller.removeVirtualHostNameMapping(
            _kWindowsKakaoPostcodeVirtualHost,
          );
        }
      } catch (_) {}
      try {
        await _controller.dispose();
      } catch (_) {}
      try {
        dir?.deleteSync(recursive: true);
      } catch (_) {}
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = _initError;
    if (err != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(err, textAlign: TextAlign.center),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Webview(_controller);
  }
}
