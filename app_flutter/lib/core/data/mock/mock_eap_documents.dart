// 다우오피스 전자결재 연동 — 개발·UI용 샘플 문서.

import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

/// 연동 API 연결 전 UI 확인용 목업.
abstract final class MockEapDocuments {
  static final List<EapDocument> all = [
    EapDocument(
      docId: '1001',
      docNum: '역전-2026-0042',
      draftDate: DateTime(2026, 7, 11),
      formName: '품의 기본',
      title: '2026년 3분기 마케팅 비용 품의',
      status: EapDocStatus.inProgress,
      drafterName: '김영업',
      contentHtml:
          '1. 목적\n2026년 3분기 가맹점 프로모션 및 SNS 마케팅 비용 집행을 위한 품의입니다.\n\n'
          '2. 금액\n총 12,500,000원 (VAT 별도)\n\n'
          '3. 집행 일정\n2026-07-15 ~ 2026-09-30',
      attachmentCount: 1,
      urgent: false,
    ),
    EapDocument(
      docId: '1002',
      docNum: '역전-2026-0038',
      draftDate: DateTime(2026, 7, 9),
      formName: '지출결의서',
      title: '강남점 인테리어 보수 공사',
      status: EapDocStatus.inProgress,
      drafterName: '박점장',
      contentHtml:
          '강남역 2호점 냉난방 배관 누수로 인한 보수 공사 지출 결의입니다.\n'
          '업체: (주)역전시공 / 견적 3,800,000원',
      attachmentCount: 2,
      urgent: true,
    ),
    EapDocument(
      docId: '1003',
      docNum: '역전-2026-0031',
      draftDate: DateTime(2026, 7, 7),
      formName: '휴가신청서',
      title: '하계 휴가 신청 (김민수)',
      status: EapDocStatus.complete,
      drafterName: '김민수',
      contentHtml: '휴가 기간: 2026-08-04 ~ 2026-08-08 (5일)\n사유: 하계 연차',
      attachmentCount: 0,
      urgent: false,
    ),
    EapDocument(
      docId: '1004',
      docNum: '역전-2026-0028',
      draftDate: DateTime(2026, 7, 4),
      formName: '재직증명서',
      title: '재직증명서 발급 요청',
      status: EapDocStatus.complete,
      drafterName: '이인사',
      contentHtml: '용도: 은행 대출 제출\n발급 부수: 1부',
      attachmentCount: 0,
      urgent: false,
    ),
    EapDocument(
      docId: '1005',
      docNum: '역전-2026-0025',
      draftDate: DateTime(2026, 7, 2),
      formName: '품의 기본',
      title: '신규 POS 단말기 교체',
      status: EapDocStatus.complete,
      drafterName: '최IT',
      contentHtml: '노후 POS 15대 교체 — 단가 420,000원 × 15대',
      attachmentCount: 1,
      urgent: false,
    ),
    EapDocument(
      docId: '1006',
      docNum: '역전-2026-0019',
      draftDate: DateTime(2026, 6, 28),
      formName: '지출결의서',
      title: '본사 교육장 임차료',
      status: EapDocStatus.returned,
      drafterName: '정총무',
      contentHtml: '반려 사유: 임차 계약서 사본 미첨부. 재상신 요망.',
      attachmentCount: 0,
      urgent: false,
    ),
    EapDocument(
      docId: '1007',
      docNum: '',
      draftDate: DateTime(2026, 7, 13),
      formName: '품의 기본',
      title: '가맹점 현장 점검 결과 보고 (임시)',
      status: EapDocStatus.tempSave,
      drafterName: '홍SV',
      contentHtml: '임시 저장 — 점검 결과 입력 중',
      attachmentCount: 0,
      urgent: false,
    ),
  ];

  static EapDocument? find(String docId) {
    for (final doc in all) {
      if (doc.docId == docId) return doc;
    }
    return null;
  }

  static List<EapDocument> pendingForMe() => [];

  static List<EapDocument> inProgress() =>
      all.where((d) => d.status == EapDocStatus.inProgress).toList();

  static List<EapDocument> completed() =>
      all.where((d) => d.status == EapDocStatus.complete).toList();

  static List<EapDocument> drafted() =>
      all.where((d) => d.status != EapDocStatus.tempSave).toList();

  static List<EapDocument> tempSaved() =>
      all.where((d) => d.status == EapDocStatus.tempSave).toList();

  static List<EapDocument> returned() =>
      all.where((d) => d.status == EapDocStatus.returned).toList();
}
