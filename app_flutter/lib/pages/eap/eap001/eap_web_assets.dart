// 전자결재 Web iframe 자산 — 캐시 버스트·페이지 경로 단일 관리.

/// `web/eap_*.html`, `web/eap_*.js` 쿼리 `?v=` 와 Dart iframe src 에 동일하게 사용.
const kEapWebAssetVersion = '20260821zc';

const kEapHtmlEditorPage = 'eap_html_editor.html';
const kEapFormFillPage = 'eap_form_fill.html';
const kEapPreviewCss = 'eap_preview.css';
const kEapPreviewJs = 'eap_preview.js';
const kEapFormDesignCss = 'eap_form_design.css';
const kEapHtmlEditorCss = 'eap_html_editor.css';
const kEapHtmlEditorJs = 'eap_html_editor.js';

String eapWebAssetUrl(String page, {String? mode}) {
  final base = '$page?v=$kEapWebAssetVersion';
  if (mode == null || mode.isEmpty) return base;
  return '$base&mode=${Uri.encodeQueryComponent(mode)}';
}
