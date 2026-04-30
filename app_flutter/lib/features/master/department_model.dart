// 부서 모델 — 트리 구조를 지원한다.

/// 부서 정보.
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

  final String id;
  final String name;
  final String manager;
  final int userCount;
  final List<Department> children;
  final String? parentId;
  final int? level;
  final int? sortOrder;

  /// 이 부서가 자식을 가지고 있는지.
  bool get hasChildren => children.isNotEmpty;

  factory Department.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    final parent = json['upperDeptIdx'] ?? json['upper_dept_idx'];
    return Department(
      id: (json['deptIdx'] ?? json['dept_idx'] ?? '').toString(),
      name: (json['deptNm'] ?? json['dept_nm'] ?? '').toString(),
      manager: (json['managerNm'] ?? json['manager_nm'] ?? '').toString(),
      userCount: _intValue(json['userCount'] ?? json['user_count']),
      parentId: parent?.toString(),
      level: _nullableInt(json['deptLevel'] ?? json['dept_level']),
      sortOrder: _nullableInt(json['sortOrder'] ?? json['sort_order']),
      children: [
        for (final child in rawChildren)
          Department.fromJson(child as Map<String, dynamic>),
      ],
    );
  }

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

class DepartmentSortOrder {
  const DepartmentSortOrder({
    required this.deptIdx,
    required this.sortOrder,
    this.upperDeptIdx,
  });

  final int deptIdx;
  final int sortOrder;
  final int? upperDeptIdx;

  Map<String, dynamic> toJson() => {
    'deptIdx': deptIdx,
    'upperDeptIdx': upperDeptIdx,
    'sortOrder': sortOrder,
  };
}

int _intValue(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
