/// `user_mst` 목록·상세 응답 — 백엔드 `UserMstDto` JSON 키와 동일.
///
/// 생성·수정 요청(`UserMstCreateRequestDto` / `UserMstUpdateRequestDto`)에도 쓰이는 이름은
/// `UserMstWritePayload.jsonKey*`가 이 상수를 가리킨다.
abstract final class UserMstApiJsonKeys {
  static const String userIdx = 'userIdx';
  static const String userName = 'userName';
  static const String userId = 'userId';
  static const String deptIdx = 'deptIdx';
  static const String deptNm = 'deptNm';
  static const String userPhone = 'userPhone';
  static const String userEmail = 'userEmail';
  static const String svYn = 'svYn';
  static const String positionCd = 'positionCd';
  static const String positionNm = 'positionNm';
  static const String tagYn = 'tagYn';
  static const String joinDt = 'joinDt';

  /// 요청 전용(응답 DTO에는 없음).
  static const String userPassword = 'userPassword';

  /// `GET /users/check-user-id` — `UserIdAvailabilityDto`.
  static const String available = 'available';
}
