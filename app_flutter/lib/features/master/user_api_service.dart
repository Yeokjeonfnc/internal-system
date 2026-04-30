// 사용자 API 서비스.

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/features/master/employee_model.dart';

class UserApiService {
  final ApiClient _client = ApiClient();

  Future<List<Employee>> getUsers({int? deptIdx}) async {
    final uri = deptIdx != null ? '/users?deptIdx=$deptIdx' : '/users';
    final response = await _client.get(uri);
    final data = response.data['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((json) => Employee.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Employee> getUser(int userIdx) async {
    final response = await _client.get('/users/$userIdx');
    return Employee.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Employee> createUser(Map<String, dynamic> userData) async {
    final response = await _client.post('/users', data: userData);
    return Employee.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Employee> updateUser(int userIdx, Map<String, dynamic> userData) async {
    final response = await _client.put('/users/$userIdx', data: userData);
    return Employee.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(int userIdx) async {
    await _client.delete('/users/$userIdx');
  }
}
