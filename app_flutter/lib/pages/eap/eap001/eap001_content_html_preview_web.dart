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
}) {
  return _EapContentHtmlPreviewWeb(
    htmlBody: htmlBody,
    seamless: seamless,
    readOnly: readOnly,
  );
}

class _EapContentHtmlPreviewWeb extends StatefulWidget {
  const _EapContentHtmlPreviewWeb({
    required this.htmlBody,
    this.seamless = false,
    this.readOnly = false,
  });

  final String htmlBody;
  final bool seamless;
  final bool readOnly;

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
    );
  }

  @override
  void didUpdateWidget(covariant _EapContentHtmlPreviewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlBody != widget.htmlBody ||
        oldWidget.seamless != widget.seamless ||
        oldWidget.readOnly != widget.readOnly) {
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
