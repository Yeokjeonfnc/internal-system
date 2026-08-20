// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev001_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Partner _$PartnerFromJson(Map<String, dynamic> json) => Partner(
  partnerIdx: (json['partnerIdx'] as num).toInt(),
  createDt: erpFormatYmdFromJson(json['createDt']),
  partnerNm: _stringAny(json['partnerNm']),
  partnerTel: _stringAny(json['partnerTel']),
  partnerEmail: _stringAny(json['partnerEmail']),
  gender: _genderFromJson(json['gender']),
  partnerBirth: erpFormatYmdFromJson(json['partnerBirth']),
  pZipCd: _stringAny(json['pZipCd']),
  pAddress: _stringAny(json['pAddress']),
  pAddressDetail: _stringAny(json['pAddressDetail']),
  evaluationStatus:
      $enumDecodeNullable(
        _$EvaluationStatusEnumMap,
        json['evaluationStatus'],
      ) ??
      EvaluationStatus.pending,
  evaluationScore: asJsonIntOpt(json['evaluationScore']),
  pRegion: _stringAny(json['pRegion']),
  partnerStatus: _partnerStatusFromJson(json['partnerStatus']),
);

Map<String, dynamic> _$PartnerToJson(Partner instance) => <String, dynamic>{
  'partnerIdx': instance.partnerIdx,
  'createDt': instance.createDt,
  'partnerNm': instance.partnerNm,
  'partnerTel': instance.partnerTel,
  'partnerEmail': instance.partnerEmail,
  'gender': _$GenderEnumMap[instance.gender]!,
  'partnerBirth': instance.partnerBirth,
  'pZipCd': instance.pZipCd,
  'pAddress': instance.pAddress,
  'pAddressDetail': instance.pAddressDetail,
  'evaluationStatus': _$EvaluationStatusEnumMap[instance.evaluationStatus]!,
  'evaluationScore': instance.evaluationScore,
  'pRegion': instance.pRegion,
  'partnerStatus': _$PartnerStatusEnumMap[instance.partnerStatus]!,
};

const _$EvaluationStatusEnumMap = {
  EvaluationStatus.pending: 'pending',
  EvaluationStatus.completed: 'completed',
};

const _$GenderEnumMap = {Gender.male: 'male', Gender.female: 'female'};

const _$PartnerStatusEnumMap = {
  PartnerStatus.prospect: 'prospect',
  PartnerStatus.franchisee: 'franchisee',
};
