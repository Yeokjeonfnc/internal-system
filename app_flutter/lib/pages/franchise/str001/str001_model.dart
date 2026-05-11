import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';
import 'package:app_flutter/core/utils/store_history_format.dart';

part 'str001_model.g.dart';

String _stringAny(Object? e) => e?.toString() ?? '';

/// 백엔드 [BigDecimal] → JSON 숫자. `as String?` 만으로는 파싱 예외로 목록 전체가 비게 된다.
String? _coordStringFromJson(Object? v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}

int _intAny(Object? e) => e.asJsonInt();

/// 가맹점 목록·상세 공통 모델.
@JsonSerializable()
class Store {
  const Store({
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
    required this.contManagerNm,
    required this.eduManager,
    required this.eduManagerNm,

    required this.contArea,
    required this.realArea,
    required this.regionCd,
    required this.regionNm,
    required this.storeType,
    required this.storeTypeNm,
    required this.svId,
    required this.svNm,
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

  @JsonKey(name: 'storeIdx', fromJson: _intAny)
  final int storeIdx;

  final String storeNm;
  final String brandCd;

  @JsonKey(fromJson: _stringAny)
  final String brandNm;

  @JsonKey(fromJson: _stringAny)
  final String storeCd;
  final String storeStatus;
  final String storeStatusNm;
  final String ownerNm;
  final String storeTel;
  final String zipCd;
  final String address;

  @JsonKey(name: 'adressDetail', defaultValue: '')
  final String addressDetail;

  @JsonKey(name: 'contStartDt', fromJson: _stringAny)
  final String contStartDt;

  @JsonKey(name: 'contEndDt', fromJson: _stringAny)
  final String contEndDt;

  @JsonKey(defaultValue: '')
  final String firstContDt;

  @JsonKey(fromJson: _stringAny)
  final String contManager;

  @JsonKey(defaultValue: '')
  final String contManagerNm;

  @JsonKey(fromJson: _stringAny)
  final String eduManager;

  @JsonKey(defaultValue: '')
  final String eduManagerNm;

  @JsonKey(defaultValue: '')
  final String regionCd;

  @JsonKey(defaultValue: '')
  final String regionNm;

  @JsonKey(defaultValue: '')
  final String storeType;

  @JsonKey(defaultValue: '')
  final String storeTypeNm;

  @JsonKey(fromJson: _stringAny)
  final String svId;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String svNm;

  @JsonKey(defaultValue: '')
  final String businessNumber;

  @JsonKey(defaultValue: '')
  final String notes;

  @JsonKey(fromJson: _stringAny)
  final String frFee;

  @JsonKey(fromJson: _stringAny)
  final String eduFee;

  @JsonKey(fromJson: _stringAny)
  final String insuDeposit;

  @JsonKey(fromJson: _stringAny)
  final String contDeposit;

  @JsonKey(fromJson: _stringAny)
  final String contArea;

  @JsonKey(fromJson: _stringAny)
  final String realArea;

  @JsonKey(fromJson: _intAny)
  final int floor;

  @JsonKey(fromJson: _intAny)
  final int parkingCount;

  @JsonKey(fromJson: _intAny)
  final int monthlyRent;

  @JsonKey(fromJson: _intAny)
  final int rentDeposit;

  @JsonKey(fromJson: _intAny)
  final int premiumFee;

  @JsonKey(fromJson: _coordStringFromJson)
  final String? latitude;

  @JsonKey(fromJson: _coordStringFromJson)
  final String? longitude;

  String get region => regionNm.isNotEmpty ? regionNm : regionCd;
  String get contractStartDate => contStartDt;
  String get contractEndDate => contEndDt;

  factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);

  Map<String, dynamic> toJson() => _$StoreToJson(this);
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
@JsonSerializable(createToJson: false)
class HistoryEntry {
  const HistoryEntry({
    required this.chgDt,
    required this.chgContent,
    required this.plainApiContent,
    required this.chgUserId,
  });

  @JsonKey(name: 'chgDt', fromJson: storeHistoryChgDtFromJson)
  final String chgDt;

  @JsonKey(name: 'chgContent', fromJson: storeHistoryChgContentEncode)
  final String chgContent;

  @JsonKey(name: 'content', defaultValue: '')
  final String plainApiContent;

  @JsonKey(fromJson: _stringAny)
  final String chgUserId;

  /// UI 표시용(변경 요약 + 폴백).
  String get content =>
      storeHistoryDisplayFromEncoded(chgContent, plainApiContent);

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);
}
