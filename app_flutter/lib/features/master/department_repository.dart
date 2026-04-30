// 부서 데이터 Repository.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/features/master/department_model.dart';

class DepartmentRepository {
  final ApiClient _client = ApiClient();

  /// 부서 트리 전체를 반환.
  Future<List<Department>> all() async {
    try {
      final response = await _client.get('/dept/list');
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return [
          for (final row in rows)
            Department.fromJson(row as Map<String, dynamic>),
        ];
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
    return const <Department>[];
  }

  Future<bool> updateSortOrders(List<DepartmentSortOrder> items) async {
    try {
      final response = await _client.put(
        '/dept/sort-order',
        data: {'items': [for (final item in items) item.toJson()]},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating department sort orders: $e');
    }
    return false;
  }
}
