// 알림 종류·탭 시 이동 경로.

import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

abstract final class NotifTypes {
  static const String activityApproval = 'ACTIVITY_APPROVAL';
  static const String eapApproval = 'EAP_APPROVAL';
}

String? notifOpenRoute(NotifRow row) {
  final id = row.actIdx;
  if (id == null) return null;
  final typ = row.notifTyp.trim();
  if (typ == NotifTypes.activityApproval) {
    return ActivityRoutes.approvalActivityDetail(id);
  }
  if (typ == NotifTypes.eapApproval) {
    return EapRoutes.documentDetail('LOCAL-$id');
  }
  return null;
}
