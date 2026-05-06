import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';

class ActivityApiService {
  final ApiClient _client = ApiClient();

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
      final response = await _client.get(
        '/activities/status/$type',
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching activity status rows: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getChecklistActivities() async {
    try {
      final response = await _client.get(
        '/activities',
        queryParameters: {'chkYn': 'Y'},
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching checklist activities: $e');
    }
    return [];
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
      final response = await _client.get(
        '/activities',
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getActivity(int actIdx) async {
    try {
      final response = await _client.get('/activities/$actIdx');
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> createActivity(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.post('/activities', data: data);
      if (response.statusCode == 201 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
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
      final response = await _client.put('/activities/$actIdx', data: data);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
    return null;
  }

  Future<bool> deleteActivity(int actIdx) async {
    try {
      final response = await _client.delete('/activities/$actIdx');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getChecklistResults(int actIdx) async {
    try {
      final response = await _client.get(
        '/activities/$actIdx/checklist-results',
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching checklist results: $e');
    }
    return [];
  }
}
