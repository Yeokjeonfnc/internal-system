import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';

/// 활동 결재 등 [notif_mst] 알림 API.
class NotificationApiService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> list(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final response = await _client.get(
        '/notifications',
        queryParameters: {'userId': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('알림 목록 로드 실패: $e');
    }
    return [];
  }

  Future<int> unreadCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final response = await _client.get(
        '/notifications/unread-count',
        queryParameters: {'userId': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final raw = body['data'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
      }
    } catch (e) {
      debugPrint('알림 미읽음 수 조회 실패: $e');
    }
    return 0;
  }

  Future<void> markRead(int notifIdx, String userId) async {
    if (userId.isEmpty) return;
    try {
      await _client.patch(
        '/notifications/$notifIdx/read',
        queryParameters: {'userId': userId},
      );
    } catch (e) {
      debugPrint('알림 읽음 처리 실패: $e');
    }
  }

  /// 활동 결재 화면 [결재하기]: 해당 활동 알림의 appr_yn 을 Y 로 반영.
  Future<bool> acknowledgeActivityApproval({
    required int actIdx,
    required String userId,
  }) async {
    if (userId.isEmpty) return false;
    try {
      final response = await _client.patch(
        '/notifications/activity-approval',
        queryParameters: {'userId': userId, 'actIdx': actIdx},
      );
      if (response.statusCode != 200 || response.data == null) {
        return false;
      }
      final raw = response.data;
      if (raw is! Map) {
        return false;
      }
      final body = Map<String, dynamic>.from(raw);
      final ok = body['success'];
      return ok == true;
    } catch (e) {
      debugPrint('결재 확인 반영 실패: $e');
      return false;
    }
  }
}
