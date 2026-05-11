import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/active_mst/active_mst_write_payload.dart';
import 'package:app_flutter/core/checklist/chk_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

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
      baseScore:
          (json[ChkMstApiJsonKeys.baseScore] as Object?).asJsonInt(0),
      displayOrder: asJsonIntOpt(json[ChkMstApiJsonKeys.displayOrder]),
      answerVal: json.jsonString(ChkResultDtlSave.jsonKeyAnswerVal),
      answerScore:
          (json[ChkResultDtlSave.jsonKeyAnswerScore] as Object?).asJsonInt(0),
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
