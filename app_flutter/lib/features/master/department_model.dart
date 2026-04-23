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
  });

  final String id;
  final String name;
  final String manager;
  final int userCount;
  final List<Department> children;
  final String? parentId;

  /// 이 부서가 자식을 가지고 있는지.
  bool get hasChildren => children.isNotEmpty;
}
