/// `chk_mst` 조회·생성·수정 응답 — 백엔드 `ChkMstResponseDto` JSON 키와 동일.
///
/// 활동 체크결과 `GET /activities/{id}/checklist-results`(`ChkResultRowDto`)의 마스터 메타 필드명도 동일하다.
/// `POST`/`PUT` 본문 필드 중 겹치는 이름은 `ChkMstWritePayload`에서 이 상수를 재사용한다.
abstract final class ChkMstApiJsonKeys {
  static const String chkIdx = 'chkIdx';
  static const String brandCd = 'brandCd';
  static const String chkType = 'chkType';
  static const String chkTypeNm = 'chkTypeNm';
  static const String chkContent = 'chkContent';
  static const String baseScore = 'baseScore';
  static const String useYn = 'useYn';
  static const String displayOrder = 'displayOrder';
}
