import 'package:app_flutter/core/activity_plan/activity_plan_api_json_keys.dart';
import 'package:app_flutter/core/activity_plan/activity_plan_api_paths.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';

class Act004Api extends BaseRepository {
  Future<Act004CalendarContext?> fetchCalendarContext(int viewerUserIdx) {
    return getDataOrNull(
      ActivityPlanApiPaths.calendarContext,
      queryParameters: {
        ActivityPlanApiJsonKeys.viewerUserIdx: viewerUserIdx,
      },
      fromJson: Act004CalendarContext.fromJson,
    );
  }

  Future<Act004MonthResponse> fetchMonthPlans({
    required int viewerUserIdx,
    required int year,
    required int month,
    List<int>? assigneeUserIdxs,
  }) async {
    final params = <String, dynamic>{
      ActivityPlanApiJsonKeys.viewerUserIdx: viewerUserIdx,
      ActivityPlanApiJsonKeys.year: year,
      ActivityPlanApiJsonKeys.month: month,
    };
    if (assigneeUserIdxs != null && assigneeUserIdxs.isNotEmpty) {
      params[ActivityPlanApiJsonKeys.assigneeUserIdxs] = assigneeUserIdxs;
    }
    final data = await getDataOrNull(
      ActivityPlanApiPaths.month,
      queryParameters: params,
      fromJson: Act004MonthResponse.fromJson,
    );
    return data ?? const Act004MonthResponse();
  }

  Future<Act004DayDetail?> fetchDayDetail({
    required int viewerUserIdx,
    required int assigneeUserIdx,
    required DateTime planDate,
  }) {
    return getDataOrNull(
      ActivityPlanApiPaths.day,
      queryParameters: {
        ActivityPlanApiJsonKeys.viewerUserIdx: viewerUserIdx,
        ActivityPlanApiJsonKeys.assigneeUserIdx: assigneeUserIdx,
        ActivityPlanApiJsonKeys.planDate: _formatDate(planDate),
      },
      fromJson: Act004DayDetail.fromJson,
    );
  }

  Future<bool> saveDayStores({
    required int viewerUserIdx,
    required String createdBy,
    required ActivityPlanDaySaveBody body,
  }) async {
    try {
      final r = await client.put(
        ActivityPlanApiPaths.day,
        queryParameters: {
          ActivityPlanApiJsonKeys.viewerUserIdx: viewerUserIdx,
          ActivityPlanApiJsonKeys.createdBy: createdBy,
        },
        data: body.toJson(),
      );
      return envelopeSuccess(r.data);
    } catch (_) {
      return false;
    }
  }

  Future<List<TeamViewPermissionRow>> fetchTeamViewPermissions(int userIdx) {
    return getDataList(
      ActivityPlanApiPaths.teamViewPermissions(userIdx),
      fromJson: TeamViewPermissionRow.fromJson,
    );
  }

  Future<bool> saveTeamViewPermissions({
    required int userIdx,
    required String grantedBy,
    required List<TeamViewPermissionRow> rows,
  }) async {
    try {
      final r = await client.put(
        ActivityPlanApiPaths.teamViewPermissions(userIdx),
        queryParameters: {ActivityPlanApiJsonKeys.grantedBy: grantedBy},
        data: {
          ActivityPlanApiJsonKeys.items: rows
              .where((e) => e.canView)
              .map(
                (e) => {
                  ActivityPlanApiJsonKeys.targetDeptIdx: e.targetDeptIdx,
                  ActivityPlanApiJsonKeys.canView: true,
                },
              )
              .toList(),
        },
      );
      return envelopeSuccess(r.data);
    } catch (_) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
