// 부서 데이터 Repository.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/dept/dept_sort_order_write_payload.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';

class DepartmentRepository extends BaseRepository {
  /// 부서 트리 전체를 반환.
  Future<List<Department>> all() async {
    try {
      return await getDataList(DeptMstApiPaths.list, fromJson: Department.fromJson);
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
    return const <Department>[];
  }

  Future<bool> updateSortOrders(List<DepartmentSortOrder> items) async {
    try {
      final body = DeptSortOrderUpdatePayload.fromItemMaps(
        items.map((e) => e.toJson()),
      );
      final response = await client.put(
        DeptMstApiPaths.sortOrder,
        data: body.toRequestBody(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating department sort orders: $e');
    }
    return false;
  }
}
