// 전자결재 서식 본문 — 게시판 Quill 유틸을 재사용한다.

import 'package:flutter_quill/flutter_quill.dart';

import 'package:app_flutter/pages/board/bbs001/bbs001_quill.dart';

Document eapBodyToDocument(String body) => boardBodyToDocument(body);

/// 저장된 서식 본문 → 편집기용 HTML. 표가 있는 HTML을 우선한다.
String eapStoredBodyToHtml(String contentHtml, String contentDelta) {
  final html = eapFormBodyHtml(contentHtml);
  if (html.contains('<') && !boardBodyIsQuillDelta(html)) return html;
  if (contentDelta.trim().isNotEmpty) {
    return eapDocumentToPreviewHtml(eapBodyToDocument(contentDelta));
  }
  return html;
}

/// 아주 예전 저장본에만 있던 머리말을 걷어낸다.
///
/// 옛 문서 모델은 결재 정보를 `<h3>결재 정보</h3><table>…` 로, 서식 안내를
/// `<h2>…</h2><p>서식 …</p>` 로 본문 안에 넣어 두었다. 지금은 결재 정보를 화면
/// 위젯(ApprovalInfoTable)이 그리고, 본문에는 양식만 들어간다.
///
/// **중요**: 이 정리는 옛 형식일 때만 한다.
/// 예전에는 모든 서식에 무조건 적용해서, 지금 형식으로 만든 문서에 우연히
/// `결재 정보` 라는 h3 나 `서식 …` 으로 시작하는 p 가 있으면 **열기만 해도 그
/// 블록이 사라졌고, 사용자가 아무것도 안 고치고 저장만 해도 DB 에 반영**됐다.
/// 표가 중첩된 경우엔 비탐욕 매칭이 안쪽 `</table>` 에서 멈춰 닫는 태그가 남는
/// 깨진 HTML 이 되기도 했다.
///
/// 현재 편집기가 만드는 문서에는 `eap-doc-header` / `eap-widget` /
/// `data-eap-type` 같은 표식이 반드시 들어간다. 그 표식이 있으면 손대지 않는다.
String eapFormBodyHtml(String contentHtml) {
  var html = contentHtml.trim();
  if (html.isEmpty) return html;

  final isCurrentFormat =
      html.contains('eap-doc-header') ||
      html.contains('eap-widget') ||
      html.contains('data-eap-type=') ||
      html.contains('eap-doc-body');
  if (isCurrentFormat) return html;

  // 스캔 범위를 제한한다 — 닫는 태그가 없는 문서에서 역추적이 폭주해
  // UI 스레드가 멈추는 것을 막는다.
  html = html.replaceAll(
    RegExp(
      r'<h3[^>]*>\s*결재\s*정보\s*</h3>\s*<table[\s\S]{0,20000}?</table>',
      caseSensitive: false,
    ),
    '',
  );
  html = html.replaceFirst(
    RegExp(
      r'<h2[^>]*>[\s\S]{0,2000}?</h2>\s*<p[^>]*>\s*서식\s+[\s\S]{0,2000}?</p>',
      caseSensitive: false,
    ),
    '',
  );
  return html.trim();
}

String eapDocumentToDelta(Document document) => boardDocumentToBody(document);

String eapDocumentToPreviewHtml(Document document) {
  final buf = StringBuffer();
  buf.write(
    '<div style="font-family:Pretendard,Malgun Gothic,sans-serif;'
    'font-size:14px;line-height:1.65;color:#212529;">',
  );
  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is String) {
      buf.write(
        data
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('\n', '<br/>'),
      );
    }
  }
  buf.write('</div>');
  return buf.toString();
}
