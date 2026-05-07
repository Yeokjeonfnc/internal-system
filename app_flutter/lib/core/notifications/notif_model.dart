import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/utils/json_extensions.dart';

part 'notif_model.g.dart';

/// [notif_mst] 목록 한 줄 (API camelCase).
@JsonSerializable()
class NotifRow {
  const NotifRow({
    this.notifIdx,
    this.userId = '',
    this.msgTxt = '',
    this.notifTyp = '',
    this.actIdx,
    this.apprYn = '',
    this.readYn = '',
    this.creatDt = '',
  });

  @JsonKey(fromJson: asJsonIntOpt)
  final int? notifIdx;

  @JsonKey(fromJson: _str)
  final String userId;

  @JsonKey(fromJson: _str)
  final String msgTxt;

  @JsonKey(fromJson: _str)
  final String notifTyp;

  @JsonKey(fromJson: asJsonIntOpt)
  final int? actIdx;

  @JsonKey(fromJson: _str)
  final String apprYn;

  @JsonKey(fromJson: _str)
  final String readYn;

  /// API [ZonedDateTime] 직렬화 문자열.
  @JsonKey(fromJson: _str)
  final String creatDt;

  factory NotifRow.fromJson(Map<String, dynamic> json) => _$NotifRowFromJson(json);

  Map<String, dynamic> toJson() => _$NotifRowToJson(this);
}

String _str(Object? v) => v?.toString() ?? '';
