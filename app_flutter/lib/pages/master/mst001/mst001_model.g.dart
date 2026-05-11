// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mst001_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  userIdx: (json['userIdx'] as num).toInt(),
  name: json['userName'] as String,
  department: json['deptNm'] as String,
  positionNm: json['positionNm'] as String,
  mobilePhone: json['userPhone'] as String,
  email: json['userEmail'] as String,
  joinDt: _joinDtFromJson(json['joinDt']),
  tagYn: _tagYnFromJsonField(json['tagYn']),
  userId: json['userId'] as String? ?? '',
  deptIdx: (json['deptIdx'] as num?)?.toInt(),
  positionCd: json['positionCd'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'userIdx': instance.userIdx,
  'userName': instance.name,
  'deptNm': instance.department,
  'deptIdx': instance.deptIdx,
  'positionNm': instance.positionNm,
  'positionCd': instance.positionCd,
  'userPhone': instance.mobilePhone,
  'userEmail': instance.email,
  'joinDt': instance.joinDt,
  'userId': instance.userId,
  'tagYn': _tagYnToJson(instance.tagYn),
};
