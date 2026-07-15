// 전자결재 본문 HTML 미리보기 — Web iframe.

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildEapContentHtmlPreview(String htmlBody) {
  return _EapContentHtmlPreviewWeb(htmlBody: htmlBody);
}

class _EapContentHtmlPreviewWeb extends StatefulWidget {
  const _EapContentHtmlPreviewWeb({required this.htmlBody});

  final String htmlBody;

  @override
  State<_EapContentHtmlPreviewWeb> createState() =>
      _EapContentHtmlPreviewWebState();
}

class _EapContentHtmlPreviewWebState extends State<_EapContentHtmlPreviewWeb> {
  late final String _viewType;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewType =
        'eap-content-html-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc = _wrapHtml(widget.htmlBody);
    _iframe = iframe;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => iframe,
    );
  }

  @override
  void didUpdateWidget(covariant _EapContentHtmlPreviewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlBody != widget.htmlBody) {
      _iframe?.srcdoc = _wrapHtml(widget.htmlBody);
    }
  }

  static String _wrapHtml(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return '<!DOCTYPE html><html><body><p style="color:#888;font-family:sans-serif;">본문 없음</p></body></html>';
    }
    if (trimmed.toLowerCase().contains('<html')) {
      return trimmed;
    }
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<style>
  body { margin: 12px; font-family: 'Malgun Gothic', Pretendard, sans-serif; font-size: 10pt; color: #212529; }
  table { border-collapse: collapse; }
</style>
</head>
<body>$trimmed</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
