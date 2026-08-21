// 전자결재 본문 HTML 미리보기 — Web iframe.

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:app_flutter/pages/eap/eap001/eap_iframe_bridge_web.dart';
import 'package:app_flutter/pages/eap/eap001/eap_preview_srcdoc_web.dart';

Widget buildEapContentHtmlPreview(
  String htmlBody, {
  bool seamless = false,
  bool readOnly = false,
  bool formDesignPreview = false,
}) {
  return _EapContentHtmlPreviewWeb(
    htmlBody: htmlBody,
    seamless: seamless,
    readOnly: readOnly,
    formDesignPreview: formDesignPreview,
  );
}

class _EapContentHtmlPreviewWeb extends StatefulWidget {
  const _EapContentHtmlPreviewWeb({
    required this.htmlBody,
    this.seamless = false,
    this.readOnly = false,
    this.formDesignPreview = false,
  });

  final String htmlBody;
  final bool seamless;
  final bool readOnly;
  final bool formDesignPreview;

  @override
  State<_EapContentHtmlPreviewWeb> createState() =>
      _EapContentHtmlPreviewWebState();
}

class _EapContentHtmlPreviewWebState extends State<_EapContentHtmlPreviewWeb>
    with EapIframePointerGateMixin {
  late final String _viewType;
  html.IFrameElement? _iframe;
  var _alive = true;

  @override
  html.IFrameElement? get iframeForPointerGate => _iframe;

  @override
  bool get iframeHostAlive => _alive;

  @override
  void initState() {
    super.initState();
    _viewType = registerEapIframeView('eap-preview', _createIframe());
    bindEapIframePointerGate();
  }

  html.IFrameElement _createIframe() {
    final iframe = html.IFrameElement()
      // 미리보기는 **저장된 서식 HTML 을 그대로** srcdoc 에 넣어 띄운다.
      // 샌드박스가 없으면 그 HTML 안의 <script> 가 이 앱과 같은 출처로 실행되어
      // localStorage 의 로그인 토큰까지 읽을 수 있다. 서식은 사내 사용자가 HTML
      // 소스로 직접 편집할 수 있으므로(편집기의 「소스 <>」 탭) 실제 통로가 된다.
      //
      // 'allow-scripts' 만 준다: 표 렌더링·자동계산 스크립트는 그대로 동작하지만
      // 출처가 불투명(opaque)해져 부모의 저장소·쿠키에는 접근하지 못한다.
      // 'allow-same-origin' 은 **절대 함께 주면 안 된다** — 두 값을 같이 주면
      // 샌드박스가 사실상 해제된다.
      ..setAttribute('sandbox', 'allow-scripts')
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden'
      ..style.display = 'block';
    _applySrcdoc(iframe);
    _iframe = iframe;
    return iframe;
  }

  void _applySrcdoc(html.IFrameElement iframe) {
    iframe.srcdoc = buildEapPreviewSrcdoc(
      widget.htmlBody,
      seamless: widget.seamless,
      readOnly: widget.readOnly,
      formDesignPreview: widget.formDesignPreview,
    );
  }

  @override
  void didUpdateWidget(covariant _EapContentHtmlPreviewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlBody != widget.htmlBody ||
        oldWidget.seamless != widget.seamless ||
        oldWidget.readOnly != widget.readOnly ||
        oldWidget.formDesignPreview != widget.formDesignPreview) {
      final iframe = _iframe;
      if (iframe != null) _applySrcdoc(iframe);
    }
  }

  @override
  void dispose() {
    _alive = false;
    unbindEapIframePointerGate();
    retireEapIframe(_iframe);
    _iframe = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildEapIframeView(_viewType);
  }
}
