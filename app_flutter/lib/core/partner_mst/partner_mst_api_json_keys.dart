/// `partner_mst` 목록·상세 응답 — 백엔드 `PartnerMstDto` JSON 키와 동일.
///
/// `evaluationStatus`·`evaluationScore`는 DTO에 없을 수 있으나 앱 목록 JSON과 호환을 위해 포함한다.
/// `PartnerMstWritePayload.jsonKey*`는 요청 본문과 겹치는 이름에 이 상수를 가리킨다.
abstract final class PartnerMstApiJsonKeys {
  static const String partnerIdx = 'partnerIdx';
  static const String partnerNm = 'partnerNm';
  static const String partnerStatus = 'partnerStatus';
  static const String partnerTel = 'partnerTel';
  static const String partnerEmail = 'partnerEmail';
  static const String gender = 'gender';
  static const String createDt = 'createDt';
  static const String partnerBirth = 'partnerBirth';
  static const String pZipCd = 'pZipCd';
  static const String pAddress = 'pAddress';
  static const String pAddressDetail = 'pAddressDetail';
  static const String pRegion = 'pRegion';
  static const String evaluationStatus = 'evaluationStatus';
  static const String evaluationScore = 'evaluationScore';
}
