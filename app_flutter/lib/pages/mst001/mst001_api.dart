// 사원(mst001) API.

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/mst001/mst001_model.dart';

class Emp001ApiService extends BaseRepository {
  Future<List<Employee>> getUsers({int? deptIdx}) async {
    final uri = deptIdx != null ? '/users?deptIdx=$deptIdx' : '/users';
    return getDataList(uri, fromJson: Employee.fromJson);
  }

  Future<Employee> getUser(int userIdx) =>
      getData('/users/$userIdx', fromJson: Employee.fromJson);

  /// 로그인 ID 사용 가능 여부. [true] 이면 중복 없음(등록 가능).
  Future<bool> isUserIdAvailable(String userId) async {
    final r = await client.get(
      '/users/check-user-id',
      queryParameters: {'userId': userId},
    );
    if (r.statusCode != 200 || r.data == null) return false;
    final body = responseMap(r);
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data['available'] as bool? ?? false;
    }
    return false;
  }

  Future<Employee> createUser(Map<String, dynamic> userData) =>
      postData('/users', data: userData, fromJson: Employee.fromJson);

  Future<Employee> updateUser(int userIdx, Map<String, dynamic> userData) =>
      putData('/users/$userIdx', data: userData, fromJson: Employee.fromJson);

  Future<void> deleteUser(int userIdx) async {
    await client.delete('/users/$userIdx');
  }
}
