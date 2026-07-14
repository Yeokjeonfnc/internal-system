/// 가맹점 저장 요청 본문 — 백엔드 `StoreMstWriteRequestDto`와 동일한 JSON 키.
///
/// `merge`는 뒤쪽 페이로드의 키가 이긴다(`Map` 병합과 동일, null 값 포함).
class StoreMstWriteRequest {
  /// 등록·수정 시 연결 창업자 FK — DTO 필드 `partnerIdx`.
  static const String jsonKeyPartnerIdx = 'partnerIdx';

  static const String jsonKeyStoreCd = 'storeCd';
  static const String jsonKeyStoreNm = 'storeNm';
  static const String jsonKeyOwnerNm = 'ownerNm';
  static const String jsonKeyRegionCd = 'regionCd';
  static const String jsonKeyStoreTel = 'storeTel';
  static const String jsonKeyAddress = 'address';
  static const String jsonKeyLatitude = 'latitude';
  static const String jsonKeyLongitude = 'longitude';
  static const String jsonKeyStoreStatus = 'storeStatus';
  static const String jsonKeyContEndDt = 'contEndDt';
  static const String jsonKeyAutoRenewalYn = 'autoRenewalYn';
  static const String jsonKeyStoreType = 'storeType';
  static const String jsonKeySvId = 'svId';
  static const String jsonKeySvNm = 'svNm';
  static const String jsonKeyAdressDetail = 'adressDetail';
  static const String jsonKeyZipCd = 'zipCd';
  static const String jsonKeyBrandCd = 'brandCd';
  static const String jsonKeyContStartDt = 'contStartDt';
  static const String jsonKeyBusinessNumber = 'businessNumber';
  static const String jsonKeyFirstContDt = 'firstContDt';
  static const String jsonKeyTransferDate = 'transferDate';
  static const String jsonKeyFrFee = 'frFee';
  static const String jsonKeyEduFee = 'eduFee';
  static const String jsonKeyInsuDeposit = 'insuDeposit';
  static const String jsonKeyContDeposit = 'contDeposit';
  static const String jsonKeyContManager = 'contManager';
  static const String jsonKeyContManagerNm = 'contManagerNm';
  static const String jsonKeyEduManager = 'eduManager';
  static const String jsonKeyEduManagerNm = 'eduManagerNm';
  static const String jsonKeyContArea = 'contArea';
  static const String jsonKeyRealArea = 'realArea';
  static const String jsonKeyFloor = 'floor';
  static const String jsonKeyParkingCount = 'parkingCount';
  static const String jsonKeyPremiumFee = 'premiumFee';
  static const String jsonKeyMonthlyRent = 'monthlyRent';
  static const String jsonKeyRentDeposit = 'rentDeposit';
  static const String jsonKeyNotes = 'notes';

  /// `property_mst.prop_idx` — 물건 조회로 연결 시 저장.
  static const String jsonKeyPropIdx = 'propIdx';

  StoreMstWriteRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  StoreMstWriteRequest merge(StoreMstWriteRequest other) =>
      StoreMstWriteRequest._({..._map, ...other._map});

  factory StoreMstWriteRequest.fromMap(Map<String, dynamic> map) =>
      StoreMstWriteRequest._(Map<String, dynamic>.from(map));

  String? get storeNm => _map[jsonKeyStoreNm] as String?;

  bool get isStoreNmBlank => (storeNm ?? '').trim().isEmpty;
}

/// 가맹점 REST 경로 — 백엔드 `StrController` (`/stores`)와 동일.
abstract final class StoreMstApiPaths {
  static const String root = '/stores';

  static String one(int storeIdx) => '$root/$storeIdx';

  static String histories(int storeIdx) => '$root/$storeIdx/histories';

  static String documents(int storeIdx) => '$root/$storeIdx/documents';

  static String documentDownload(int storeIdx, int storeDocIdx) =>
      '$root/$storeIdx/documents/$storeDocIdx/download';

  static String documentOne(int storeIdx, int storeDocIdx) =>
      '$root/$storeIdx/documents/$storeDocIdx';

  static String nfcTag(int storeIdx) => '$root/$storeIdx/nfc-tag';

  /// `GET` 검색 — 쿼리 키는 [StoreMstWriteRequest.jsonKeyStoreNm].
  static String get search => '$root/search';
}
