// 웹 전용 구현 (조건부 import). iframe / window 메시지용으로 dart:html 사용.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'kakao_postcode_data.dart';

/// iframe embed 의 `postMessage` 와 동일 (`web/kakao_postcode_embed.html` SYNC)
const String _kKakaoPostcodeWebMsgPrefix = 'yj_pc_v1|';

/// Flutter 웹 iframe SRC — `web/kakao_postcode_embed.html` (앱과 동일 출처).
/// 내용은 [kKakaoPostcodeEmbedHtml] 과 SYNC 유지.
Uri kakaoPostcodeEmbedPageUri() {
  final origin = html.window.location.origin;
  final baseHref =
      html.document.querySelector('base')?.getAttribute('href') ?? '/';
  return Uri.parse(
    origin,
  ).resolve(baseHref).resolve('kakao_postcode_embed.html');
}

Future<KakaoPostcodeResult?> showWebKakaoPostcodeDialog(
  BuildContext context,
) async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              Expanded(child: _KakaoPostcodeWebIframeBody(dialogContext)),
            ],
          ),
        ),
      );
    },
  );
}

class _KakaoPostcodeWebIframeBody extends StatefulWidget {
  const _KakaoPostcodeWebIframeBody(this.dialogContext);

  final BuildContext dialogContext;

  @override
  State<_KakaoPostcodeWebIframeBody> createState() =>
      _KakaoPostcodeWebIframeBodyState();
}

class _KakaoPostcodeWebIframeBodyState
    extends State<_KakaoPostcodeWebIframeBody> {
  late final String _viewType;
  late final String _embedSrc;
  StreamSubscription<html.MessageEvent>? _sub;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _viewType =
        'yeokjeon-kakao-postcode-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _embedSrc = kakaoPostcodeEmbedPageUri().toString();
    assert(() {
      debugPrint('[yj_kakao_web] iframe same-origin src=$_embedSrc');
      return true;
    }());
    final navigator = Navigator.of(widget.dialogContext);
    final messenger = ScaffoldMessenger.maybeOf(widget.dialogContext);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..src = _embedSrc;
      return iframe;
    });

    _sub = html.window.onMessage.listen((event) {
      if (event.origin != html.window.location.origin) {
        return;
      }
      Object? raw;
      try {
        raw = event.data;
      } catch (e) {
        debugPrint('postMessage.data 변환 실패(무시): $e');
        return;
      }
      if (raw == null) return;
      if (raw is! String) return;
      if (!raw.startsWith(_kKakaoPostcodeWebMsgPrefix)) return;
      final payload = raw.substring(_kKakaoPostcodeWebMsgPrefix.length);
      try {
        final decoded = jsonDecode(payload);
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
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
