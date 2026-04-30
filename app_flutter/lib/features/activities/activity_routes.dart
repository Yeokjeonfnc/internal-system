// 활동관리 메뉴 경로·배너 제목 (짧은 path, 한글 제목).
//
// 루트 문자열은 [AppRoutes.activities] 와 동일하게 유지한다.

/// [AppRoutes.activities] 와 동일.
const String kActivitiesRoot = '/activities';

/// `/activities` 이하 전체 경로.
abstract final class ActivityRoutes {
  static const String _b = kActivitiesRoot;

  static String get hub => _b;

  /// 사이드바 3분할(개발관리와 동일 패턴).
  static String get groupStatus => '$_b/group/status';
  static String get groupManage => '$_b/group/manage';
  static String get groupApproval => '$_b/group/approval';

  static String get statusByAssignee => '$_b/status/by-assignee';
  static String get statusByStore => '$_b/status/by-store';
  static String get drafts => '$_b/drafts';
  static String draftDetail(int actIdx) => '$_b/drafts/$actIdx';
  static String get manage => '$_b/manage';
  static String get manageRegister => '$_b/manage/register';
  static String manageDetail(int actIdx) => '$_b/manage/$actIdx';
  static String get instructions => '$_b/instructions';
  static String get checklist => '$_b/checklist';
  static String get approvalAll => '$_b/approval/all';
  static String get approvalPending => '$_b/approval/pending';
  static String get approvalActive => '$_b/approval/active';
  static String get approvalInstructions => '$_b/approval/instructions';
  static String get approvalSuggestions => '$_b/approval/suggestions';
  static String get approvalChecklist => '$_b/approval/checklist';
  static String get approvalChecklistStats => '$_b/approval/checklist-stats';
}

/// [ActivityApprovalManagementView] — 경로 → 탭(0=전체 … 4=체크리스트, 미일치 0).
int activityApprovalInitialTabForPath(String path) {
  if (path == ActivityRoutes.approvalAll) return 0;
  if (path == ActivityRoutes.approvalPending) return 1;
  if (path == ActivityRoutes.approvalActive) return 2;
  if (path == ActivityRoutes.approvalSuggestions) return 3;
  if (path == ActivityRoutes.approvalChecklist) return 4;
  return 0;
}

/// 하위 화면 스텁 제목.
String activityPageTitle(String path) {
  if (path.startsWith('${ActivityRoutes.drafts}/')) {
    return '임시보관 상세';
  }
  return _activityTitles[path] ?? '활동 관리';
}

/// 상단 배너 뒤로가기 fallback.
///
/// `/activities` 허브는 내부 안내 화면이라 사용자가 직접 보게 하지 않고,
/// 3개 상위 메뉴는 대시보드로, 세부 경로는 해당 상위 메뉴로 돌려보낸다.
String activityParentPath(String path) {
  if (path == ActivityRoutes.hub) return '/';
  if (path == ActivityRoutes.groupStatus ||
      path == ActivityRoutes.groupManage ||
      path == ActivityRoutes.groupApproval) {
    return '/';
  }
  if (path == ActivityRoutes.statusByAssignee ||
      path == ActivityRoutes.statusByStore) {
    return ActivityRoutes.groupStatus;
  }
  if (path.startsWith('${ActivityRoutes.drafts}/')) {
    return ActivityRoutes.drafts;
  }
  if (path == ActivityRoutes.drafts ||
      path == ActivityRoutes.manage ||
      path == ActivityRoutes.manageRegister ||
      path.startsWith('${ActivityRoutes.manage}/') ||
      path == ActivityRoutes.instructions ||
      path == ActivityRoutes.checklist) {
    return ActivityRoutes.groupManage;
  }
  if (path == ActivityRoutes.approvalAll ||
      path == ActivityRoutes.approvalPending ||
      path == ActivityRoutes.approvalActive ||
      path == ActivityRoutes.approvalInstructions ||
      path == ActivityRoutes.approvalSuggestions ||
      path == ActivityRoutes.approvalChecklist ||
      path == ActivityRoutes.approvalChecklistStats) {
    return ActivityRoutes.groupApproval;
  }
  return ActivityRoutes.groupManage;
}

final Map<String, String> _activityTitles = {
  ActivityRoutes.groupStatus: '활동현황',
  ActivityRoutes.groupManage: '활동관리',
  ActivityRoutes.groupApproval: '활동관리결재',
  ActivityRoutes.statusByAssignee: '담당자별 활동 현황',
  ActivityRoutes.statusByStore: '가맹점별 활동 현황',
  ActivityRoutes.drafts: '임시보관',
  ActivityRoutes.manage: '활동관리상세',
  ActivityRoutes.manageRegister: '활동 관리 등록',
  ActivityRoutes.instructions: '지시사항(결재특이사항)',
  ActivityRoutes.checklist: '체크리스트',
  ActivityRoutes.approvalAll: '전체활동관리',
  ActivityRoutes.approvalPending: '결재대기',
  ActivityRoutes.approvalActive: '결재진행',
  ActivityRoutes.approvalInstructions: '지시사항(결재특이사항)',
  ActivityRoutes.approvalSuggestions: '건의사항',
  ActivityRoutes.approvalChecklist: '체크리스트',
  ActivityRoutes.approvalChecklistStats: '체크리스트 통계',
};
