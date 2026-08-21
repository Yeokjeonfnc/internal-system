// 전자결재 본문 미리보기 srcdoc HTML 조립.

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:app_flutter/pages/eap/eap001/eap_web_assets.dart';

/// [seamless] — 문서 카드 안 채움 스크롤. false — 회색 배경 + 종이 그림자.
String buildEapPreviewSrcdoc(
  String body, {
  required bool seamless,
  required bool readOnly,
  bool formDesignPreview = false,
}) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return '<!DOCTYPE html><html><body><p style="color:#888;font-family:sans-serif;">본문 없음</p></body></html>';
  }

  final layoutClass = seamless ? 'eap-preview-fill' : 'eap-preview-paper';
  final readOnlyAttr = readOnly ? ' data-readonly="1"' : '';
  final tableCss = eapWebAssetAbsolute('eap_doc_tables.css');
  final previewCss = eapWebAssetAbsolute('eap_preview.css');
  final formDesignCss = eapWebAssetAbsolute(kEapFormDesignCss);
  final tableJs = eapWebAssetAbsolute('eap_doc_tables.js');
  final previewJs = eapWebAssetAbsolute('eap_preview.js');
  final headInject =
      '<link rel="stylesheet" href="$tableCss"/>'
      '<link rel="stylesheet" href="$previewCss"/>'
      '${formDesignPreview ? '<link rel="stylesheet" href="$formDesignCss"/>' : ''}'
      '<script src="$tableJs"></script>'
      '<script src="$previewJs"></script>';
  final a4Class = formDesignPreview ? 'eap-a4 eap-form-preview' : 'eap-a4';

  if (trimmed.toLowerCase().contains('<html')) {
    var htmlDoc = trimmed;
    if (htmlDoc.toLowerCase().contains('</head>')) {
      htmlDoc = htmlDoc.replaceFirst(
        RegExp('</head>', caseSensitive: false),
        '$headInject</head>',
      );
    }
    if (htmlDoc.toLowerCase().contains('<body')) {
      htmlDoc = htmlDoc.replaceFirst(
        RegExp(r'<body(\s[^>]*)?>', caseSensitive: false),
        '<body class="$layoutClass"$readOnlyAttr>',
      );
    }
    return htmlDoc;
  }

  return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
$headInject
</head>
<body class="$layoutClass"$readOnlyAttr>
<div class="$a4Class">$trimmed</div>
</body>
</html>''';
}

/// `web/eap_*.css|js` 절대 URL (srcdoc iframe 용).
String eapWebAssetAbsolute(String file) {
  final origin = html.window.location.origin;
  var path = html.window.location.pathname ?? '/';
  if (!path.endsWith('/')) {
    final slash = path.lastIndexOf('/');
    path = slash >= 0 ? path.substring(0, slash + 1) : '/';
  }
  return '$origin$path$file?v=$kEapWebAssetVersion';
}
