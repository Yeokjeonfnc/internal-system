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

int? _intOrNull(Object? e) {
  if (e == null) return null;
  if (e is int) return e;
  if (e is num) return e.toInt();
  return int.tryParse(e.toString());
}

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
    this.closedYn = false,
    required this.ownerNm,
    required this.storeTel,
    required this.zipCd,
    required this.address,
    required this.addressDetail,
    required this.contStartDt,
    required this.contEndDt,
    required this.firstContDt,
    this.transferDate = '',
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
    this.propIdx,
    this.partnerIdx,
    this.latitude,
    this.longitude,
  });

  @JsonKey(name: 'storeIdx', fromJson: _intAny)
  final int storeIdx;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String storeNm;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String brandCd;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String brandNm;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String storeCd;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String storeStatus;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String storeStatusNm;

  @JsonKey(defaultValue: false)
  final bool closedYn;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String ownerNm;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String storeTel;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String zipCd;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String address;

  @JsonKey(name: 'adressDetail', defaultValue: '')
  final String addressDetail;

  @JsonKey(name: 'contStartDt', fromJson: _stringAny)
  final String contStartDt;

  @JsonKey(name: 'contEndDt', fromJson: _stringAny)
  final String contEndDt;

  @JsonKey(defaultValue: '')
  final String firstContDt;

  @JsonKey(defaultValue: '')
  final String transferDate;

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

  @JsonKey(name: 'propIdx', fromJson: _intOrNull, includeIfNull: false)
  final int? propIdx;

  @JsonKey(name: 'partnerIdx', fromJson: _intOrNull, includeIfNull: false)
  final int? partnerIdx;

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
    this.storeDocIdx,
    required this.fileName,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.attached,
    required this.attachmentBaseDate,
    required this.attachedAt,
  });

  final int? storeDocIdx;
  final String fileName;
  final String modifiedAt;
  final String modifiedBy;
  final bool attached;
  final String attachmentBaseDate;
  final String attachedAt;

  factory Document.fromJson(Map<String, dynamic> json) {
    int? docIdx;
    final rawIdx = json['storeDocIdx'];
    if (rawIdx is int) {
      docIdx = rawIdx;
    } else if (rawIdx != null) {
      docIdx = int.tryParse(rawIdx.toString());
    }
    return Document(
      storeDocIdx: docIdx,
      fileName: json['fileName']?.toString() ?? '',
      modifiedAt: json['modifiedAt']?.toString() ?? '',
      modifiedBy: json['modifiedBy']?.toString() ?? '',
      attached: json['attached'] == true,
      attachmentBaseDate: json['attachmentBaseDate']?.toString() ?? '',
      attachedAt: json['attachedAt']?.toString() ?? '',
    );
  }
}

/// 히스토리 탭 한 행.
class HistoryEntry {
  const HistoryEntry({
    required this.chgDt,
    required this.chgType,
    required this.chgContent,
    required this.plainApiContent,
    required this.chgUserId,
  });

  @JsonKey(name: 'chgDt', fromJson: storeHistoryChgDtFromJson, defaultValue: '')
  final String chgDt;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String chgType;

  @JsonKey(name: 'chgContent', fromJson: storeHistoryChgContentEncode, defaultValue: '[]')
  final String chgContent;

  @JsonKey(name: 'content', fromJson: _stringAny, defaultValue: '')
  final String plainApiContent;

  @JsonKey(fromJson: _stringAny, defaultValue: '')
  final String chgUserId;

  /// UI 표시용 — `UPDATE`만 [column_desc] 요약, 그 외 API [content] 등 기존 포맷.
  String get content =>
      storeHistoryDisplayFromEncoded(chgContent, plainApiContent, chgType);

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      chgDt: storeHistoryChgDtFromJson(json['chgDt']),
      chgType: _stringAny(json['chgType']),
      chgContent: storeHistoryChgContentEncode(json['chgContent']),
      plainApiContent: _stringAny(json['content']),
      chgUserId: _stringAny(json['chgUserId']),
    );
  }
}
