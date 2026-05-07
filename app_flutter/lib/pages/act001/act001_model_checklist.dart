import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';

part 'act001_model_checklist.g.dart';

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

  @JsonKey(fromJson: _intAny)
  final int chkIdx;

  final String brandCd;
  final String chkType;
  final String chkTypeNm;
  final String chkContent;

  @JsonKey(fromJson: asJsonIntOpt)
  final int? baseScore;

  @JsonKey(fromJson: asJsonIntOpt)
  final int? displayOrder;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistItemToJson(this);
}

int _intAny(Object? e) => e.asJsonInt();
