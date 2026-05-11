import 'package:app_flutter/core/user_mst/user_mst_api_json_keys.dart';

/// 사원 저장 요청 본문 — 생성 `UserMstCreateRequestDto`, 수정 `UserMstUpdateRequestDto` JSON 키와 동일.
class UserMstWritePayload {
  static const String jsonKeyUserName = UserMstApiJsonKeys.userName;
  static const String jsonKeyUserPassword = UserMstApiJsonKeys.userPassword;
  static const String jsonKeyUserId = UserMstApiJsonKeys.userId;
  static const String jsonKeyDeptIdx = UserMstApiJsonKeys.deptIdx;
  static const String jsonKeyUserPhone = UserMstApiJsonKeys.userPhone;
  static const String jsonKeyUserEmail = UserMstApiJsonKeys.userEmail;
  static const String jsonKeySvYn = UserMstApiJsonKeys.svYn;
  static const String jsonKeyTagYn = UserMstApiJsonKeys.tagYn;
  static const String jsonKeyPositionCd = UserMstApiJsonKeys.positionCd;
  static const String jsonKeyJoinDt = UserMstApiJsonKeys.joinDt;

  UserMstWritePayload._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory UserMstWritePayload.fromMap(Map<String, dynamic> map) =>
      UserMstWritePayload._(Map<String, dynamic>.from(map));
}

/// 사원 REST 경로 — 백엔드 `MstController` (`/users`).
abstract final class UserMstApiPaths {
  static const String root = '/users';

  static String one(int userIdx) => '$root/$userIdx';

  /// `GET` 쿼리 파라미터 이름 — `UserMstApiJsonKeys.userId`와 동일 문자열.
  static const String checkUserId = '$root/check-user-id';
}
