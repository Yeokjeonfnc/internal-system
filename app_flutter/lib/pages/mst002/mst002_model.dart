// 부서 모델 — 트리 구조를 지원한다.

import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';

part 'mst002_model.g.dart';

Object? _readDeptIdx(Object? json, String key) {
  final m = json as Map;
  return m['deptIdx'] ?? m['dept_idx'];
}

Object? _readDeptNm(Object? json, String key) {
  final m = json as Map;
  return m['deptNm'] ?? m['dept_nm'];
}

Object? _readManagerNm(Object? json, String key) {
  final m = json as Map;
  return m['managerNm'] ?? m['manager_nm'];
}

Object? _readUserCount(Object? json, String key) {
  final m = json as Map;
  return m['userCount'] ?? m['user_count'];
}

Object? _readUpperDept(Object? json, String key) {
  final m = json as Map;
  return m['upperDeptIdx'] ?? m['upper_dept_idx'];
}

Object? _readDeptLevel(Object? json, String key) {
  final m = json as Map;
  return m['deptLevel'] ?? m['dept_level'];
}

Object? _readSortOrder(Object? json, String key) {
  final m = json as Map;
  return m['sortOrder'] ?? m['sort_order'];
}

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

  @JsonKey(readValue: _readDeptIdx, fromJson: _stringAny)
  final String id;

  @JsonKey(readValue: _readDeptNm, fromJson: _stringAny)
  final String name;

  @JsonKey(readValue: _readManagerNm, fromJson: _stringAny)
  final String manager;

  @JsonKey(readValue: _readUserCount, fromJson: _intAny)
  final int userCount;

  @JsonKey(defaultValue: <Department>[])
  final List<Department> children;

  @JsonKey(readValue: _readUpperDept, fromJson: _nullableString)
  final String? parentId;

  @JsonKey(readValue: _readDeptLevel, fromJson: asJsonIntOpt)
  final int? level;

  @JsonKey(readValue: _readSortOrder, fromJson: asJsonIntOpt)
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

  final int deptIdx;
  final int sortOrder;
  final int? upperDeptIdx;

  factory DepartmentSortOrder.fromJson(Map<String, dynamic> json) =>
      _$DepartmentSortOrderFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentSortOrderToJson(this);
}
