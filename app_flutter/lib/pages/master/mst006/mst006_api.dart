import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/owner_user/owner_user_write_request.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';

class Mst006ApiService extends BaseRepository {
  Future<List<OwnerUser>> getOwners() async {
    try {
      final r = await client.get(OwnerUserApiPaths.root);
      if (r.statusCode != 200 || r.data == null) {
        debugPrint('getOwners HTTP ${r.statusCode}');
        return const [];
      }
      return parseDataList(r.data, OwnerUser.fromJson);
    } catch (e, st) {
      if (e is DioException && ApiReachability.isUnreachable(e)) {
        debugPrint('getOwners failed: backend unreachable');
      } else {
        debugPrint('getOwners failed: $e\n$st');
      }
      rethrow;
    }
  }

  Future<OwnerUser> getOwner(int userIdx) =>
      getData(OwnerUserApiPaths.one(userIdx), fromJson: OwnerUser.fromJson);

  Future<OwnerUser> createOwner(OwnerUserWriteRequest body) => postData(
        OwnerUserApiPaths.root,
        data: body.toRequestBody(),
        fromJson: OwnerUser.fromJson,
      );

  Future<OwnerUser> updateOwner(int userIdx, OwnerUserWriteRequest body) =>
      putData(
        OwnerUserApiPaths.one(userIdx),
        data: body.toRequestBody(),
        fromJson: OwnerUser.fromJson,
      );

  Future<void> deleteOwner(int userIdx) async {
    await client.delete(OwnerUserApiPaths.one(userIdx));
  }
}
