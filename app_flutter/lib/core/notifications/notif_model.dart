import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/notifications/notif_mst_api_json_keys.dart';
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
    this.createDt = '',
  });

  @JsonKey(name: NotifMstApiJsonKeys.notifIdx, fromJson: asJsonIntOpt)
  final int? notifIdx;

  @JsonKey(name: NotifMstApiJsonKeys.userId, fromJson: _str)
  final String userId;

  @JsonKey(name: NotifMstApiJsonKeys.msgTxt, fromJson: _str)
  final String msgTxt;

  @JsonKey(name: NotifMstApiJsonKeys.notifTyp, fromJson: _str)
  final String notifTyp;

  @JsonKey(name: NotifMstApiJsonKeys.actIdx, fromJson: asJsonIntOpt)
  final int? actIdx;

  @JsonKey(name: NotifMstApiJsonKeys.apprYn, fromJson: _str)
  final String apprYn;

  @JsonKey(name: NotifMstApiJsonKeys.readYn, fromJson: _str)
  final String readYn;

  /// API [ZonedDateTime] 직렬화 문자열.
  @JsonKey(name: NotifMstApiJsonKeys.createDt, fromJson: _str)
  final String createDt;

  factory NotifRow.fromJson(Map<String, dynamic> json) =>
      _$NotifRowFromJson(json);

  Map<String, dynamic> toJson() => _$NotifRowToJson(this);
}

String _str(Object? v) => v?.toString() ?? '';
