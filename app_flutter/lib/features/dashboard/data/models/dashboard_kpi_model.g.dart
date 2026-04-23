// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_kpi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardKpiModel _$DashboardKpiModelFromJson(Map<String, dynamic> json) =>
    DashboardKpiModel(
      label: json['label'] as String,
      value: (json['value'] as num).toInt(),
      unit: json['unit'] as String,
      deltaRate: (json['deltaRate'] as num).toDouble(),
    );

Map<String, dynamic> _$DashboardKpiModelToJson(DashboardKpiModel instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'unit': instance.unit,
      'deltaRate': instance.deltaRate,
    };
