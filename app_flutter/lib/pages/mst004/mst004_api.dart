import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/mst004/mst004_model.dart';

class MasterChecklistApiService extends BaseRepository {
  Future<MasterChecklistItem?> createChecklist(
    Map<String, dynamic> data,
  ) async {
    try {
      return await postDataOrNull(
        '/checklists',
        data: data,
        fromJson: MasterChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('Error creating checklist: $e');
    }
    return null;
  }

  Future<MasterChecklistItem?> updateChecklist(
    int chkIdx,
    Map<String, dynamic> data,
  ) async {
    try {
      return await putDataOrNull(
        '/checklists/$chkIdx',
        data: data,
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
        queryParameters['brandCd'] = brandCd;
      }
      if (chkType != null && chkType.isNotEmpty) {
        queryParameters['chkType'] = chkType;
      }

      return await getDataList(
        '/checklists',
        queryParameters: queryParameters,
        fromJson: MasterChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching checklists: $e');
    }
    return [];
  }
}
