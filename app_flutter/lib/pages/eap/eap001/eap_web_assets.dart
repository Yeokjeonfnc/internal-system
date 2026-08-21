// 전자결재 Web iframe 자산 — 캐시 버스트·페이지 경로 단일 관리.

/// `web/eap_*.html`, `web/eap_*.js` 쿼리 `?v=` 와 Dart iframe src 에 동일하게 사용.
///
/// **주의**: 이 값은 `web/eap_html_editor.html`·`web/eap_form_fill.html` 안의
/// `<script src="...?v=">`·`<link href="...?v=">` 에도 **같은 문자열로 박혀 있다.**
/// 한쪽만 올리면 iframe 페이지는 새로 받아오는데 그 안의 JS·CSS 는 브라우저 캐시의
/// 옛것이 쓰여, 고친 내용이 반영되지 않은 채 "고쳤는데 그대로다" 가 된다.
/// 편집기 자산을 고쳤으면 **여기와 두 HTML 을 함께** 바꿀 것:
///   `cd app_flutter/web && sed -i 's/v=<옛버전>/v=<새버전>/g' *.html`
const kEapWebAssetVersion = '20260822a';

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
