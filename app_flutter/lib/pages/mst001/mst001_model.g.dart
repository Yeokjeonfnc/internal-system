// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mst001_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
  no: (json['userIdx'] as num).toInt(),
  name: json['userName'] as String,
  department: json['deptNm'] as String,
  jobTitle: json['positionNm'] as String,
  mobilePhone: json['userPhone'] as String,
  email: json['userEmail'] as String,
  joinDt: _joinDtFromJson(json['joinDt']),
  tagYn: _svYnFromJson(json['svYn']),
  userId: json['userId'] as String? ?? '',
);

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
  'userIdx': instance.no,
  'userName': instance.name,
  'deptNm': instance.department,
  'positionNm': instance.jobTitle,
  'userPhone': instance.mobilePhone,
  'userEmail': instance.email,
  'joinDt': instance.joinDt,
  'userId': instance.userId,
  'svYn': _svYnToJson(instance.tagYn),
};
