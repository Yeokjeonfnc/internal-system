/// 백엔드 `ActController` 활동 베이스와 go_router 활동 루트가 동일한 문자열(`/activities`).
abstract final class ActiveMstApiPaths {
  static const String root = '/activities';

  /// `GET` 목록 — 레거시는 [root] 단일 쿼리; 신규는 아래 `list/*`.
  static const String listAll = '$root/list/all';
  static const String listByStore = '$root/list/by-store';
  /// 가맹점 지시사항 다이얼로그 — APPROVED + appr_notes + store_idx.
  static const String listByStoreApprNote = '$root/list/by-store-appr-note';
  static const String listByApprNote = '$root/list/by-appr-note';
  /// 활동관리결재 > 지시사항 — `notif_mst` 조인·결재선 포함.
  static const String listByMemoNotifForApprover = '$root/list/by-memo-notif';
  static const String listBySuggestions = '$root/list/by-suggestions';
  static const String listByCheck = '$root/list/by-check';
  static const String listByStatus = '$root/list/by-status';

  static String attachments(int actIdx) => '$root/$actIdx/attachments';

  static String attachmentDownload(int actIdx, int actAttIdx) =>
      '$root/$actIdx/attachments/$actAttIdx/download';

  static String signature(int actIdx) => '$root/$actIdx/signature';
}
