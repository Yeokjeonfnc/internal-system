import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';

part 'dev001_model.g.dart';

/// 예비창업자 평가 상태.
enum EvaluationStatus { pending, completed }

/// 예비창업자 / 가맹점사업자 구분.
enum PartnerStatus { prospect, franchisee }

String partnerStatusLabelKorean(PartnerStatus s) => switch (s) {
  PartnerStatus.prospect => '예비창업자',
  PartnerStatus.franchisee => '가맹점사업자',
};

/// 성별.
enum Gender { male, female }

Gender _genderFromJson(Object? v) {
  final s = v?.toString();
  return s == 'F' || s == '여' ? Gender.female : Gender.male;
}

PartnerStatus _partnerStatusFromJson(Object? v) =>
    v?.toString() == '가맹점사업자'
        ? PartnerStatus.franchisee
        : PartnerStatus.prospect;

Object? _readPartnerZip(Object? json, String key) {
  final m = json as Map;
  return m['pZipCd'] ?? m['p_zip_cd'];
}

Object? _readPartnerAddr(Object? json, String key) {
  final m = json as Map;
  return m['pAddress'] ?? m['p_address'];
}

Object? _readPartnerAddrDetail(Object? json, String key) {
  final m = json as Map;
  return m['pAddressDetail'] ?? m['p_address_detail'];
}

Object? _readPartnerRegion(Object? json, String key) {
  final m = json as Map;
  return m['pRegion'] ?? m['p_region'];
}

/// 예비창업자 모델.
@JsonSerializable()
class Partner {
  const Partner({
    required this.partnerIdx,
    required this.createDt,
    required this.partnerNm,
    required this.partnerTel,
    required this.partnerEmail,
    required this.gender,
    required this.partnerBirth,
    required this.pZipCd,
    required this.pAddress,
    required this.pAddressDetail,
    required this.evaluationStatus,
    required this.evaluationScore,
    required this.pRegion,
    required this.partnerStatus,
  });

  final int partnerIdx;

  @JsonKey(fromJson: erpFormatYmdFromJson)
  final String createDt;

  final String partnerNm;
  final String partnerTel;
  final String partnerEmail;

  @JsonKey(fromJson: _genderFromJson)
  final Gender gender;

  @JsonKey(fromJson: erpFormatYmdFromJson)
  final String partnerBirth;

  @JsonKey(readValue: _readPartnerZip, fromJson: _stringAny)
  final String pZipCd;

  @JsonKey(readValue: _readPartnerAddr, fromJson: _stringAny)
  final String pAddress;

  @JsonKey(readValue: _readPartnerAddrDetail, fromJson: _stringAny)
  final String pAddressDetail;

  @JsonKey(defaultValue: EvaluationStatus.pending)
  final EvaluationStatus evaluationStatus;

  @JsonKey(fromJson: asJsonIntOpt)
  final int? evaluationScore;

  @JsonKey(readValue: _readPartnerRegion, fromJson: _stringAny)
  final String pRegion;

  @JsonKey(fromJson: _partnerStatusFromJson)
  final PartnerStatus partnerStatus;

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerToJson(this);
}

String _stringAny(Object? e) => e?.toString() ?? '';
