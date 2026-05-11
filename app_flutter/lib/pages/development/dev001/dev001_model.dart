import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/partner_mst/partner_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

part 'dev001_model.g.dart';

/// 예비창업자 평가 상태.
enum EvaluationStatus { pending, completed }

/// 예비창업자 / 가맹점사업자 구분.
enum PartnerStatus { prospect, franchisee }

/// `PartnerStatus` → API·화면용 한글 라벨.
String statusLabelKo(PartnerStatus s) => switch (s) {
  PartnerStatus.prospect => '예비창업자',
  PartnerStatus.franchisee => '가맹점사업자',
};

/// 성별.
enum Gender { male, female }

Gender _genderFromJson(Object? v) {
  final s = v?.toString();
  return s == 'F' || s == '여' ? Gender.female : Gender.male;
}

PartnerStatus _partnerStatusFromJson(Object? v) => v?.toString() == '가맹점사업자'
    ? PartnerStatus.franchisee
    : PartnerStatus.prospect;

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

  @JsonKey(name: PartnerMstApiJsonKeys.partnerIdx)
  final int partnerIdx;

  @JsonKey(name: PartnerMstApiJsonKeys.createDt, fromJson: erpFormatYmdFromJson)
  final String createDt;

  @JsonKey(name: PartnerMstApiJsonKeys.partnerNm)
  final String partnerNm;

  @JsonKey(name: PartnerMstApiJsonKeys.partnerTel)
  final String partnerTel;

  @JsonKey(name: PartnerMstApiJsonKeys.partnerEmail)
  final String partnerEmail;

  @JsonKey(name: PartnerMstApiJsonKeys.gender, fromJson: _genderFromJson)
  final Gender gender;

  @JsonKey(
    name: PartnerMstApiJsonKeys.partnerBirth,
    fromJson: erpFormatYmdFromJson,
  )
  final String partnerBirth;

  @JsonKey(name: PartnerMstApiJsonKeys.pZipCd, fromJson: _stringAny)
  final String pZipCd;

  @JsonKey(name: PartnerMstApiJsonKeys.pAddress, fromJson: _stringAny)
  final String pAddress;

  @JsonKey(name: PartnerMstApiJsonKeys.pAddressDetail, fromJson: _stringAny)
  final String pAddressDetail;

  @JsonKey(
    name: PartnerMstApiJsonKeys.evaluationStatus,
    defaultValue: EvaluationStatus.pending,
  )
  final EvaluationStatus evaluationStatus;

  @JsonKey(name: PartnerMstApiJsonKeys.evaluationScore, fromJson: asJsonIntOpt)
  final int? evaluationScore;

  @JsonKey(name: PartnerMstApiJsonKeys.pRegion, fromJson: _stringAny)
  final String pRegion;

  @JsonKey(
    name: PartnerMstApiJsonKeys.partnerStatus,
    fromJson: _partnerStatusFromJson,
  )
  final PartnerStatus partnerStatus;

  factory Partner.fromJson(Map<String, dynamic> json) =>
      _$PartnerFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerToJson(this);
}

String _stringAny(Object? e) => e?.toString() ?? '';
