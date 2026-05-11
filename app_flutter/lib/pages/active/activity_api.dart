import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/checklist/chk_mst_write_payload.dart';
import 'package:app_flutter/pages/active/activity_model.dart';
import 'package:app_flutter/pages/active/activity_model_checklist.dart';

/// `/activities` 계열 — 목록 [ActivityRow], 현황 [ActivityStatusPivotRow], 단건 [ActivityDetail], 저장 [ActivityWritePayload]/[ActivitySaveResult].
class ActivityApiService extends BaseRepository {
  /// 현황 화면용 `/activities/status/{type}`.
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

  /// 임시보관(작성 중) — `apprStatus=DRAFT`, 선택적 작성자 `svId`.
  Future<List<ActivityRow>> fetchDraftRows({String? svId}) => fetchList(
        apprStatus: ActiveMstListApprStatus.draft,
        svId: svId,
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

  /// 건의사항이 있는 행만.
  Future<List<ActivityRow>> fetchRowsWithSuggestions() =>
      fetchList(hasSuggestions: true);

  /// 지시사항 탭: SV별 결재 메모(`hasApprNote`) 목록.
  Future<List<ActivityRow>> fetchRowsForSvWithApprNote(String svId) =>
      fetchList(svId: svId, hasApprNote: true);

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

  Future<ActivitySaveResult?> create(ActivityWritePayload payload) async {
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
    ActivityWritePayload payload,
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
        queryParameters: {ChkMstWritePayload.jsonKeyBrandCd: brandCd},
        fromJson: ChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('체크리스트 조회 에러: $e');
    }
    return const [];
  }
}
