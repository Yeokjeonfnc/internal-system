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

/// 새 문서 모델: 결재 정보는 ApprovalInfoTable, HTML은 양식 본문만.
String eapFormBodyHtml(String contentHtml) {
  var html = contentHtml.trim();
  if (html.isEmpty) return html;
  html = html.replaceAll(
    RegExp(
      r'<h3[^>]*>\s*결재\s*정보\s*</h3>\s*<table[\s\S]*?</table>',
      caseSensitive: false,
    ),
    '',
  );
  html = html.replaceFirst(
    RegExp(
      r'<h2[^>]*>[\s\S]*?</h2>\s*<p[^>]*>\s*서식\s+[\s\S]*?</p>',
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
