/// 활동 계획 API 경로 — 백엔드 `ActivityPlanController`.
abstract final class ActivityPlanApiPaths {
  static const String root = '/activity-plans';
  static const String calendarContext = '$root/calendar-context';
  static const String month = '$root/month';
  static const String day = '$root/day';

  static String teamViewPermissions(int userIdx) =>
      '/users/$userIdx/team-view-permissions';
}
