// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act001_model_checklist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    ChecklistItem(
      chkIdx: _intAny(json['chkIdx']),
      brandCd: json['brandCd'] as String,
      chkType: json['chkType'] as String,
      chkTypeNm: json['chkTypeNm'] as String,
      chkContent: json['chkContent'] as String,
      baseScore: asJsonIntOpt(json['baseScore']),
      displayOrder: asJsonIntOpt(json['displayOrder']),
    );

Map<String, dynamic> _$ChecklistItemToJson(ChecklistItem instance) =>
    <String, dynamic>{
      'chkIdx': instance.chkIdx,
      'brandCd': instance.brandCd,
      'chkType': instance.chkType,
      'chkTypeNm': instance.chkTypeNm,
      'chkContent': instance.chkContent,
      'baseScore': instance.baseScore,
      'displayOrder': instance.displayOrder,
    };
