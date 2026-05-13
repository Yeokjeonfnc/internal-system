import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

/// `/activities/status/*` 피벗 행 — 백엔드 `ActivityStatusPivotRowDto`.
class ActivityStatusPivotRow {
  const ActivityStatusPivotRow({
    required this.storeNm,
    required this.userName,
    required this.userId,
    required this.actDtRaw,
    required this.count,
  });

  final String storeNm;
  final String userName;
  final String userId;
  final String actDtRaw;
  final int count;

  factory ActivityStatusPivotRow.fromJson(Map<String, dynamic> json) {
    return ActivityStatusPivotRow(
      storeNm: json.jsonString(ActiveMstApiJsonKeys.storeNm),
      userName: json.jsonString(ActiveMstApiJsonKeys.userName),
      userId: json.jsonString(ActiveMstApiJsonKeys.userId),
      actDtRaw: json.jsonString(ActiveMstApiJsonKeys.actDt),
      count: (json[ActiveMstApiJsonKeys.count] as Object?).asJsonInt(0),
    );
  }
}
