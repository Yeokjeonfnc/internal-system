import 'package:app_flutter/pages/eap/eap001/eap001_transfer_form_data.dart';

/// 다우 Ver.7(2025.09.04) 본문과 동일한 표·셀 인라인 스타일 조각.
/// OpenAPI content → appContent 에 넣는다 (input 없이 값만).
String buildDaouTransferBodyHtml(EapTransferFormData d) {
  final store = d.storeName.trim().isEmpty ? 'OOOOOOOOOO' : d.storeName.trim();
  return '''
<div style="font-family:malgun gothic,dotum,arial,tahoma;font-size:10pt;line-height:150%;width:710px;">
${_p9('◾ 전결 기준')}
${_p9('SV→운영팀장(결재)→재무팀장(순차합의)/점포개발팀장(순차합의)/경영지원본부장(순차합의)→운영본부장(결재)→대표이사(결재)')}
${_br()}
${_p9('◾ 명의변경 기준')}
${_p9('→ 직계존비속(조부모, 부모, 자녀, 손주), 배우자, 동업자 (교육비 및 교육 면제 *증빙서류필수)')}
${_br()}
${_p9('◾ 양수도 기준')}
${_p9('→ 명의변경 제외한 모든 제3자에 해당 (교육비 및 교육 필수 *추가출점시 or 운영팀 판단에 따라 교육비 납부 후 교육 면제 가능)')}
${_br()}${_br()}
${_pCenter('<b>할맥 ${_e(store)}점 ${_e(d.transferType)}에 대해 아래와 같이 보고 드리오니,</b>')}
${_pCenter('<b>검토 후 재가 하여 주시기 바랍니다.</b>')}
${_br()}
${_pCenter('<b>- &nbsp; 아 &nbsp;&nbsp;&nbsp; 래 &nbsp; -</b>')}
${_br()}

${_secTitle('1. 점포 개요')}
<table ${_tAttr(698)}>
${_cg(['56', '112', '57', '83', '47', '90', '115', '137'])}
<tr>
  ${_th('점포명')}${_td(store, colspan: 2)}
  ${_th('담당 SV')}${_td(d.managerSv, colspan: 2)}
  ${_th('양수도 기준 여부<br><u>*6개월 이상 운영</u>')}${_td(d.criteria)}
</tr>
<tr>
  ${_th('보증금')}${_td(d.deposit)}
  ${_th('임차료')}${_td(d.rent)}
  ${_th('면적')}${_td('${_e(d.areaSqm)}㎡<br>${_e(d.areaPyeong)}평', raw: true)}
  ${_th('점포 최초 오픈일')}${_td(d.openDate)}
</tr>
<tr>
  ${_th('특이<br>사항')}${_td(d.storeRemark, colspan: 5, left: true)}
  ${_th('현재 점주<br>(양도인) 오픈일<br>및 운영기간')}${_td('${_e(d.ownerOpenDate)}<br>${_e(d.operatePeriod)}', raw: true)}
</tr>
</table>
${_note('*임대료 부가세 별도')}
${_br()}${_br()}

${_secTitle('2. 양도양수인 사항')}
<table ${_tAttr(697)}>
${_cg(['70', '47', '107', '74', '58', '110', '74', '44', '109'])}
<tr>
  ${_th('①<br>현재<br>점주<br>(양도인)', rowspan: 4)}
  ${_th('이름')}${_td(d.transferorName)}
  ${_th('②<br>현재<br>점주<br>(양도인)<br><u>*공동명의</u>', rowspan: 4)}
  ${_th('이름')}${_td(d.t2Name)}
  ${_th('③<br>현재<br>점주<br>(양도인)<br><u>*공동명의</u>', rowspan: 4)}
  ${_th('이름')}${_td(d.t3Name)}
</tr>
<tr>
  ${_th('성별')}${_td(d.transferorGender)}
  ${_th('성별')}${_td(d.t2Gender)}
  ${_th('성별')}${_td(d.t3Gender)}
</tr>
<tr>
  ${_th('생년<br>월일')}${_td(d.transferorBirth)}
  ${_th('생년<br>월일')}${_td(d.t2Birth)}
  ${_th('생년<br>월일')}${_td(d.t3Birth)}
</tr>
<tr>
  ${_th('전화<br>번호')}${_td(d.transferorPhone)}
  ${_th('전화<br>번호')}${_td(d.t2Phone)}
  ${_th('전화<br>번호')}${_td(d.t3Phone)}
</tr>
<tr>
  ${_th('현재 점주<br>(양도인)<br>체크사항', rowspan: 4)}
  ${_th('양도인<br>공동명의시 관계<br><u>*양도인 간의 관계기재</u>', colspan: 2)}
  ${_td(d.transferorJointRelation, colspan: 6, left: true)}
</tr>
<tr>
  ${_th('본부 미회수<br>채권·채무 여부<br><u>*특이사항 기재</u>', colspan: 2)}
  ${_td(d.unpaidDebt)}
  ${_td(d.unpaidDebtDetail, colspan: 5, left: true)}
</tr>
<tr>
  ${_th('양도인 현재 할맥 다점포<br>복수 운영 여부<br><u>*명의자 or 동업자</u>', colspan: 2)}
  ${_td(d.transferorMultiStore)}
  ${_th('점포명')}
  ${_td(d.transferorMultiStoreNames, colspan: 4, left: true)}
</tr>
<tr>
  ${_th('가맹점 관련 서류<br>반환 또는 폐기 여부<br><u>*폐기시 SV 확인</u>', colspan: 2)}
  ${_th('계약서')}${_td(d.contractDoc, colspan: 2)}
  ${_th('매뉴얼')}${_td(d.manualDoc, colspan: 2)}
</tr>
<tr>
  ${_th('①<br>양수인', rowspan: 4)}
  ${_th('이름')}${_td(d.transfereeName)}
  ${_th('②<br>양수인<br><u>*공동명의</u>', rowspan: 4)}
  ${_th('이름')}${_td(d.r2Name)}
  ${_th('③<br>양수인<br><u>*공동명의</u>', rowspan: 4)}
  ${_th('이름')}${_td(d.r3Name)}
</tr>
<tr>
  ${_th('성별')}${_td(d.transfereeGender)}
  ${_th('성별')}${_td(d.r2Gender)}
  ${_th('성별')}${_td(d.r3Gender)}
</tr>
<tr>
  ${_th('생년<br>월일')}${_td(d.transfereeBirth)}
  ${_th('생년<br>월일')}${_td(d.r2Birth)}
  ${_th('생년<br>월일')}${_td(d.r3Birth)}
</tr>
<tr>
  ${_th('전화<br>번호')}${_td(d.transfereePhone)}
  ${_th('전화<br>번호')}${_td(d.r2Phone)}
  ${_th('전화<br>번호')}${_td(d.r3Phone)}
</tr>
<tr>
  ${_th('양수인<br>체크<br>사항', rowspan: 5)}
  ${_th('양수인<br>공동명의시 관계', colspan: 2)}
  ${_td(d.transfereeJointRelation, colspan: 6, left: true)}
</tr>
<tr>
  ${_th('양수인 현재 할맥 다점포<br>복수 운영 여부<br><u>*추가출점 품의서 첨부</u>', colspan: 2)}
  ${_td(d.transfereeMultiStore)}
  ${_th('점포명')}
  ${_td(d.transfereeMultiStoreNames, colspan: 4, left: true)}
</tr>
<tr>
  ${_th('양수인 과거<br>할맥 매장 운영 여부<br><u>*명의자 or 동업자</u>', colspan: 2)}
  ${_td(d.transfereePastStore)}
  ${_th('점포명')}
  ${_td(d.transfereePastStoreNames, colspan: 4, left: true)}
</tr>
<tr>
  ${_th('신규 가맹점주<br>교육 참석 여부', colspan: 2, rowspan: 2)}
  ${_td(d.educationAttend, rowspan: 2)}
  ${_th('교육비')}${_td(d.educationFee)}
  ${_th('계약이행<br>보증금', colspan: 2)}${_td(d.contractGuarantee)}
</tr>
<tr>
  ${_th('미참석<br>사유')}${_td(d.educationSkipReason, colspan: 4, left: true)}
</tr>
<tr>
  ${_th('양도인<br>양수인<br>관계')}${_td(d.partyRelation, colspan: 8, left: true)}
</tr>
<tr>
  ${_th('양도<br>사유')}${_td(d.transferReason, colspan: 8, left: true)}
</tr>
<tr>
  ${_th('특이<br>사항')}${_td(d.partyRemark, colspan: 8, left: true)}
</tr>
</table>
${_note('*교육비 부가세 별도')}
${_br()}${_br()}

${_secTitle('3. 양수도 가맹계약 사항')}
<table ${_tAttr(697)}>
${_cg(['99', '134', '114', '122', '115', '114'])}
<tr>
  ${_th('양수도<br>예정일')}${_td(d.transferDate)}
  ${_th('현재 점주 (양도인) 가맹계약기간', colspan: 2)}
  ${_td(d.currentContractPeriod, colspan: 2)}
</tr>
<tr>
  ${_th('양수도<br>요청서<br>수취일')}${_td(d.transferRequestDate)}
  ${_th('양수인 가맹계약기간', colspan: 2)}
  ${_td(d.newContractPeriod, colspan: 2)}
</tr>
<tr>
  ${_th('가맹계약기간<br>변동 여부')}${_td(d.periodChange)}
  ${_th('양수도 계약조건')}${_td(d.contractCondition)}
  ${_th('가맹금 납부 여부')}${_td(d.franchiseFee)}
</tr>
<tr>
  ${_th('*양수<br>임대차 조건', rowspan: 2)}
  ${_th('보증금')}${_td(d.newDeposit, colspan: 2, hl: true)}
  ${_th('임차료')}${_td(d.newRent, hl: true)}
</tr>
<tr>
  ${_th('권리금<br>(양수인의 지급액)')}${_td(d.premium, colspan: 2, hl: true)}
  ${_th('면적')}${_td('${_e(d.newAreaSqm)}㎡<br>${_e(d.newAreaPyeong)}평', raw: true, hl: true)}
</tr>
<tr>
  ${_th('현재 점주 (양도인)<br>출점 당시 투자비', colspan: 2, rowspan: 2)}
  ${_th('인테리어, 간판, 시설,<br>장비, 집기, 본사초도 등<br><u>*상가 보증금 및 권리금 제외</u>', colspan: 2)}
  ${_td(d.investmentCost, colspan: 2)}
</tr>
<tr>
  ${_th('권리금<br><u>*출점 당시 / 직전 점주 지급액</u>', colspan: 2)}
  ${_td(d.paidPremium, colspan: 2)}
</tr>
<tr>
  ${_th('로열티')}${_th('식자재')}${_th('주류')}${_th('간판')}${_th('인테리어')}${_th('포스기')}
</tr>
<tr>
  ${_td(d.royalty)}${_td(d.foodstuff)}${_td(d.liquor)}${_td(d.signboard)}${_td(d.interior)}${_td(d.pos)}
</tr>
<tr>
  ${_th('특이사항')}${_td(d.contractRemark, colspan: 5, left: true)}
</tr>
</table>
${_note('*임차료 부가세 별도')}
${_br()}${_br()}

${_secTitle('4. 최근 3개월 매출대비 식자재 / 주류')}
<table ${_tAttr(697)}>
${_cg(['59', '121', '91', '121', '91', '121', '91'])}
<tr>
  ${_th('구분')}
  ${_th(d.salesMonth1.isEmpty ? 'OOOO년 OO월' : d.salesMonth1, colspan: 2)}
  ${_th(d.salesMonth2.isEmpty ? 'OOOO년 OO월' : d.salesMonth2, colspan: 2)}
  ${_th(d.salesMonth3.isEmpty ? 'OOOO년 OO월' : d.salesMonth3, colspan: 2)}
</tr>
<tr>
  ${_th('매출')}
  ${_td(d.sales1, colspan: 2)}
  ${_td(d.sales2, colspan: 2)}
  ${_td(d.sales3, colspan: 2)}
</tr>
<tr>
  ${_th('주류')}
  ${_td(d.liq1)}${_td(d.liq1p, right: true)}
  ${_td(d.liq2)}${_td(d.liq2p, right: true)}
  ${_td(d.liq3)}${_td(d.liq3p, right: true)}
</tr>
<tr>
  ${_th('식자재')}
  ${_td(d.food1)}${_td(d.food1p, right: true)}
  ${_td(d.food2)}${_td(d.food2p, right: true)}
  ${_td(d.food3)}${_td(d.food3p, right: true)}
</tr>
<tr>
  ${_td(d.royaltyNote.isEmpty ? '※ 로열티 : 공급대가의 OO%' : d.royaltyNote, colspan: 7, right: true)}
</tr>
</table>
${_br()}${_br()}

${_pBlue('*담당 SV 해당 양수도 품의서 상신 즉시,')}
${_pBlue('- 리드플래닛 가맹점 정보 최신화 저장 필수 : 보증금, 권리금, 임대료, 가맹계약기간, 평수 등')}
${_pBlue('- 리드플래닛 가맹점 문서함 등록 필수(해당시) : 동업계약서, 최초 가맹계약서(공동명의날인본), 가족관계증명서 등')}
${_br()}${_br()}
${_p11('<b>※ 첨부파일</b>')}
${_p11('<b>① 양수도 요청서</b>')}
${_p11('<b>② 양수도 합의서</b>')}
${_p11('<b>③ 양수인 체크리스트</b>')}
${_p11('<b>④ 인테리어 체크리스트</b>')}
${_br()}
${_p11('<b>(해당시 추가첨부)</b>')}
${_p11('<b>① 공동명의 또는 동업관계 : 동업계약서, 최초 가맹계약서(공동명의날인본), 수익금분배증빙(6개월이상)</b>')}
${_p11('<b>② 직계존비속 : 가족관계증명서</b>')}
${_p11("<b>③ 추가출점 : 결재 득한 추가출점 품의서(아래 '관련문서 - 문서검색' 활용)</b>")}
${_br()}${_br()}
${_p11('끝.')}
</div>
''';
}

