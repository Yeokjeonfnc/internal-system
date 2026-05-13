import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/checklist/chk_mst_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

part 'act002_model_checklist.g.dart';

@JsonSerializable()
class ChecklistItem {
  const ChecklistItem({
    required this.chkIdx,
    required this.brandCd,
    required this.chkType,
    required this.chkTypeNm,
    required this.chkContent,
    required this.baseScore,
    required this.displayOrder,
  });

  @JsonKey(name: ChkMstApiJsonKeys.chkIdx, fromJson: _toInt)
  final int chkIdx;

  @JsonKey(name: ChkMstApiJsonKeys.brandCd)
  final String brandCd;

  @JsonKey(name: ChkMstApiJsonKeys.chkType)
  final String chkType;

  @JsonKey(name: ChkMstApiJsonKeys.chkTypeNm)
  final String chkTypeNm;

  @JsonKey(name: ChkMstApiJsonKeys.chkContent)
  final String chkContent;

  @JsonKey(name: ChkMstApiJsonKeys.baseScore, fromJson: asJsonIntOpt)
  final int? baseScore;

  @JsonKey(name: ChkMstApiJsonKeys.displayOrder, fromJson: asJsonIntOpt)
  final int? displayOrder;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistItemToJson(this);
}

int _toInt(Object? e) => e.asJsonInt();
