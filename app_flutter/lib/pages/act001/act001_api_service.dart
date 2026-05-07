import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';

/// `/activities` 계열 — 응답은 `Map<String, dynamic>` (백엔드 조회 Map 직렬화).
class ActivityApiService extends BaseRepository {
  Future<List<Map<String, dynamic>>> getStatusRows({
    required String type,
    required String startDt,
    required String endDt,
    String? brandCd,
    String? userId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'startDt': startDt,
        'endDt': endDt,
      };
      if (brandCd != null && brandCd.isNotEmpty) {
        queryParameters['brandCd'] = brandCd;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParameters['userId'] = userId;
      }
      return await getDataListMap(
        '/activities/status/$type',
        queryParameters: queryParameters,
      );
    } catch (e) {
      debugPrint('Error fetching activity status rows: $e');
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getChecklistActivities() async {
    try {
      return await getDataListMap(
        '/activities',
        queryParameters: const {'chkYn': 'Y'},
      );
    } catch (e) {
      debugPrint('Error fetching checklist activities: $e');
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getActivities({
    String? apprStatus,
    String? svId,
    String? relUserId,
    bool hasSuggestions = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (apprStatus != null && apprStatus.isNotEmpty) {
        queryParameters['apprStatus'] = apprStatus;
      }
      if (svId != null && svId.isNotEmpty) {
        queryParameters['svId'] = svId;
      }
      if (relUserId != null && relUserId.isNotEmpty) {
        queryParameters['relUserId'] = relUserId;
      }
      if (hasSuggestions) {
        queryParameters['hasSuggestions'] = true;
      }
      return await getDataListMap(
        '/activities',
        queryParameters: queryParameters,
      );
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    }
    return const [];
  }

  Future<Map<String, dynamic>?> getActivity(int actIdx) async {
    try {
      return await getDataMapOrNull('/activities/$actIdx');
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createActivity(Map<String, dynamic> data) async {
    try {
      return await postDataMapOrNull('/activities', data: data);
    } catch (e) {
      debugPrint('Error creating activity: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateActivity(
    int actIdx,
    Map<String, dynamic> data,
  ) async {
    try {
      return await putDataMapOrNull('/activities/$actIdx', data: data);
    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
    return null;
  }

  Future<bool> deleteActivity(int actIdx) => deleteOk('/activities/$actIdx');

  Future<List<Map<String, dynamic>>> getChecklistResults(int actIdx) async {
    try {
      return await getDataListMap('/activities/$actIdx/checklist-results');
    } catch (e) {
      debugPrint('Error fetching checklist results: $e');
    }
    return const [];
  }
}
