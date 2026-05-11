// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mst002_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Department _$DepartmentFromJson(Map<String, dynamic> json) => Department(
  id: _stringAny(json['deptIdx']),
  name: _stringAny(json['deptNm']),
  manager: _stringAny(json['managerNm']),
  userCount: _intAny(json['userCount']),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => Department.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  parentId: _nullableString(json['upperDeptIdx']),
  level: asJsonIntOpt(json['deptLevel']),
  sortOrder: asJsonIntOpt(json['sortOrder']),
);

Map<String, dynamic> _$DepartmentToJson(Department instance) =>
    <String, dynamic>{
      'deptIdx': instance.id,
      'deptNm': instance.name,
      'managerNm': instance.manager,
      'userCount': instance.userCount,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'upperDeptIdx': instance.parentId,
      'deptLevel': instance.level,
      'sortOrder': instance.sortOrder,
    };

DepartmentSortOrder _$DepartmentSortOrderFromJson(Map<String, dynamic> json) =>
    DepartmentSortOrder(
      deptIdx: (json['deptIdx'] as num).toInt(),
      sortOrder: (json['sortOrder'] as num).toInt(),
      upperDeptIdx: (json['upperDeptIdx'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DepartmentSortOrderToJson(
  DepartmentSortOrder instance,
) => <String, dynamic>{
  'deptIdx': instance.deptIdx,
  'sortOrder': instance.sortOrder,
  'upperDeptIdx': instance.upperDeptIdx,
};
