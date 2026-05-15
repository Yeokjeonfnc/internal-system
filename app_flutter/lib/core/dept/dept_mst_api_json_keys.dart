/// `dept_mst` 트리 노드 — 백엔드 `DeptMstNodeDto` JSON 키와 동일.
///
/// `DeptSortItemDto`·`DeptSortOrderUpdateRequest` 항목 키(`deptIdx` 등)와 이름이 겹치면 이 상수를 재사용한다.
abstract final class DeptMstApiJsonKeys {
  static const String deptIdx = 'deptIdx';
  static const String upperDeptIdx = 'upperDeptIdx';
  static const String deptNm = 'deptNm';
  static const String deptLevel = 'deptLevel';
  static const String sortOrder = 'sortOrder';
  static const String managerNm = 'managerNm';
  static const String userCount = 'userCount';
  static const String children = 'children';
}
