import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';
import 'package:app_flutter/core/partner_mst/partner_mst_write_request.dart';

/// 예비창업자 API — 백엔드 `DevController` (`/partners`).
class PartnerApiService extends BaseRepository {
  Future<List<Partner>> fetchList() async {
    try {
      return await getDataList(PartnerMstApiPaths.root, fromJson: Partner.fromJson);
    } catch (e) {
      debugPrint('Error fetching partners: $e');
    }
    return const [];
  }

  Future<Partner?> fetchOne(int partnerIdx) async {
    try {
      return await getDataOrNull(
        PartnerMstApiPaths.one(partnerIdx),
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching partner: $e');
    }
    return null;
  }

  Future<Partner?> create(PartnerMstWriteRequest body) async {
    try {
      return await postDataOrNull(
        PartnerMstApiPaths.root,
        data: body.toRequestBody(),
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error creating partner: $e');
    }
    return null;
  }

  Future<Partner?> update(int partnerIdx, PartnerMstWriteRequest body) async {
    try {
      return await putDataOrNull(
        PartnerMstApiPaths.one(partnerIdx),
        data: body.toRequestBody(),
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating partner: $e');
    }
    return null;
  }
}
