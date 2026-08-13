// 전자결재 미리보기용 — 다우 슬림 양식 셸 + 저장된 본문.

String buildEapFormPreviewHtml({
  required String formCode,
  required String title,
  required String contentHtml,
  required String drafterName,
  required String draftDateLabel,
  String draftDept = '',
  String docNum = '',
}) {
  final code = formCode.trim().toLowerCase();
  if (code == 'yeokjeon_eap01' || code.contains('eap01')) {
    return _buildEap01Shell(
      title: title,
      bodyHtml: _extractBodyInner(contentHtml),
      drafterName: drafterName.isEmpty ? '-' : drafterName,
      draftDept: draftDept.isEmpty ? '-' : draftDept,
      draftDateLabel: draftDateLabel.isEmpty ? '-' : draftDateLabel,
      docNum: docNum.isEmpty ? '(기안 후 부여)' : docNum,
    );
  }
  // 양수도 등: 저장된 표 HTML 그대로 (셸은 다우 양식 쪽)
  return contentHtml.trim();
}

String _extractBodyInner(String html) {
  final trimmed = html.trim();
  if (trimmed.isEmpty) return '<p style="color:#999;">(본문 없음)</p>';
  // 이미 전체 문서면 본문만 쓰기 어려우니 그대로
  if (trimmed.toLowerCase().contains('data-id="appcontent"') ||
      trimmed.contains('업 무 기 안')) {
    return trimmed;
  }
  return trimmed;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _buildEap01Shell({
  required String title,
  required String bodyHtml,
  required String drafterName,
  required String draftDept,
  required String draftDateLabel,
  required String docNum,
}) {
  return '''
<div style="font-family:'Malgun Gothic','맑은 고딕',malgun gothic,dotum,sans-serif;font-size:10pt;color:#000;max-width:800px;margin:0 auto;">
<table style="width:800px;border-collapse:collapse;border:0;margin-top:1px;">
  <colgroup><col width="310"/><col width="490"/></colgroup>
  <tr>
    <td colspan="2" style="text-align:center;font-size:36px;font-weight:bold;height:90px;vertical-align:middle;border:0;">업 무 기 안</td>
  </tr>
  <tr>
    <td style="vertical-align:top;border:0;padding:0;">
      <table style="border-collapse:collapse;border:1px solid #000;">
        <colgroup><col width="90"/><col width="220"/></colgroup>
        <tr>
          <td style="background:#ddd;border:1px solid #000;padding:5px;text-align:center;font-weight:bold;font-size:12px;">기안자</td>
          <td style="border:1px solid #000;padding:5px;font-size:12px;">${_esc(drafterName)}</td>
        </tr>
        <tr>
          <td style="background:#ddd;border:1px solid #000;padding:5px;text-align:center;font-weight:bold;font-size:12px;">소속</td>
          <td style="border:1px solid #000;padding:5px;font-size:12px;">${_esc(draftDept)}</td>
        </tr>
        <tr>
          <td style="background:#ddd;border:1px solid #000;padding:5px;text-align:center;font-weight:bold;font-size:12px;">기안일</td>
          <td style="border:1px solid #000;padding:5px;font-size:12px;">${_esc(draftDateLabel)}</td>
        </tr>
        <tr>
          <td style="background:#ddd;border:1px solid #000;padding:5px;text-align:center;font-weight:bold;font-size:12px;">문서번호</td>
          <td style="border:1px solid #000;padding:5px;font-size:12px;">${_esc(docNum)}</td>
        </tr>
      </table>
    </td>
    <td style="vertical-align:top;text-align:right;border:0;padding:0;">
      ${_signGroup('결재', 5)}
      <div style="margin-top:6px;">${_signGroup('합의', 1)}</div>
    </td>
  </tr>
</table>
<table style="width:800px;border-collapse:collapse;border:0;margin-top:10px;">
  <colgroup><col width="120"/><col width="680"/></colgroup>
  <tr>
    <td style="background:#ddd;border:1px solid #000;padding:5px;text-align:center;font-weight:bold;font-size:14px;height:25px;">제목</td>
    <td style="border:1px solid #000;padding:5px;font-size:14px;">${_esc(title)}</td>
  </tr>
  <tr>
    <td colspan="2" style="border:1px solid #000;padding:5px;height:350px;vertical-align:top;">
      <div style="width:100%;min-height:300px;border:1px dashed #bbb;padding:8px;font-size:14px;line-height:1.6;">
        $bodyHtml
      </div>
    </td>
  </tr>
</table>
</div>
''';
}

String _signGroup(String label, int count) {
  final boxes = StringBuffer();
  for (var i = 0; i < count; i++) {
    boxes.write('''
<span style="display:inline-block;border:1px solid #000;width:56px;vertical-align:top;margin-left:1px;text-align:center;">
  <div style="border-bottom:1px solid #000;height:22px;font-size:9pt;">&nbsp;</div>
  <div style="border-bottom:1px solid #000;height:48px;">&nbsp;</div>
  <div style="height:22px;font-size:9pt;">&nbsp;</div>
</span>''');
  }
  return '''
<span style="display:inline-block;text-align:left;vertical-align:top;">
  <span style="display:inline-block;writing-mode:vertical-rl;border:1px solid #000;padding:8px 4px;font-weight:bold;font-size:12px;margin-right:2px;vertical-align:top;height:${count > 1 ? 92 : 70}px;">$label</span>
  $boxes
</span>''';
}
