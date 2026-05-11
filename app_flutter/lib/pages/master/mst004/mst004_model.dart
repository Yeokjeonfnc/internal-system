import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/checklist/chk_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

part 'mst004_model.g.dart';

@JsonSerializable()
class MasterChecklistItem {
  const MasterChecklistItem({
    required this.chkIdx,
    required this.brandCd,
    required this.chkType,
    required this.chkTypeNm,
    required this.chkContent,
    required this.baseScore,
    required this.useYn,
  });

  @JsonKey(name: ChkMstApiJsonKeys.chkIdx, fromJson: _intAny)
  final int chkIdx;

  @JsonKey(name: ChkMstApiJsonKeys.brandCd)
  final String brandCd;

  @JsonKey(name: ChkMstApiJsonKeys.chkType)
  final String chkType;

  @JsonKey(name: ChkMstApiJsonKeys.chkTypeNm)
  final String chkTypeNm;

  @JsonKey(name: ChkMstApiJsonKeys.chkContent)
  final String chkContent;

  @JsonKey(name: ChkMstApiJsonKeys.baseScore, fromJson: _intAny)
  final int baseScore;

  @JsonKey(name: ChkMstApiJsonKeys.useYn)
  final String useYn;

  factory MasterChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$MasterChecklistItemFromJson(json);

  Map<String, dynamic> toJson() => _$MasterChecklistItemToJson(this);
}

int _intAny(Object? e) => e.asJsonInt();
