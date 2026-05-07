// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mst002_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Department _$DepartmentFromJson(Map<String, dynamic> json) => Department(
  id: _stringAny(_readDeptIdx(json, 'id')),
  name: _stringAny(_readDeptNm(json, 'name')),
  manager: _stringAny(_readManagerNm(json, 'manager')),
  userCount: _intAny(_readUserCount(json, 'userCount')),
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => Department.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  parentId: _nullableString(_readUpperDept(json, 'parentId')),
  level: asJsonIntOpt(_readDeptLevel(json, 'level')),
  sortOrder: asJsonIntOpt(_readSortOrder(json, 'sortOrder')),
);

Map<String, dynamic> _$DepartmentToJson(Department instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'manager': instance.manager,
      'userCount': instance.userCount,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'parentId': instance.parentId,
      'level': instance.level,
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
