import 'package:app_flutter/core/checklist/chk_mst_api_json_keys.dart';

/// 체크리스트 마스터 저장 본문 — 백엔드 `ChkMstWriteRequestDto` (`/checklists`).
///
/// 마스터 화면(`mst004`)·활동 등록(`ActivityApiService.fetchChecklistMastersByBrand`) 등 `/checklists` POST·PUT 공통.
class ChkMstWriteRequest {
  static const String jsonKeyBrandCd = ChkMstApiJsonKeys.brandCd;
  static const String jsonKeyChkType = ChkMstApiJsonKeys.chkType;
  static const String jsonKeyChkContent = ChkMstApiJsonKeys.chkContent;
  static const String jsonKeyBaseScore = ChkMstApiJsonKeys.baseScore;
  static const String jsonKeyUseYn = ChkMstApiJsonKeys.useYn;

  ChkMstWriteRequest._(this._map);

  final Map<String, dynamic> _map;

  Map<String, dynamic> toRequestBody() => Map<String, dynamic>.from(_map);

  factory ChkMstWriteRequest.fromMap(Map<String, dynamic> map) =>
      ChkMstWriteRequest._(Map<String, dynamic>.from(map));
}

/// 체크리스트 마스터 REST 경로 — `GET`/`POST`/`PUT /checklists`.
abstract final class ChkMstApiPaths {
  static const String root = '/checklists';

  static String one(int chkIdx) => '$root/$chkIdx';
}
