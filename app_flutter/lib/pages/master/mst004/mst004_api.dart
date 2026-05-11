import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/checklist/chk_mst_write_payload.dart';
import 'package:app_flutter/pages/master/mst004/mst004_model.dart';

class MasterChecklistApiService extends BaseRepository {
  Future<MasterChecklistItem?> createChecklist(ChkMstWritePayload body) async {
    try {
      return await postDataOrNull(
        ChkMstApiPaths.root,
        data: body.toRequestBody(),
        fromJson: MasterChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('Error creating checklist: $e');
    }
    return null;
  }

  Future<MasterChecklistItem?> updateChecklist(
    int chkIdx,
    ChkMstWritePayload body,
  ) async {
    try {
      return await putDataOrNull(
        ChkMstApiPaths.one(chkIdx),
        data: body.toRequestBody(),
        fromJson: MasterChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating checklist: $e');
    }
    return null;
  }

  Future<List<MasterChecklistItem>> getChecklists({
    String? brandCd,
    String? chkType,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (brandCd != null && brandCd.isNotEmpty) {
        queryParameters[ChkMstWritePayload.jsonKeyBrandCd] = brandCd;
      }
      if (chkType != null && chkType.isNotEmpty) {
        queryParameters[ChkMstWritePayload.jsonKeyChkType] = chkType;
      }

      return await getDataList(
        ChkMstApiPaths.root,
        queryParameters: queryParameters,
        fromJson: MasterChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching checklists: $e');
    }
    return [];
  }
}
