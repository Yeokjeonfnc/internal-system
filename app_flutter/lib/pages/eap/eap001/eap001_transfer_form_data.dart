// 양수도·명의변경 품의 — ERP 입력값 + 다우 content HTML 생성.

import 'package:app_flutter/pages/eap/eap001/eap001_transfer_daou_body_html.dart';

/// 다우 시스템 연동 양식 코드 — 양수도 / 명의변경 품의서
const String kEapTransferFormCode = 'yeokjeon_eap02';

class EapTransferFormData {
  EapTransferFormData({
    this.docType = '양수도 품의서',
    this.transferType = '양수도',
    this.namingFrom = '단독명의',
    this.namingTo = '단독명의',
    this.storeName = '',
    this.managerSv = '',
    this.criteria = '기준내',
    this.deposit = '',
    this.rent = '',
    this.areaSqm = '',
    this.areaPyeong = '',
    this.openDate = '',
    this.ownerOpenDate = '',
    this.operatePeriod = '',
    this.storeRemark = '',
    this.transferorName = '',
    this.transferorGender = '남',
    this.transferorBirth = '',
    this.transferorPhone = '',
    this.t2Name = '',
    this.t2Gender = '남',
    this.t2Birth = '',
    this.t2Phone = '',
    this.t3Name = '',
    this.t3Gender = '남',
    this.t3Birth = '',
    this.t3Phone = '',
    this.transferorJointRelation = '',
    this.unpaidDebt = '없음',
    this.unpaidDebtDetail = '',
    this.transferorMultiStore = '없음',
    this.transferorMultiStoreNames = '',
    this.contractDoc = '폐기',
    this.manualDoc = '폐기',
    this.transfereeName = '',
    this.transfereeGender = '남',
    this.transfereeBirth = '',
    this.transfereePhone = '',
    this.r2Name = '',
    this.r2Gender = '남',
    this.r2Birth = '',
    this.r2Phone = '',
    this.r3Name = '',
    this.r3Gender = '남',
    this.r3Birth = '',
    this.r3Phone = '',
    this.transfereeJointRelation = '',
    this.transfereeMultiStore = '없음',
    this.transfereeMultiStoreNames = '',
    this.transfereePastStore = '없음',
    this.transfereePastStoreNames = '',
    this.educationAttend = '참석',
    this.educationFee = '없음',
    this.contractGuarantee = '없음',
    this.educationSkipReason = '',
    this.partyRelation = '',
    this.transferReason = '',
    this.partyRemark = '',
    this.transferDate = '',
    this.transferRequestDate = '',
    this.currentContractPeriod = '',
    this.newContractPeriod = '',
    this.periodChange = '미변동',
    this.contractCondition = '승계',
    this.franchiseFee = '면제',
    this.newDeposit = '',
    this.newRent = '',
    this.premium = '',
    this.newAreaSqm = '',
    this.newAreaPyeong = '',
    this.investmentCost = '',
    this.paidPremium = '',
    this.royalty = '',
    this.foodstuff = '',
    this.liquor = '',
    this.signboard = '',
    this.interior = '',
    this.pos = '',
    this.contractRemark = '',
    this.salesMonth1 = '',
    this.sales1 = '',
    this.salesMonth2 = '',
    this.sales2 = '',
    this.salesMonth3 = '',
    this.sales3 = '',
    this.liq1 = '',
    this.liq1p = '',
    this.liq2 = '',
    this.liq2p = '',
    this.liq3 = '',
    this.liq3p = '',
    this.food1 = '',
    this.food1p = '',
    this.food2 = '',
    this.food2p = '',
    this.food3 = '',
    this.food3p = '',
    this.royaltyNote = '',
  });

  String docType;
  String transferType;
  String namingFrom;
  String namingTo;
  String storeName;
  String managerSv;
  String criteria;
  String deposit;
  String rent;
  String areaSqm;
  String areaPyeong;
  String openDate;
  String ownerOpenDate;
  String operatePeriod;
  String storeRemark;

