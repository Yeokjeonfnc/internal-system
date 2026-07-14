import 'package:app_flutter/core/property_mst/property_mst_api_json_keys.dart';

/// 물건 저장 요청 본문 — 백엔드 `PropertyMstWriteRequestDto` JSON 키와 동일.
///
/// `merge`는 뒤쪽 페이로드의 키가 이긴다(null 포함).
class PropertyMstWriteRequest {
  static const String jsonKeyPropNm = PropertyMstApiJsonKeys.propNm;
  static const String jsonKeyZipCd = PropertyMstApiJsonKeys.zipCd;
  static const String jsonKeyAddress = PropertyMstApiJsonKeys.address;
  static const String jsonKeyAddressDetail =
      PropertyMstApiJsonKeys.addressDetail;
  static const String jsonKeyRegion = PropertyMstApiJsonKeys.region;
  static const String jsonKeyPropStatus = PropertyMstApiJsonKeys.propStatus;
  static const String jsonKeyPropType = PropertyMstApiJsonKeys.propType;
  static const String jsonKeySurveyor = PropertyMstApiJsonKeys.surveyor;
  static const String jsonKeyFloor = PropertyMstApiJsonKeys.floor;
  static const String jsonKeyParkingCount = PropertyMstApiJsonKeys.parkingCount;
  static const String jsonKeyContArea = PropertyMstApiJsonKeys.contArea;
  static const String jsonKeyRealArea = PropertyMstApiJsonKeys.realArea;
  static const String jsonKeyRentDeposit = PropertyMstApiJsonKeys.rentDeposit;
  static const String jsonKeyMonthlyRent = PropertyMstApiJsonKeys.monthlyRent;
  static const String jsonKeyPremiumFee = PropertyMstApiJsonKeys.premiumFee;
  static const String jsonKeyMaintFee = PropertyMstApiJsonKeys.maintFee;
  static const String jsonKeyPropNotes = PropertyMstApiJsonKeys.propNotes;
  static const String jsonKeySurveyDt = PropertyMstApiJsonKeys.surveyDt;
  static const String jsonKeyLatitude = PropertyMstApiJsonKeys.latitude;
  static const String jsonKeyLongitude = PropertyMstApiJsonKeys.longitude;

  PropertyMstWriteRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  PropertyMstWriteRequest merge(PropertyMstWriteRequest other) =>
      PropertyMstWriteRequest._({..._map, ...other._map});

  factory PropertyMstWriteRequest.fromMap(Map<String, dynamic> map) =>
      PropertyMstWriteRequest._(Map<String, dynamic>.from(map));

  String? get propNm => _map[jsonKeyPropNm] as String?;
  String? get zipCd => _map[jsonKeyZipCd] as String?;
  String? get address => _map[jsonKeyAddress] as String?;
  String? get surveyor => _map[jsonKeyAddress] as String?;
  String? get surveyDt => _map[jsonKeySurveyDt] as String?;

  bool get isPropNmBlank => (propNm ?? '').trim().isEmpty;
}

/// 물건 REST 경로 — 백엔드 `DevController` (`/properties`).
abstract final class PropertyMstApiPaths {
  static const String root = '/properties';

  static String one(int propIdx) => '$root/$propIdx';

  static String documents(int propIdx) => '${one(propIdx)}/documents';

  static String documentDownload(int propIdx, int propertyDocIdx) =>
      '${documents(propIdx)}/$propertyDocIdx/download';

  static String documentOne(int propIdx, int propertyDocIdx) =>
      '${documents(propIdx)}/$propertyDocIdx';
}
