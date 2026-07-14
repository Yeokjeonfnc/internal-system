import 'package:flutter/material.dart';

import 'package:app_flutter/core/map/kakao_coordinate_picker_model.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';

Future<KakaoCoordinatePickResult?> showKakaoCoordinatePicker(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
}) async {
  await showAlertDialog(context, '좌표 지정은 Flutter Web에서 사용할 수 있습니다.');
  return null;
}
