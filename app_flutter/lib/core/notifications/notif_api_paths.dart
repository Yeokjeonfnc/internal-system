/// 알림 REST 경로 — 백엔드 `ActController` (`/notifications`).
abstract final class NotifMstApiPaths {
  static const String root = '/notifications';

  static const String unreadCount = '$root/unread-count';

  static String read(int notifIdx) => '$root/$notifIdx/read';

  static const String activityApproval = '$root/activity-approval';
}

/// `PATCH /notifications/activity-approval` 쿼리 — `actIdx`는 [active_mst]와 동일 키명.
abstract final class NotifMstQueryParamKeys {
  static const String actIdx = 'actIdx';
}
