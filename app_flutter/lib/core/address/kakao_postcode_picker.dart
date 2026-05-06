// 카카오 우편번호 서비스(https://postcode.map.daum.net) 연동.

//

// - Web: iframe(HtmlElementView) 다이얼로그 + postMessage

// - Android / iOS / macOS: webview_flutter 다이얼로그

// - Windows: webview_windows(WebView2) 다이얼로그

// - Linux: 임시 HTML 기본 브라우저 (선택 후 복사 안내)

// - 그 외: 안내 다이얼로그



import 'dart:convert';



import 'package:flutter/foundation.dart'

    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:webview_flutter/webview_flutter.dart';



import 'package:app_flutter/core/theme/app_colors.dart';

import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';

import 'package:app_flutter/core/address/kakao_postcode_data.dart';

import 'package:app_flutter/core/address/kakao_postcode_desktop_launch.dart';



export 'kakao_postcode_data.dart' show KakaoPostcodeResult;



import 'kakao_postcode_web_stub.dart'

    if (dart.library.html) 'kakao_postcode_web_html.dart' as kakao_web;



import 'kakao_postcode_windows_dialog_stub.dart'

    if (dart.library.io) 'kakao_postcode_windows_dialog_io.dart' as kakao_win;



bool _embeddedWebViewSupported() =>

    !kIsWeb &&

    (identical(defaultTargetPlatform, TargetPlatform.android) ||

        identical(defaultTargetPlatform, TargetPlatform.iOS) ||

        identical(defaultTargetPlatform, TargetPlatform.macOS));



bool _linuxBrowserFallback() =>

    !kIsWeb && identical(defaultTargetPlatform, TargetPlatform.linux);



/// 외부 앱(브라우저)으로 전환하기 전 키보드 포커스를 정리해 Windows 등에서

/// Shift 등 수정키 KeyUp/KeyDown 불일치(assert → 크래시) 가능성을 줄인다.

Future<void> _releaseKeyboardBeforeExternalLaunch() async {

  FocusManager.instance.primaryFocus?.unfocus();

  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

  await Future<void>.delayed(const Duration(milliseconds: 40));

}



Future<void> _promptOpenPostcodeInBrowser(BuildContext context) async {

  if (!context.mounted) return;

  await _releaseKeyboardBeforeExternalLaunch();

  if (!context.mounted) return;



  final open = await showDialog<bool>(

    context: context,

    builder: (dialogContext) {

      return AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        title: const Text(

          '주소 검색',

          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

        ),

        content: const Text(

          'Linux에서는 브라우저에서 우편번호 검색 창을 엽니다.\n'

          '(카카오 홈페이지 주소만으로는 “잘못된 접근”으로 열리지 않습니다.)\n\n'

          '주소를 선택하면 우편번호·주소 안내창이 뜹니다.\n'

          '내용을 복사해 앱 입력란에 붙여 넣어 주세요.',

          style: TextStyle(fontSize: 15),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(dialogContext).pop(false),

            child: Text(

              '취소',

              style: TextStyle(

                color: AppTheme.accentRed,

                fontWeight: FontWeight.w600,

              ),

            ),

          ),

          FilledButton(

            onPressed: () => Navigator.of(dialogContext).pop(true),

            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),

            child: const Text('브라우저에서 열기'),

          ),

        ],

      );

    },

  );



  if (open != true || !context.mounted) return;



  await _releaseKeyboardBeforeExternalLaunch();

  if (!context.mounted) return;



  final ok = await launchKakaoPostcodeStandaloneInBrowser();

  if (!ok && context.mounted) {

    await showAlertDialog(

      context,

      '브라우저에서 검색 페이지를 열 수 없습니다.\n'

      '앱을 최신 버전으로 실행했는지 확인하거나\n'

      '기본 브라우저 설정을 확인해 주세요.',

    );

  }

}



/// 카카오 우편번호 찾기.

Future<KakaoPostcodeResult?> showKakaoPostcodePicker(BuildContext context) async {

  if (kIsWeb) {

    if (!context.mounted) return null;

    return kakao_web.showWebKakaoPostcodeDialog(context);

  }



  if (_embeddedWebViewSupported()) {

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

                const Expanded(child: _KakaoPostcodeMobileBody()),

              ],

            ),

          ),

        );

      },

    );

  }



  if (!kIsWeb && identical(defaultTargetPlatform, TargetPlatform.windows)) {

    if (!context.mounted) return null;

    return kakao_win.showWindowsKakaoPostcodeDialog(context);

  }



  if (_linuxBrowserFallback()) {

    await _promptOpenPostcodeInBrowser(context);

    return null;

  }



  if (!context.mounted) return null;

  await showAlertDialog(

    context,

    '이 환경에서는 주소 검색을 지원하지 않습니다.\n'

    '웹·모바일·데스크톱(Windows·Linux) 빌드로 이용해 주세요.',

  );

  return null;

}



class _KakaoPostcodeMobileBody extends StatefulWidget {

  const _KakaoPostcodeMobileBody();



  @override

  State<_KakaoPostcodeMobileBody> createState() =>

      _KakaoPostcodeMobileBodyState();

}



class _KakaoPostcodeMobileBodyState extends State<_KakaoPostcodeMobileBody> {

  WebViewController? _controller;

  var _loading = true;

  var _completed = false;



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initController());

  }



  Future<void> _initController() async {

    if (!mounted) return;

    final navigator = Navigator.of(context);

    final messenger = ScaffoldMessenger.maybeOf(context);



    final controller = WebViewController()

      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ..setBackgroundColor(Colors.white)

      ..addJavaScriptChannel(

        'KakaoPostcode',

        onMessageReceived: (JavaScriptMessage message) {

          if (!mounted) return;

          try {

            final decoded = jsonDecode(message.message);

            applyKakaoPostcodeBridgeDecoded(

              navigator,

              messenger,

              decoded: decoded,

              getCompleted: () => _completed,

              setCompleted: (v) => _completed = v,

            );

          } catch (_) {

            messenger?.showSnackBar(

              const SnackBar(content: Text('주소 정보를 처리하지 못했습니다.')),

            );

          }

        },

      )

      ..setNavigationDelegate(

        NavigationDelegate(

          onPageFinished: (_) {

            if (mounted) setState(() => _loading = false);

          },

          onWebResourceError: (WebResourceError error) {

            if (!mounted) return;

            setState(() => _loading = false);

            messenger?.showSnackBar(

              SnackBar(content: Text('페이지 로드 실패: ${error.description}')),

            );

          },

        ),

      );



    await controller.loadHtmlString(

      kKakaoPostcodeEmbedHtml,

      baseUrl: 'https://postcode.map.daum.net',

    );



    if (!mounted) return;

    setState(() {

      _controller = controller;

      _loading = false;

    });

  }



  @override

  Widget build(BuildContext context) {

    final c = _controller;

    return Stack(

      children: [

        if (c != null)

          WebViewWidget(controller: c)

        else

          const Center(child: CircularProgressIndicator()),

        if (_loading && c != null)

          const Center(child: CircularProgressIndicator()),

      ],

    );

  }

}


