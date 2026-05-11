/// `POST /auth/login` 본문 — 백엔드 `AuthLoginRequestDto`.
class AuthLoginPayload {
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyUserPassword = 'userPassword';

  AuthLoginPayload._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory AuthLoginPayload({
    required String userId,
    required String userPassword,
  }) =>
      AuthLoginPayload._({
        jsonKeyUserId: userId,
        jsonKeyUserPassword: userPassword,
      });
}

/// `PUT /auth/profile` 본문 — 백엔드 `AuthProfileUpdateRequestDto`.
/// 값이 `null`인 인자는 JSON에 포함하지 않는다(기존 `AuthApiService.updateUserProfile`와 동일).
class AuthProfileUpdatePayload {
  static const String jsonKeyUserName = 'userName';
  static const String jsonKeyUserPassword = 'userPassword';
  static const String jsonKeyUserPhone = 'userPhone';
  static const String jsonKeyPositionCd = 'positionCd';
  static const String jsonKeySvYn = 'svYn';
  static const String jsonKeyTagYn = 'tagYn';

  AuthProfileUpdatePayload._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory AuthProfileUpdatePayload({
    String? userName,
    String? userPassword,
    String? userPhone,
    String? positionCd,
    String? svYn,
    String? tagYn,
  }) {
    final m = <String, dynamic>{};
    if (userName != null) m[jsonKeyUserName] = userName;
    if (userPassword != null && userPassword.isNotEmpty) {
      m[jsonKeyUserPassword] = userPassword;
    }
    if (userPhone != null) m[jsonKeyUserPhone] = userPhone;
    if (positionCd != null) m[jsonKeyPositionCd] = positionCd;
    if (svYn != null) m[jsonKeySvYn] = svYn;
    if (tagYn != null) m[jsonKeyTagYn] = tagYn;
    return AuthProfileUpdatePayload._(m);
  }
}

/// 인증 REST 경로 — `AuthController` (`/auth/*`).
/// 쿼리 `userId`는 [AuthLoginPayload.jsonKeyUserId]와 동일 문자열.
abstract final class AuthApiPaths {
  static const String login = '/auth/login';

  static const String profile = '/auth/profile';
}
