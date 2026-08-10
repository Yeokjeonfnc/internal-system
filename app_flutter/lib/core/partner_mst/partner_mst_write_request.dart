import 'package:app_flutter/core/partner_mst/partner_mst_api_json_keys.dart';

/// 예비창업자 저장 요청 본문 — 백엔드 `PartnerMstWriteRequestDto` JSON 키와 동일.
class PartnerMstWriteRequest {
  static const String jsonKeyPartnerNm = PartnerMstApiJsonKeys.partnerNm;
  static const String jsonKeyPartnerStatus =
      PartnerMstApiJsonKeys.partnerStatus;
  static const String jsonKeyPartnerTel = PartnerMstApiJsonKeys.partnerTel;
  static const String jsonKeyPartnerEmail = PartnerMstApiJsonKeys.partnerEmail;
  static const String jsonKeyGender = PartnerMstApiJsonKeys.gender;
  static const String jsonKeyPartnerBirth = PartnerMstApiJsonKeys.partnerBirth;
  static const String jsonKeyPZipCd = PartnerMstApiJsonKeys.pZipCd;
  static const String jsonKeyPAddress = PartnerMstApiJsonKeys.pAddress;
  static const String jsonKeyPAddressDetail =
      PartnerMstApiJsonKeys.pAddressDetail;
  static const String jsonKeyPRegion = PartnerMstApiJsonKeys.pRegion;

  PartnerMstWriteRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory PartnerMstWriteRequest.fromMap(Map<String, dynamic> map) =>
      PartnerMstWriteRequest._(Map<String, dynamic>.from(map));

  String? get partnerNm => _map[jsonKeyPartnerNm] as String?;
  String? get partnerTel => _map[jsonKeyPartnerTel] as String?;

  bool get isPartnerNmBlank => (partnerNm ?? '').trim().isEmpty;
  bool get isPartnerTelBlank => (partnerTel ?? '').trim().isEmpty;
}

/// 예비창업자 REST 경로 — 백엔드 `DevController` (`/partners`).
abstract final class PartnerMstApiPaths {
  static const String root = '/partners';
  static const String checkEmail = '$root/check-email';

  static String one(int partnerIdx) => '$root/$partnerIdx';
}
