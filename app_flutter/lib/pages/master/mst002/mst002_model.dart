// 부서 모델 — 트리 구조를 지원한다.

import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/dept/dept_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

part 'mst002_model.g.dart';

String _stringAny(Object? e) => e?.toString() ?? '';

/// 부서 정보.
@JsonSerializable(explicitToJson: true)
class Department {
  const Department({
    required this.id,
    required this.name,
    required this.manager,
    required this.userCount,
    this.children = const [],
    this.parentId,
    this.level,
    this.sortOrder,
  });

  @JsonKey(name: DeptMstApiJsonKeys.deptIdx, fromJson: _stringAny)
  final String id;

  @JsonKey(name: DeptMstApiJsonKeys.deptNm, fromJson: _stringAny)
  final String name;

  @JsonKey(name: DeptMstApiJsonKeys.managerNm, fromJson: _stringAny)
  final String manager;

  @JsonKey(name: DeptMstApiJsonKeys.userCount, fromJson: _intAny)
  final int userCount;

  @JsonKey(name: DeptMstApiJsonKeys.children, defaultValue: <Department>[])
  final List<Department> children;

  @JsonKey(name: DeptMstApiJsonKeys.upperDeptIdx, fromJson: _nullableString)
  final String? parentId;

  @JsonKey(name: DeptMstApiJsonKeys.deptLevel, fromJson: asJsonIntOpt)
  final int? level;

  @JsonKey(name: DeptMstApiJsonKeys.sortOrder, fromJson: asJsonIntOpt)
  final int? sortOrder;

  /// 이 부서가 자식을 가지고 있는지.
  bool get hasChildren => children.isNotEmpty;

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentToJson(this);

  Department copyWith({
    String? id,
    String? name,
    String? manager,
    int? userCount,
    List<Department>? children,
    String? parentId,
    int? level,
    int? sortOrder,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      manager: manager ?? this.manager,
      userCount: userCount ?? this.userCount,
      children: children ?? this.children,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

int _intAny(Object? e) => e.asJsonInt();

String? _nullableString(Object? e) {
  final s = e?.toString();
  if (s == null || s.isEmpty) return null;
  return s;
}

@JsonSerializable()
class DepartmentSortOrder {
  const DepartmentSortOrder({
    required this.deptIdx,
    required this.sortOrder,
    this.upperDeptIdx,
  });

  @JsonKey(name: DeptMstApiJsonKeys.deptIdx)
  final int deptIdx;

  @JsonKey(name: DeptMstApiJsonKeys.sortOrder)
  final int sortOrder;

  @JsonKey(name: DeptMstApiJsonKeys.upperDeptIdx)
  final int? upperDeptIdx;

  factory DepartmentSortOrder.fromJson(Map<String, dynamic> json) =>
      _$DepartmentSortOrderFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentSortOrderToJson(this);
}
