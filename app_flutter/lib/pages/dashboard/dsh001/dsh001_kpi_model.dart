// 대시보드 KPI 한 건 JSON 직렬화 모델.

import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/pages/dashboard/dsh001/dsh001_kpi_json_keys.dart';

part 'dsh001_kpi_model.g.dart';

@JsonSerializable()
class DashboardKpiModel {
  const DashboardKpiModel({
    required this.label,
    required this.value,
    required this.unit,
    required this.deltaRate,
  });

  @JsonKey(name: DashboardKpiJsonKeys.label)
  final String label;

  @JsonKey(name: DashboardKpiJsonKeys.value)
  final int value;

  @JsonKey(name: DashboardKpiJsonKeys.unit)
  final String unit;

  @JsonKey(name: DashboardKpiJsonKeys.deltaRate)
  final double deltaRate;

  factory DashboardKpiModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardKpiModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardKpiModelToJson(this);
}
