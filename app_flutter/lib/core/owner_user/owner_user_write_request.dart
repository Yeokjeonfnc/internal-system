/// 가맹점주 API 경로·JSON 키.
abstract final class OwnerUserApiJsonKeys {
  static const String userIdx = 'userIdx';
  static const String userName = 'userName';
  static const String userId = 'userId';
  static const String userPhone = 'userPhone';
  static const String userEmail = 'userEmail';
  static const String userPassword = 'userPassword';
  static const String storeIdx = 'storeIdx';
  static const String storeNm = 'storeNm';
}

/// 가맹점주 저장 요청 본문.
class OwnerUserWriteRequest {
  OwnerUserWriteRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory OwnerUserWriteRequest.fromMap(Map<String, dynamic> map) =>
      OwnerUserWriteRequest._(Map<String, dynamic>.from(map));
}

abstract final class OwnerUserApiPaths {
  static const String root = '/owner-users';

  static String one(int userIdx) => '$root/$userIdx';
}
