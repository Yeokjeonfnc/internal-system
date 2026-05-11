import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/notifications/notif_api_paths.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_payload.dart';

/// 활동 결재 등 [notif_mst] 알림 API.
class NotificationApiService extends BaseRepository {
  Future<List<NotifRow>> list(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      return await getDataList(
        NotifMstApiPaths.root,
        queryParameters: {UserMstWritePayload.jsonKeyUserId: userId},
        fromJson: NotifRow.fromJson,
      );
    } catch (e) {
      debugPrint('알림 목록 로드 실패: $e');
    }
    return const [];
  }

  Future<int> unreadCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final r = await client.get(
        NotifMstApiPaths.unreadCount,
        queryParameters: {UserMstWritePayload.jsonKeyUserId: userId},
      );
      if (r.statusCode != 200 || r.data == null) return 0;
      final n = readEnvelopeData(r.data, (raw) {
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse(raw.toString()) ?? 0;
      });
      return n ?? 0;
    } catch (e) {
      debugPrint('알림 미읽음 수 조회 실패: $e');
    }
    return 0;
  }

  Future<void> markRead(int notifIdx, String userId) async {
    if (userId.isEmpty) return;
    try {
      await client.patch(
        NotifMstApiPaths.read(notifIdx),
        queryParameters: {UserMstWritePayload.jsonKeyUserId: userId},
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
      final response = await client.patch(
        NotifMstApiPaths.activityApproval,
        queryParameters: {
          UserMstWritePayload.jsonKeyUserId: userId,
          NotifMstQueryParamKeys.actIdx: actIdx,
        },
      );
      if (response.statusCode != 200 || response.data == null) {
        return false;
      }
      return envelopeSuccess(response.data);
    } catch (e) {
      debugPrint('결재 확인 반영 실패: $e');
      return false;
    }
  }
}
