import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/active_mst/active_mst_write_request.dart';
import 'package:app_flutter/core/checklist/chk_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

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
    required this.suggestions,
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
  final String suggestions;
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
      suggestions: json.jsonString(ActiveMstApiJsonKeys.suggestions),
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
    required this.hasSignature,
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
  final bool hasSignature;

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

    /// 결재 도장용 — 일자 맵에 값이 있는 사용자만 '결재함'으로 본다(목록·ID만 오는 오탐 방지).
    String? nonEmptyAckDayForUser(String uid) {
      final u = uid.trim();
      if (u.isEmpty) return null;
      final direct = ackDates[u]?.trim() ?? '';
      if (direct.isNotEmpty) return direct;
      for (final e in ackDates.entries) {
        if (e.key.trim() == u) {
          final d = e.value.toString().trim();
          if (d.isNotEmpty) return d;
        }
      }
      return null;
    }

    final ackIdsEffective = <String>{};
    for (final id in ackIds) {
      if (nonEmptyAckDayForUser(id) != null) ackIdsEffective.add(id.trim());
    }
    for (final e in ackDates.entries) {
      final k = e.key.trim();
      if (k.isEmpty) continue;
      if (e.value.toString().trim().isNotEmpty) ackIdsEffective.add(k);
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
      apprAckUserIds: ackIdsEffective,
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
      hasSignature: json[ActiveMstApiJsonKeys.hasSignature] == true,
    );
  }
}

/// 활동 첨부파일 — `ActAttachmentDto`.
class ActAttachment {
  const ActAttachment({
    required this.actAttIdx,
    required this.actIdx,
    required this.fileName,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.attached,
    required this.attachedAt,
  });

  final int actAttIdx;
  final int actIdx;
  final String fileName;
  final String modifiedAt;
  final String modifiedBy;
  final bool attached;
  final String attachedAt;

  factory ActAttachment.fromJson(Map<String, dynamic> json) {
    return ActAttachment(
      actAttIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.actAttIdx]) ?? 0,
      actIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.actIdx]) ?? 0,
      fileName: json.jsonString(ActiveMstApiJsonKeys.fileName),
      modifiedAt: json.jsonString(ActiveMstApiJsonKeys.modifiedAt),
      modifiedBy: json.jsonString(ActiveMstApiJsonKeys.modifiedBy),
      attached: json[ActiveMstApiJsonKeys.attached] == true,
      attachedAt: json.jsonString(ActiveMstApiJsonKeys.attachedAt),
    );
  }
}

/// `GET /activities/{actIdx}/checklist-results` 한 행 — `ChkResultRowDto`.
class ChkResultRow {
  const ChkResultRow({
    required this.chkIdx,
    required this.brandCd,
    required this.chkType,
    required this.chkTypeNm,
    required this.chkContent,
    required this.baseScore,
    this.displayOrder,
    required this.answerVal,
    required this.answerScore,
  });

  final int chkIdx;
  final String brandCd;
  final String chkType;
  final String chkTypeNm;
  final String chkContent;
  final int baseScore;
  final int? displayOrder;
  final String answerVal;
  final int answerScore;

  factory ChkResultRow.fromJson(Map<String, dynamic> json) {
    return ChkResultRow(
      chkIdx: asJsonIntOpt(json[ChkMstApiJsonKeys.chkIdx]) ?? 0,
      brandCd: json.jsonString(ChkMstApiJsonKeys.brandCd),
      chkType: json.jsonString(ChkMstApiJsonKeys.chkType),
      chkTypeNm: json.jsonString(ChkMstApiJsonKeys.chkTypeNm),
      chkContent: json.jsonString(ChkMstApiJsonKeys.chkContent),
      baseScore: (json[ChkMstApiJsonKeys.baseScore] as Object?).asJsonInt(0),
      displayOrder: asJsonIntOpt(json[ChkMstApiJsonKeys.displayOrder]),
      answerVal: json.jsonString(ChkResultDtlSave.jsonKeyAnswerVal),
      answerScore: (json[ChkResultDtlSave.jsonKeyAnswerScore] as Object?)
          .asJsonInt(0),
    );
  }
}

/// `POST`/`PUT /activities` 성공 응답에서 사용하는 필드만.
class ActivitySaveResult {
  const ActivitySaveResult({this.actIdx});

  final int? actIdx;

  factory ActivitySaveResult.fromJson(Map<String, dynamic> json) {
    return ActivitySaveResult(
      actIdx: asJsonIntOpt(json[ActiveMstApiJsonKeys.actIdx]),
    );
  }
}