// ── helpers (Ver.7 cell look) ──────────────────────────────────────────

const _kTh =
    'border:1px solid black;background:rgb(217,217,217);text-align:center;'
    'vertical-align:middle;padding:3.6pt 7.2pt;'
    'font-family:malgun gothic,dotum,arial,tahoma;font-size:9pt;'
    'font-weight:bold;color:black;';

const _kTd =
    'border:1px solid black;background:rgb(255,255,255);text-align:center;'
    'vertical-align:middle;padding:3.6pt 7.2pt;'
    'font-family:malgun gothic,dotum,arial,tahoma;font-size:9pt;color:black;';

String _tAttr(int w) =>
    'border="0" cellpadding="0" cellspacing="0" '
    'style="border-collapse:collapse;width:${w}px;table-layout:fixed;'
    'font-family:malgun gothic,dotum,arial,tahoma;"';

String _cg(List<String> widths) =>
    '<colgroup>${widths.map((w) => '<col width="$w">').join()}</colgroup>';

String _th(String label, {int colspan = 1, int rowspan = 1}) {
  final cs = colspan > 1 ? ' colspan="$colspan"' : '';
  final rs = rowspan > 1 ? ' rowspan="$rowspan"' : '';
  return '<td$cs$rs bgcolor="#D9D9D9" style="$_kTh">$label</td>';
}

