/// `property_mst` 목록·상세 응답 — 백엔드 `PropertyMstDto` JSON 키와 동일.
///
/// `location`·`franchiseFlag`·`addressScope` 등은 엔티티/확장 응답에서 올 수 있는 키로 앱 모델과 맞춘다.
/// `PropertyMstWriteRequest.jsonKey*`는 요청과 겹치는 이름에 이 상수를 가리킨다.
abstract final class PropertyMstApiJsonKeys {
  static const String propIdx = 'propIdx';
  static const String propNm = 'propNm';
  static const String zipCd = 'zipCd';
  static const String address = 'address';
  static const String addressDetail = 'addressDetail';
  static const String region = 'region';
  static const String propStatus = 'propStatus';
  static const String propType = 'propType';
  static const String surveyor = 'surveyor';
  static const String floor = 'floor';
  static const String parkingCount = 'parkingCount';
  static const String contArea = 'contArea';
  static const String realArea = 'realArea';
  static const String rentDeposit = 'rentDeposit';
  static const String monthlyRent = 'monthlyRent';
  static const String premiumFee = 'premiumFee';
  static const String maintFee = 'maintFee';
  static const String propNotes = 'propNotes';
  static const String surveyDt = 'surveyDt';
  static const String createDt = 'createDt';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String location = 'location';
  static const String franchiseFlag = 'franchiseFlag';
  static const String addressScope = 'addressScope';
}
