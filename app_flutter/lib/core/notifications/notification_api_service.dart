import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/notifications/notif_api_paths.dart';
import 'package:app_flutter/core/notifications/notif_model.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';

/// 활동 결재 등 [notif_mst] 알림 API.
class NotificationApiService extends BaseRepository {
  Future<List<NotifRow>> list(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      return await getDataList(
        NotifMstApiPaths.root,
        queryParameters: {UserMstWriteRequest.jsonKeyUserId: userId},
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
        queryParameters: {UserMstWriteRequest.jsonKeyUserId: userId},
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
        queryParameters: {UserMstWriteRequest.jsonKeyUserId: userId},
      );
    } catch (e) {
      debugPrint('알림 읽음 처리 실패: $e');
    }
  }

  Future<bool> markAllRead(String userId) async {
    if (userId.isEmpty) return false;
    try {
      final r = await client.patch(
        NotifMstApiPaths.readAll,
        queryParameters: {UserMstWriteRequest.jsonKeyUserId: userId},
      );
      return r.statusCode == 200 && envelopeSuccess(r.data);
    } catch (e) {
      debugPrint('알림 모두 읽음 처리 실패: $e');
      return false;
    }
  }

  /// 활동 결재 화면 [결재하기]: `notif_mst` 대기(N) 건만 Y 로 반영.
  /// [apprNotes] 는 `active_mst.appr_notes` 에 그대로 반영한다(빈 문자열이면 DB NULL).
  /// 실패 시 서버 [ApiResponse.message] 를 [errorMessage] 로 돌려 얼럿에 쓴다.
  Future<({bool ok, String? errorMessage})> acknowledgeActivityApproval({
    required int actIdx,
    required String userId,
    String? apprNotes,
  }) async {
    if (userId.isEmpty) {
      return (ok: false, errorMessage: '로그인 정보가 없습니다.');
    }
    try {
      final qp = <String, dynamic>{
        UserMstWriteRequest.jsonKeyUserId: userId,
        NotifMstQueryParamKeys.actIdx: actIdx,
        NotifMstQueryParamKeys.apprNotes: apprNotes ?? '',
      };
      final response = await client.patch(
        NotifMstApiPaths.activityApproval,
        queryParameters: qp,
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          envelopeSuccess(response.data)) {
        return (ok: true, errorMessage: null);
      }
      final msg = response.data != null
          ? envelopeMessage(response.data)
          : null;
      return (
        ok: false,
        errorMessage: msg ?? '결재 처리에 실패했습니다.',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data != null) {
        final m = envelopeMessage(data);
        if (m != null) {
          return (ok: false, errorMessage: m);
        }
      }
      debugPrint('결재 확인 반영 실패: $e');
      return (ok: false, errorMessage: '결재 처리에 실패했습니다.');
    } catch (e) {
      debugPrint('결재 확인 반영 실패: $e');
      return (ok: false, errorMessage: '결재 처리에 실패했습니다.');
    }
  }
}
