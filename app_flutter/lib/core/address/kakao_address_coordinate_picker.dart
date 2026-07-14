import 'package:flutter/material.dart';

import 'kakao_address_coordinate_picker_stub.dart'
    if (dart.library.html) 'kakao_address_coordinate_picker_web.dart'
    as impl;
import 'kakao_address_coordinate_result.dart';

export 'kakao_address_coordinate_result.dart';

/// 우편번호 검색 후 같은 팝업에서 지도 좌표까지 지정.
Future<KakaoAddressCoordinateResult?> showKakaoAddressCoordinatePicker(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
}) {
  return impl.showKakaoAddressCoordinatePicker(
    context,
    initialLatitude: initialLatitude,
    initialLongitude: initialLongitude,
    initialAddress: initialAddress,
  );
}
