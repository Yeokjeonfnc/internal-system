import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(fromJson: _intAny)
  final int chkIdx;

  final String brandCd;
  final String chkType;
  final String chkTypeNm;
  final String chkContent;

  @JsonKey(fromJson: _intAny)
  final int baseScore;

  final String useYn;

  factory MasterChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$MasterChecklistItemFromJson(json);

  Map<String, dynamic> toJson() => _$MasterChecklistItemToJson(this);
}

int _intAny(Object? e) => e.asJsonInt();