String _td(
  String? value, {
  int colspan = 1,
  int rowspan = 1,
  bool left = false,
  bool right = false,
  bool hl = false,
  bool raw = false,
}) {
  final cs = colspan > 1 ? ' colspan="$colspan"' : '';
  final rs = rowspan > 1 ? ' rowspan="$rowspan"' : '';
  final align = right
      ? 'right'
      : left
      ? 'left'
      : 'center';
  final bg = hl ? 'rgb(255,245,153)' : 'rgb(255,255,255)';
  final bgAttr = hl ? '#FFF599' : '#FFFFFF';
  final style = _kTd
      .replaceAll('text-align:center', 'text-align:$align')
      .replaceAll('background:rgb(255,255,255)', 'background:$bg');
  final body = raw ? (value ?? '') : _e(value);
  return '<td$cs$rs bgcolor="$bgAttr" style="$style">$body</td>';
}

String _e(String? value) {
  final v = value ?? '';
  return v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _p9(String text) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;"><span style="font-size:9pt;">$text</span></p>';

String _p11(String html) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;">$html</p>';

String _pCenter(String html) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;text-align:center;">$html</p>';

String _pBlue(String text) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;"><span style="color:rgb(0,0,255);font-size:10pt;'
    'font-weight:bold;">$text</span></p>';

String _secTitle(String title) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;"><b>$title</b>'
    '<span style="font-size:9pt;"> &nbsp;(단위 : 원)</span></p>';

String _note(String text) =>
    '<p style="line-height:1;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;margin:0;"><span style="font-size:9pt;"><b>$text</b></span></p>';

String _br() =>
    '<p style="line-height:1;margin:0;font-family:malgun gothic,dotum,arial,tahoma;'
    'font-size:11pt;"><br></p>';
