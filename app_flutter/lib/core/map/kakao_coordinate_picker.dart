import 'package:flutter/material.dart';

import 'kakao_coordinate_picker_model.dart';
import 'kakao_coordinate_picker_stub.dart'
    if (dart.library.html) 'kakao_coordinate_picker_web.dart' as impl;

Future<KakaoCoordinatePickResult?> showKakaoCoordinatePicker(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
}) {
  return impl.showKakaoCoordinatePicker(
    context,
    initialLatitude: initialLatitude,
    initialLongitude: initialLongitude,
    initialAddress: initialAddress,
  );
}
