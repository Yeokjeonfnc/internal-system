// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notif_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifRow _$NotifRowFromJson(Map<String, dynamic> json) => NotifRow(
  notifIdx: asJsonIntOpt(json['notifIdx']),
  userId: json['userId'] == null ? '' : _str(json['userId']),
  msgTxt: json['msgTxt'] == null ? '' : _str(json['msgTxt']),
  notifTyp: json['notifTyp'] == null ? '' : _str(json['notifTyp']),
  actIdx: asJsonIntOpt(json['actIdx']),
  apprYn: json['apprYn'] == null ? '' : _str(json['apprYn']),
  readYn: json['readYn'] == null ? '' : _str(json['readYn']),
  creatDt: json['creatDt'] == null ? '' : _str(json['creatDt']),
);

Map<String, dynamic> _$NotifRowToJson(NotifRow instance) => <String, dynamic>{
  'notifIdx': instance.notifIdx,
  'userId': instance.userId,
  'msgTxt': instance.msgTxt,
  'notifTyp': instance.notifTyp,
  'actIdx': instance.actIdx,
  'apprYn': instance.apprYn,
  'readYn': instance.readYn,
  'creatDt': instance.creatDt,
};
