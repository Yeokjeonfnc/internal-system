import 'package:app_flutter/core/dept/dept_mst_api_json_keys.dart';

/// `PUT /dept/sort-order` 요청 본문 — 백엔드 `DeptSortOrderUpdateRequestDto`.
///
/// `items` 원소는 `DeptSortItemDto` 키와 맞춘다(`DeptMstApiJsonKeys`).
class DeptSortOrderUpdatePayload {
  static const String jsonKeyItems = 'items';
  static const String jsonKeyDeptIdx = DeptMstApiJsonKeys.deptIdx;
  static const String jsonKeyUpperDeptIdx = DeptMstApiJsonKeys.upperDeptIdx;
  static const String jsonKeySortOrder = DeptMstApiJsonKeys.sortOrder;

  DeptSortOrderUpdatePayload._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory DeptSortOrderUpdatePayload.fromItemMaps(
    Iterable<Map<String, dynamic>> items,
  ) => DeptSortOrderUpdatePayload._({
    jsonKeyItems: [for (final item in items) Map<String, dynamic>.from(item)],
  });
}

/// 부서 REST 경로 — 백엔드 `MstController` (`/dept/*`).
abstract final class DeptMstApiPaths {
  static const String list = '/dept/list';

  static const String sortOrder = '/dept/sort-order';
}
