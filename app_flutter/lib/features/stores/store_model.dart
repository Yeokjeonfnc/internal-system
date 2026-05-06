/// 가맹점 목록·상세 공통 모델.
class Store {
  const Store({
    required this.no,
    required this.storeIdx,
    required this.storeNm,
    required this.brandCd,
    required this.brandNm,
    required this.storeCd,
    required this.storeStatus,
    required this.storeStatusNm,
    required this.ownerNm,
    required this.storeTel,
    required this.zipCd,
    required this.address,
    required this.addressDetail,
    required this.contStartDt,
    required this.contEndDt,
    required this.firstContDt,
    required this.frFee,
    required this.eduFee,
    required this.insuDeposit,
    required this.contDeposit,
    required this.contManager,
    required this.eduManager,
    required this.contArea,
    required this.realArea,
    required this.regionCd,
    required this.regionNm,
    required this.storeType,
    required this.storeTypeNm,
    required this.svId,
    required this.floor,
    required this.parkingCount,
    required this.monthlyRent,
    required this.rentDeposit,
    required this.premiumFee,
    this.businessNumber = '',
    this.notes = '',
    this.latitude,
    this.longitude,
  });

  final int no;
  final int storeIdx;
  final String storeNm;
  final String brandCd;
  final String brandNm;
  final String storeCd;
  final String storeStatus;
  final String storeStatusNm;
  final String ownerNm;
  final String storeTel;
  final String zipCd;
  final String address;
  final String notes;
  final String addressDetail;
  final String contStartDt;
  final String contEndDt;
  final String firstContDt;
  final String regionCd;
  final String regionNm;
  final String storeType;
  final String storeTypeNm;
  final String svId;
  final String businessNumber;
  final String frFee;
  final String eduFee;
  final String insuDeposit;
  final String contDeposit;
  final String contManager;
  final String eduManager;
  final String contArea;
  final String realArea;
  final int floor;
  final int parkingCount;
  final int monthlyRent;
  final int rentDeposit;
  final int premiumFee;

  /// 백엔드 `latitude` / `longitude` (문자열로 보관해 표시·편집과 동일하게 처리).
  final String? latitude;
  final String? longitude;

  // 호환성을 위한 getter
  String get region => regionNm.isNotEmpty ? regionNm : regionCd;
  String get contractStartDate => contStartDt;
  String get contractEndDate => contEndDt;
}

/// 문서 탭 한 행.
class Document {
  const Document({
    required this.fileName,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.attached,
    required this.attachmentBaseDate,
    required this.attachedAt,
  });

  final String fileName;
  final String modifiedAt;
  final String modifiedBy;
  final bool attached;
  final String attachmentBaseDate;
  final String attachedAt;
}

/// 히스토리 탭 한 행.
class HistoryEntry {
  const HistoryEntry({
    required this.chgDt,
    required this.chgContent,
    required this.content,
    required this.chgUserId,
  });

  final String chgDt;
  final String chgContent;
  final String content;
  final String chgUserId;
}
