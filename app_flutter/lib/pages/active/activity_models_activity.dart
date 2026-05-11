import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

/// `/activities/status/*` 피벗 행 — 백엔드 `ActivityStatusPivotRowDto`.
class ActivityStatusPivotRow {
  const ActivityStatusPivotRow({
    required this.storeNm,
    required this.userName,
    required this.userId,
    required this.actDtRaw,
    required this.count,
  });

  final String storeNm;
  final String userName;
  final String userId;
  final String actDtRaw;
  final int count;

  factory ActivityStatusPivotRow.fromJson(Map<String, dynamic> json) {
    return ActivityStatusPivotRow(
      storeNm: json.jsonString(ActiveMstApiJsonKeys.storeNm),
      userName: json.jsonString(ActiveMstApiJsonKeys.userName),
      userId: json.jsonString(ActiveMstApiJsonKeys.userId),
      actDtRaw: json.jsonString(ActiveMstApiJsonKeys.actDt),
      count: (json[ActiveMstApiJsonKeys.count] as Object?).asJsonInt(0),
    );
  }
}

/// `/activities` 목록·임시보관 등 공통 행 — `ActiveMstResponseDto` 키와 정렬.
class ActivityRow {
  const ActivityRow({
    this.actIdx,
    this.storeIdx,
    required this.actType,
    required this.actDt,
    required this.actNotes,
    required this.svNm,
    required this.chkYn,
    required this.apprStatus,
    required this.apprNotes,
    required this.brandNm,
    required this.brandCd,
    required this.storeNm,
    required this.storeCd,
    required this.createDt,
    required this.memoTxt,
    required this.ssvNm,
  });

  final int? actIdx;
  final int? storeIdx;
  final String actType;
  final String actDt;
  final String actNotes;
  final String svNm;
  final String chkYn;
  final String apprStatus;
  final String apprNotes;
  final String brandNm;
  final String brandCd;
  final String storeNm;
  final String storeCd;
  final String createDt;
  final String memoTxt;
  final String ssvNm;

  factory ActivityRow.fromJson(Map<String, dynamic> json) {
    return ActivityRow(
      actIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.actIdx]),
      storeIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.storeIdx]),
      actType: json.jsonString(ActiveMstApiJsonKeys.actType),
      actDt: json.jsonString(ActiveMstApiJsonKeys.actDt),
      actNotes: json.jsonString(ActiveMstApiJsonKeys.actNotes),
      svNm: json.jsonString(ActiveMstApiJsonKeys.svNm),
      chkYn: json.jsonString(ActiveMstApiJsonKeys.chkYn),
      apprStatus: json.jsonString(ActiveMstApiJsonKeys.apprStatus),
      apprNotes: json.jsonString(ActiveMstApiJsonKeys.apprNotes),
      brandNm: json.jsonString(ActiveMstApiJsonKeys.brandNm),
      brandCd: json.jsonString(ActiveMstApiJsonKeys.brandCd),
      storeNm: json.jsonString(ActiveMstApiJsonKeys.storeNm),
      storeCd: json.jsonString(ActiveMstApiJsonKeys.storeCd),
      createDt: json.jsonString(ActiveMstApiJsonKeys.createDt),
      memoTxt: json.jsonString(ActiveMstApiJsonKeys.memoTxt),
      ssvNm: json.jsonString(ActiveMstApiJsonKeys.ssvNm),
    );
  }
}

/// `GET /activities/{actIdx}` — `ActiveMstResponseDto` 상세.
class ActivityDetail {
  const ActivityDetail({
    required this.storeIdx,
    required this.apprAckUserIds,
    required this.apprAckDateByUserId,
    required this.svId,
    required this.actType,
    required this.actDt,
    required this.memoTxt,
    required this.actNotes,
    required this.suggestions,
    required this.svNotes,
    required this.apprNotes,
    required this.apprStatus,
    required this.createDtIso,
    required this.apprDtIso,
    required this.svDeptNm,
    required this.svNm,
    required this.resolvedApproverIds,
  });

  final int? storeIdx;
  final Set<String> apprAckUserIds;
  final Map<String, String> apprAckDateByUserId;
  final String svId;
  final String actType;
  final String actDt;
  final String memoTxt;
  final String actNotes;
  final String suggestions;
  final String svNotes;
  final String apprNotes;
  final String apprStatus;
  final String? createDtIso;
  final String? apprDtIso;
  final String svDeptNm;
  final String svNm;

  /// 결재 라인: `apprUserIds` 우선, 없으면 `apprId` CSV.
  final List<String> resolvedApproverIds;

  static String toYmd(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return '';
    return s.split('T').first;
  }

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    final ackIds = <String>{};
    final rawAckIds = json[ActiveMstApiJsonKeys.apprAckUserIds];
    if (rawAckIds is List) {
      for (final e in rawAckIds) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) ackIds.add(s);
      }
    }
    final ackDates = <String, String>{};
    final rawAckMap = json[ActiveMstApiJsonKeys.apprAckDateByUserId];
    if (rawAckMap is Map) {
      for (final e in rawAckMap.entries) {
        final k = e.key.toString();
        if (k.isEmpty) continue;
        ackDates[k] = e.value?.toString() ?? '';
      }
    }

    final ids = <String>[];
    final fromApi = json[ActiveMstApiJsonKeys.apprUserIds];
    if (fromApi is List) {
      for (final e in fromApi) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) ids.add(s);
      }
    }
    if (ids.isEmpty) {
      final raw = json.jsonString(ActiveMstApiJsonKeys.apprId);
      if (raw.isNotEmpty) {
        ids.addAll(
          raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }

    String? optIso(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return ActivityDetail(
      storeIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.storeIdx]),
      apprAckUserIds: ackIds,
      apprAckDateByUserId: ackDates,
      svId: json.jsonString(ActiveMstApiJsonKeys.svId),
      actType: json.jsonString(ActiveMstApiJsonKeys.actType),
      actDt: json.jsonString(ActiveMstApiJsonKeys.actDt),
      memoTxt: json.jsonString(ActiveMstApiJsonKeys.memoTxt),
      actNotes: json.jsonString(ActiveMstApiJsonKeys.actNotes),
      suggestions: json.jsonString(ActiveMstApiJsonKeys.suggestions),
      svNotes: json.jsonString(ActiveMstApiJsonKeys.svNotes),
      apprNotes: json.jsonString(ActiveMstApiJsonKeys.apprNotes),
      apprStatus: json.jsonString(ActiveMstApiJsonKeys.apprStatus),
      createDtIso: optIso(json[ActiveMstApiJsonKeys.createDt]),
      apprDtIso: optIso(json[ActiveMstApiJsonKeys.apprDt]),
      svDeptNm: json.jsonString(ActiveMstApiJsonKeys.svDeptNm),
      svNm: json.jsonString(ActiveMstApiJsonKeys.svNm),
      resolvedApproverIds: ids,
    );
  }
}
