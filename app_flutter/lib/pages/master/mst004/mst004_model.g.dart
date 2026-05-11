// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mst004_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasterChecklistItem _$MasterChecklistItemFromJson(Map<String, dynamic> json) =>
    MasterChecklistItem(
      chkIdx: _intAny(json['chkIdx']),
      brandCd: json['brandCd'] as String,
      chkType: json['chkType'] as String,
      chkTypeNm: json['chkTypeNm'] as String,
      chkContent: json['chkContent'] as String,
      baseScore: _intAny(json['baseScore']),
      useYn: json['useYn'] as String,
    );

Map<String, dynamic> _$MasterChecklistItemToJson(
  MasterChecklistItem instance,
) => <String, dynamic>{
  'chkIdx': instance.chkIdx,
  'brandCd': instance.brandCd,
  'chkType': instance.chkType,
  'chkTypeNm': instance.chkTypeNm,
  'chkContent': instance.chkContent,
  'baseScore': instance.baseScore,
  'useYn': instance.useYn,
};