  String transferorName;
  String transferorGender;
  String transferorBirth;
  String transferorPhone;
  String t2Name;
  String t2Gender;
  String t2Birth;
  String t2Phone;
  String t3Name;
  String t3Gender;
  String t3Birth;
  String t3Phone;
  String transferorJointRelation;
  String unpaidDebt;
  String unpaidDebtDetail;
  String transferorMultiStore;
  String transferorMultiStoreNames;
  String contractDoc;
  String manualDoc;

  String transfereeName;
  String transfereeGender;
  String transfereeBirth;
  String transfereePhone;
  String r2Name;
  String r2Gender;
  String r2Birth;
  String r2Phone;
  String r3Name;
  String r3Gender;
  String r3Birth;
  String r3Phone;
  String transfereeJointRelation;
  String transfereeMultiStore;
  String transfereeMultiStoreNames;
  String transfereePastStore;
  String transfereePastStoreNames;
  String educationAttend;
  String educationFee;
  String contractGuarantee;
  String educationSkipReason;
  String partyRelation;
  String transferReason;
  String partyRemark;

  String transferDate;
  String transferRequestDate;
  String currentContractPeriod;
  String newContractPeriod;
  String periodChange;
  String contractCondition;
  String franchiseFee;
  String newDeposit;
  String newRent;
  String premium;
  String newAreaSqm;
  String newAreaPyeong;
  String investmentCost;
  String paidPremium;
  String royalty;
  String foodstuff;
  String liquor;
  String signboard;
  String interior;
  String pos;
  String contractRemark;

  String salesMonth1;
  String sales1;
  String salesMonth2;
  String sales2;
  String salesMonth3;
  String sales3;
  String liq1;
  String liq1p;
  String liq2;
  String liq2p;
  String liq3;
  String liq3p;
  String food1;
  String food1p;
  String food2;
  String food2p;
  String food3;
  String food3p;
  String royaltyNote;

