// 사원(mst001) API.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/user_mst/user_id_availability.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

class Mst001ApiService extends BaseRepository {
  Future<List<User>> getUsers({int? deptIdx}) async {
    final qp = deptIdx != null
        ? <String, dynamic>{UserMstWriteRequest.jsonKeyDeptIdx: deptIdx}
        : null;
    try {
      final r = await client.get(UserMstApiPaths.root, queryParameters: qp);
      if (r.statusCode != 200 || r.data == null) {
        debugPrint('getUsers HTTP ${r.statusCode}');
        return const [];
      }
      final root = parseEnvelopeRoot(r.data);
      if (root == null) {
        debugPrint('getUsers: invalid envelope');
        return const [];
      }
      final data = root['data'];
      if (data is! List) {
        debugPrint('getUsers: data is not a list (${data.runtimeType})');
        return const [];
      }
      final users = <User>[];
      var skipped = 0;
      for (final raw in data) {
        if (raw is! Map) continue;
        try {
          users.add(User.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e, st) {
          skipped++;
          debugPrint('getUsers row parse skip: $e\n$raw\n$st');
        }
      }
      if (skipped > 0) {
        debugPrint('getUsers: parsed ${users.length}, skipped $skipped');
      }
      return users;
    } catch (e, st) {
      debugPrint('getUsers failed: $e\n$st');
      rethrow;
    }
  }

  Future<User> getUser(int userIdx) =>
      getData(UserMstApiPaths.one(userIdx), fromJson: User.fromJson);

  /// 로그인 ID 사용 가능 여부. [true] 이면 중복 없음(등록 가능).
  Future<bool> isUserIdAvailable(String userId) async {
    final v = await getDataOrNull(
      UserMstApiPaths.checkUserId,
      queryParameters: {UserMstWriteRequest.jsonKeyUserId: userId},
      fromJson: UserIdAvailability.fromJson,
    );
    return v?.available ?? false;
  }

  Future<User> createUser(UserMstWriteRequest body) =>
      postData(UserMstApiPaths.root, data: body.toRequestBody(), fromJson: User.fromJson);

  Future<User> updateUser(int userIdx, UserMstWriteRequest body) =>
      putData(UserMstApiPaths.one(userIdx), data: body.toRequestBody(), fromJson: User.fromJson);

  Future<void> deleteUser(int userIdx) async {
    await client.delete(UserMstApiPaths.one(userIdx));
  }
}
