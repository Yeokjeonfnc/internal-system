/// `/activities*` 응답 JSON 키 — 백엔드 `ActiveMstResponseDto`·`ActivityStatusPivotRowDto` 등과 동일.
/// 목록·현황 `GET` 쿼리 이름이 동일한 필드는 이 클래스를 재사용한다(`brandCd` 등).
abstract final class ActiveMstApiJsonKeys {
  static const String actIdx = 'actIdx';
  static const String storeIdx = 'storeIdx';
  static const String storeNm = 'storeNm';
  static const String storeCd = 'storeCd';
  static const String brandCd = 'brandCd';
  static const String brandNm = 'brandNm';
  static const String actType = 'actType';
  static const String actDt = 'actDt';
  static const String actNotes = 'actNotes';
  static const String svNm = 'svNm';
  static const String chkYn = 'chkYn';
  static const String apprStatus = 'apprStatus';
  static const String apprNotes = 'apprNotes';
  static const String createDt = 'createDt';
  static const String memoTxt = 'memoTxt';
  static const String ssvNm = 'ssvNm';
  static const String count = 'count';
  static const String userName = 'userName';
  static const String userId = 'userId';

  static const String apprAckUserIds = 'apprAckUserIds';
  static const String apprAckDateByUserId = 'apprAckDateByUserId';
  static const String apprUserIds = 'apprUserIds';
  static const String apprId = 'apprId';
  static const String svId = 'svId';
  static const String suggestions = 'suggestions';
  static const String svNotes = 'svNotes';
  static const String apprDt = 'apprDt';
  static const String svDeptNm = 'svDeptNm';
}

/// `GET /activities/list/*`·`/activities/status/*` 쿼리 파라미터 이름 — `ActController`와 동일.
/// (응답 JSON과 이름이 겹치면 `ActiveMstApiJsonKeys`를 쿼리 맵에 그대로 쓴다.)
abstract final class ActiveMstQueryParamKeys {
  static const String startDt = 'startDt';
  static const String endDt = 'endDt';
  static const String relUserId = 'relUserId';
  static const String hasSuggestions = 'hasSuggestions';
  static const String hasApprNote = 'hasApprNote';
}

/// `GET /activities/list/by-status` 필터 `apprStatus` 값 — `active_mst.appr_status` 코드.
abstract final class ActiveMstListApprStatus {
  static const String draft = 'DRAFT';
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';

  /// 방문 이력 등 복수 상태 CSV.
  static const String approvedPendingCsv = 'APPROVED,PENDING';
}

/// `GET /activities/{id}/checklist-results` 한 행(`ChkResultRowDto`)의 마스터 메타 키는
/// `core/checklist/chk_mst_api_json_keys.dart`의 `ChkMstApiJsonKeys`와 동일한다.
/// `answerVal`·`answerScore`는 `ChkResultDtlSave`와 동일 키.
