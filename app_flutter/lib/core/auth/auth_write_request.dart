/// `POST /auth/login` 본문 — 백엔드 `AuthLoginRequestDto`.
class AuthLoginRequest {
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyUserPassword = 'userPassword';

  AuthLoginRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory AuthLoginRequest({
    required String userId,
    required String userPassword,
  }) =>
      AuthLoginRequest._({
        jsonKeyUserId: userId,
        jsonKeyUserPassword: userPassword,
      });
}

/// `PUT /auth/profile` 본문 — 백엔드 `AuthProfileUpdateRequestDto`.
/// 값이 `null`인 인자는 JSON에 포함하지 않는다(기존 `AuthApiService.updateUserProfile`와 동일).
class AuthProfileUpdateRequest {
  static const String jsonKeyUserName = 'userName';
  static const String jsonKeyUserPassword = 'userPassword';
  static const String jsonKeyUserPhone = 'userPhone';
  static const String jsonKeyPositionCd = 'positionCd';
  static const String jsonKeySvYn = 'svYn';
  static const String jsonKeyTagYn = 'tagYn';

  AuthProfileUpdateRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory AuthProfileUpdateRequest({
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
    return AuthProfileUpdateRequest._(m);
  }
}

/// 인증 REST 경로 — `AuthController` (`/auth/*`).
/// 쿼리 `userId`는 [AuthLoginRequest.jsonKeyUserId]와 동일 문자열.
abstract final class AuthApiPaths {
  static const String login = '/auth/login';

  static const String profile = '/auth/profile';
}