  /// HTML 양식 필드 id → 모델 (iframe postMessage fields).
  factory EapTransferFormData.fromHtmlFields(Map<String, String> f) {
    String g(String key) => (f[key] ?? '').trim();
    String joinRange(String a, String b) {
      final x = g(a);
      final y = g(b);
      if (x.isEmpty && y.isEmpty) return '';
      if (x.isEmpty) return y;
      if (y.isEmpty) return x;
      return '$x ~ $y';
    }

    final store = g('storeName').isNotEmpty ? g('storeName') : g('storeTitle');
    return EapTransferFormData(
      docType: g('docType').isEmpty ? '양수도 품의서' : g('docType'),
      transferType: g('transferType').isEmpty ? '양수도' : g('transferType'),
      namingFrom: g('namingFrom').isEmpty ? '단독명의' : g('namingFrom'),
      namingTo: g('namingTo').isEmpty ? '단독명의' : g('namingTo'),
      storeName: store,
      managerSv: g('managerSv'),
      criteria: g('criteria').isEmpty ? '기준내' : g('criteria'),
      deposit: g('deposit'),
      rent: g('rent'),
      areaSqm: g('areaSqm'),
      areaPyeong: g('areaPyeong'),
      openDate: g('openDate'),
      ownerOpenDate: g('ownerOpenDate'),
      operatePeriod: g('operatePeriod'),
      storeRemark: g('storeRemark'),
      transferorName: g('t1Name'),
      transferorGender: g('t1Gender').isEmpty ? '남' : g('t1Gender'),
      transferorBirth: g('t1Birth'),
      transferorPhone: g('t1Phone'),
      t2Name: g('t2Name'),
      t2Gender: g('t2Gender').isEmpty ? '남' : g('t2Gender'),
      t2Birth: g('t2Birth'),
      t2Phone: g('t2Phone'),
      t3Name: g('t3Name'),
      t3Gender: g('t3Gender').isEmpty ? '남' : g('t3Gender'),
      t3Birth: g('t3Birth'),
      t3Phone: g('t3Phone'),
      transferorJointRelation: g('tJointRelation'),
      unpaidDebt: g('unpaidDebt').isEmpty ? '없음' : g('unpaidDebt'),
      unpaidDebtDetail: g('unpaidDetail'),
      transferorMultiStore: g('tMulti').isEmpty ? '없음' : g('tMulti'),
      transferorMultiStoreNames: g('tMultiNames'),
      contractDoc: g('contractDoc').isEmpty ? '폐기' : g('contractDoc'),
      manualDoc: g('manualDoc').isEmpty ? '폐기' : g('manualDoc'),
      transfereeName: g('r1Name'),
      transfereeGender: g('r1Gender').isEmpty ? '남' : g('r1Gender'),
      transfereeBirth: g('r1Birth'),
      transfereePhone: g('r1Phone'),
      r2Name: g('r2Name'),
      r2Gender: g('r2Gender').isEmpty ? '남' : g('r2Gender'),
      r2Birth: g('r2Birth'),
      r2Phone: g('r2Phone'),
      r3Name: g('r3Name'),
      r3Gender: g('r3Gender').isEmpty ? '남' : g('r3Gender'),
      r3Birth: g('r3Birth'),
      r3Phone: g('r3Phone'),
      transfereeJointRelation: g('rJointRelation'),
      transfereeMultiStore: g('rMulti').isEmpty ? '없음' : g('rMulti'),
      transfereeMultiStoreNames: g('rMultiNames'),
      transfereePastStore: g('rPast').isEmpty ? '없음' : g('rPast'),
      transfereePastStoreNames: g('rPastNames'),
      educationAttend: g('eduAttend').isEmpty ? '참석' : g('eduAttend'),
      educationFee: g('eduFee').isEmpty ? '없음' : g('eduFee'),
      contractGuarantee:
          g('contractGuarantee').isEmpty ? '없음' : g('contractGuarantee'),
      educationSkipReason: g('eduSkip'),
      partyRelation: g('partyRelation'),
      transferReason: g('transferReason'),
      partyRemark: g('partyRemark'),
      transferDate: g('transferDate'),
      transferRequestDate: g('transferRequestDate'),
      currentContractPeriod: joinRange('curPeriodFrom', 'curPeriodTo'),
      newContractPeriod: joinRange('newPeriodFrom', 'newPeriodTo'),
      periodChange: g('periodChange').isEmpty ? '미변동' : g('periodChange'),
      contractCondition:
          g('contractCondition').isEmpty ? '승계' : g('contractCondition'),
      franchiseFee: g('franchiseFee').isEmpty ? '면제' : g('franchiseFee'),
      newDeposit: g('newDeposit'),
      newRent: g('newRent'),
      premium: g('premium'),
      newAreaSqm: g('newAreaSqm'),
      newAreaPyeong: g('newAreaPyeong'),
      investmentCost: g('investment'),
      paidPremium: g('paidPremium'),
      royalty: g('royalty'),
      foodstuff: g('foodstuff'),
      liquor: g('liquor'),
      signboard: g('signboard'),
      interior: g('interior'),
      pos: g('pos'),
      contractRemark: g('contractRemark'),
      salesMonth1: g('salesM1'),
      sales1: g('sales1'),
      salesMonth2: g('salesM2'),
      sales2: g('sales2'),
      salesMonth3: g('salesM3'),
      sales3: g('sales3'),
      liq1: g('liq1'),
      liq1p: g('liq1p'),
      liq2: g('liq2'),
      liq2p: g('liq2p'),
      liq3: g('liq3'),
      liq3p: g('liq3p'),
      food1: g('food1'),
      food1p: g('food1p'),
      food2: g('food2'),
      food2p: g('food2p'),
      food3: g('food3'),
      food3p: g('food3p'),
      royaltyNote: g('royaltyNote'),
    );
  }

  /// 할맥 {점포}점 {양수도|명의변경}의 건. ({단독|공동}→{단독|공동})
  String buildTitle() {
    final store = storeName.trim().isEmpty ? 'OOOOOOOOOO' : storeName.trim();
    return '할맥 $store점 $transferType의 건. ($namingFrom→$namingTo)';
  }

  /// 다우 appContent 본문 — Ver.7 원본과 동일 표/셀 스타일.
  String buildContentHtml() => buildDaouTransferBodyHtml(this);
}
