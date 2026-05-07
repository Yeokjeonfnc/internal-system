// 대시보드 KPI 한 건 JSON 직렬화 모델.

import 'package:json_annotation/json_annotation.dart';

part 'dsh001_kpi_model.g.dart';

@JsonSerializable()
class DashboardKpiModel {
  const DashboardKpiModel({
    required this.label,
    required this.value,
    required this.unit,
    required this.deltaRate,
  });

  final String label;
  final int value;
  final String unit;
  final double deltaRate;

  factory DashboardKpiModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardKpiModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardKpiModelToJson(this);
}
