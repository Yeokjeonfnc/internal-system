// 사원(mst001) API.

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/user_mst/user_id_availability.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_payload.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

class Mst001ApiService extends BaseRepository {
  Future<List<User>> getUsers({int? deptIdx}) async {
    final qp = deptIdx != null
        ? <String, dynamic>{UserMstWritePayload.jsonKeyDeptIdx: deptIdx}
        : null;
    return getDataList(
      UserMstApiPaths.root,
      queryParameters: qp,
      fromJson: User.fromJson,
    );
  }

  Future<User> getUser(int userIdx) =>
      getData(UserMstApiPaths.one(userIdx), fromJson: User.fromJson);

  /// 로그인 ID 사용 가능 여부. [true] 이면 중복 없음(등록 가능).
  Future<bool> isUserIdAvailable(String userId) async {
    final v = await getDataOrNull(
      UserMstApiPaths.checkUserId,
      queryParameters: {UserMstWritePayload.jsonKeyUserId: userId},
      fromJson: UserIdAvailability.fromJson,
    );
    return v?.available ?? false;
  }

  Future<User> createUser(UserMstWritePayload body) =>
      postData(UserMstApiPaths.root, data: body.toRequestBody(), fromJson: User.fromJson);

  Future<User> updateUser(int userIdx, UserMstWritePayload body) =>
      putData(UserMstApiPaths.one(userIdx), data: body.toRequestBody(), fromJson: User.fromJson);

  Future<void> deleteUser(int userIdx) async {
    await client.delete(UserMstApiPaths.one(userIdx));
  }
}
