import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_paths.dart';
import 'package:app_flutter/pages/active/act001/act001_model.dart';

/// 활동 현황(act001) — `/activities/status/{type}`.
class Act001Api extends BaseRepository {
  Future<List<ActivityStatusPivotRow>> fetchStatus({
    required String type,
    required String startDt,
    required String endDt,
    String? brandCd,
    String? userId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        ActiveMstQueryParamKeys.startDt: startDt,
        ActiveMstQueryParamKeys.endDt: endDt,
      };
      if (brandCd != null && brandCd.isNotEmpty) {
        queryParameters[ActiveMstApiJsonKeys.brandCd] = brandCd;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParameters[ActiveMstApiJsonKeys.userId] = userId;
      }
      final maps = await getDataListMap(
        '${ActiveMstApiPaths.root}/status/$type',
        queryParameters: queryParameters,
      );
      return maps.map(ActivityStatusPivotRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching activity status rows: $e');
    }
    return const [];
  }
}
