import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_paths.dart';
import 'package:app_flutter/core/active_mst/active_mst_write_request.dart';
import 'package:app_flutter/core/checklist/chk_mst_write_request.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/act002/act002_model_checklist.dart';

/// 활동 관리(act002) — `/activities` 목록·단건·저장·체크리스트.
class Act002Api extends BaseRepository {
  /// 체크리스트 탭 — `chkYn=Y` 목록.
  Future<List<ActivityRow>> fetchChkActs() async {
    try {
      final maps = await getDataListMap(
        ActiveMstApiPaths.listByCheck,
        queryParameters: const {ActiveMstApiJsonKeys.chkYn: 'Y'},
      );
      return maps.map(ActivityRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching checklist activities: $e');
    }
    return const [];
  }

  /// `GET /activities/list/*` — [ActController] 분기와 동일 순서.
  Future<List<ActivityRow>> fetchList({
    String? apprStatus,
    String? svId,
    String? relUserId,
    int? storeIdx,
    bool hasSuggestions = false,
    bool hasApprNote = false,
  }) async {
    try {
      final String path;
      final Map<String, dynamic> queryParameters;

      if (storeIdx != null) {
        path = ActiveMstApiPaths.listByStore;
        queryParameters = {ActiveMstApiJsonKeys.storeIdx: storeIdx};
      } else if (hasApprNote) {
        path = ActiveMstApiPaths.listByApprNote;
        queryParameters = <String, dynamic>{};
        if (svId != null && svId.isNotEmpty) {
          queryParameters[ActiveMstApiJsonKeys.svId] = svId;
        }
      } else if (hasSuggestions) {
        path = ActiveMstApiPaths.listBySuggestions;
        queryParameters = const {};
      } else if (apprStatus != null && apprStatus.isNotEmpty) {
        path = ActiveMstApiPaths.listByStatus;
        queryParameters = {
          ActiveMstApiJsonKeys.apprStatus: apprStatus,
          if (svId != null && svId.isNotEmpty)
            ActiveMstApiJsonKeys.svId: svId,
          if (relUserId != null && relUserId.isNotEmpty)
            ActiveMstQueryParamKeys.relUserId: relUserId,
        };
      } else {
        path = ActiveMstApiPaths.listAll;
        queryParameters = const {};
      }

      final maps = await getDataListMap(path, queryParameters: queryParameters);
      return maps.map(ActivityRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    }
    return const [];
  }

  /// 임시보관(작성 중) — `apprStatus=DRAFT`, 작성자는 `sv_id`와 동일한 로그인 `user_id`.
  /// 백엔드는 `svId` 우선, 없으면 `relUserId`로 작성자 필터를 적용한다.
  Future<List<ActivityRow>> fetchDraftRows({String? svId}) => fetchList(
        apprStatus: ActiveMstListApprStatus.draft,
        svId: svId,
        relUserId: svId,
      );

  /// 활동관리결재 「전체」.
  Future<List<ActivityRow>> fetchAllRows() => fetchList();

  /// 결재대기 — `PENDING`, 연관 사용자 `relUserId`.
  Future<List<ActivityRow>> fetchPendingRowsForRelUser(String? relUserId) =>
      fetchList(
        apprStatus: ActiveMstListApprStatus.pending,
        relUserId: relUserId,
      );

  /// 결재완료 — `APPROVED`, 연관 사용자 `relUserId`.
  Future<List<ActivityRow>> fetchApprovedRowsForRelUser(String? relUserId) =>
      fetchList(
        apprStatus: ActiveMstListApprStatus.approved,
        relUserId: relUserId,
      );

  /// 결재대기 + 결재완료 — 대시보드 등. `act_dt` 내림차순.
  Future<List<ActivityRow>> fetchPendingAndApprovedRowsForRelUser(
    String? relUserId,
  ) async {
    final results = await Future.wait([
      fetchPendingRowsForRelUser(relUserId),
      fetchApprovedRowsForRelUser(relUserId),
    ]);
    final merged = <int, ActivityRow>{};
    for (final row in [...results[0], ...results[1]]) {
      final id = row.actIdx;
      if (id != null) {
        merged[id] = row;
      }
    }
    final rows = merged.values.toList();
    rows.sort((a, b) => _activityRowDateDesc(a, b));
    return rows;
  }

  static int _activityRowDateDesc(ActivityRow a, ActivityRow b) {
    final da = a.actDt.trim();
    final db = b.actDt.trim();
    final c = db.compareTo(da);
    if (c != 0) return c;
    return (b.actIdx ?? 0).compareTo(a.actIdx ?? 0);
  }

  /// 건의사항이 있는 행만.
  Future<List<ActivityRow>> fetchRowsWithSuggestions() =>
      fetchList(hasSuggestions: true);

  /// 지시사항 탭(활동관리): `appr_notes`·비`PENDING`·`sv_id` = [svId].
  Future<List<ActivityRow>> fetchRowsForSvWithApprNote(String svId) =>
      fetchList(svId: svId, hasApprNote: true);

  /// 지시사항 탭(활동관리결재): `appr_notes`·비`PENDING`·`notif_mst`·`appr_id` 결재선.
  Future<List<ActivityRow>> fetchRowsForApproverMemoInstructions(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final maps = await getDataListMap(
        ActiveMstApiPaths.listByMemoNotifForApprover,
        queryParameters: {ActiveMstApiJsonKeys.userId: userId},
      );
      return maps.map(ActivityRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching approver memo instructions: $e');
    }
    return const [];
  }

  /// 가맹점별 `DRAFT` 후보(등록 화면 중복 임시저장 방지).
  Future<List<ActivityRow>> fetchDraftRowsForStore(int storeIdx) => fetchList(
        apprStatus: ActiveMstListApprStatus.draft,
        storeIdx: storeIdx,
      );

  /// 방문 이력 다이얼로그 — 가맹점 + `apprStatus` CSV.
  Future<List<ActivityRow>> fetchRowsForStoreHistory({
    required int storeIdx,
    required String apprStatusCsv,
  }) =>
      fetchList(storeIdx: storeIdx, apprStatus: apprStatusCsv);

  Future<ActivityDetail?> fetchOne(int actIdx) async {
    try {
      final m = await getDataMapOrNull('${ActiveMstApiPaths.root}/$actIdx');
      if (m == null) return null;
      return ActivityDetail.fromJson(m);
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
    return null;
  }

  Future<ActivitySaveResult?> create(ActivityWriteRequest payload) async {
    try {
      final m = await postDataMapOrNull(
        ActiveMstApiPaths.root,
        data: payload.toJson(),
      );
      if (m == null) return null;
      return ActivitySaveResult.fromJson(m);
    } catch (e) {
      debugPrint('Error creating activity: $e');
    }
    return null;
  }

  Future<ActivitySaveResult?> update(
    int actIdx,
    ActivityWriteRequest payload,
  ) async {
    try {
      final m = await putDataMapOrNull(
        '${ActiveMstApiPaths.root}/$actIdx',
        data: payload.toJson(),
      );
      if (m == null) return null;
      return ActivitySaveResult.fromJson(m);
    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
    return null;
  }

  Future<bool> deleteOne(int actIdx) =>
      deleteOk('${ActiveMstApiPaths.root}/$actIdx');

  Future<List<ChkResultRow>> chkResults(int actIdx) async {
    try {
      final maps = await getDataListMap(
        '${ActiveMstApiPaths.root}/$actIdx/checklist-results',
      );
      return maps.map(ChkResultRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching checklist results: $e');
    }
    return const [];
  }

  /// 등록 화면 — 브랜드별 체크리스트 마스터 `GET /checklists` (`ChkMstApiPaths`).
  Future<List<ChecklistItem>> fetchChecklistMastersByBrand(String brandCd) async {
    try {
      return await getDataList(
        ChkMstApiPaths.root,
        queryParameters: {ChkMstWriteRequest.jsonKeyBrandCd: brandCd},
        fromJson: ChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('체크리스트 조회 에러: $e');
    }
    return const [];
  }
}
