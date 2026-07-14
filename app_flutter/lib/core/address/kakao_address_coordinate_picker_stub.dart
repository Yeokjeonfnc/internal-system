import 'package:flutter/material.dart';

import 'package:app_flutter/core/address/kakao_address_coordinate_result.dart';
import 'package:app_flutter/core/address/kakao_postcode_picker.dart';
import 'package:app_flutter/core/map/kakao_coordinate_picker.dart';
import 'package:app_flutter/core/map/kakao_coordinate_picker_model.dart';

/// Web 이외: 우편번호 선택 후 좌표 지정 팝업을 이어서 연다.
Future<KakaoAddressCoordinateResult?> showKakaoAddressCoordinatePicker(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  String? initialAddress,
}) async {
  final postcode = await showKakaoPostcodePicker(context);
  if (!context.mounted || postcode == null) return null;

  final coords = await showKakaoCoordinatePicker(
    context,
    initialLatitude: initialLatitude,
    initialLongitude: initialLongitude,
    initialAddress: postcode.addressLine,
  );
  if (!context.mounted || coords == null) return null;

  return _merge(postcode, coords);
}

KakaoAddressCoordinateResult _merge(
  KakaoPostcodeResult postcode,
  KakaoCoordinatePickResult coords,
) {
  return KakaoAddressCoordinateResult(
    zonecode: postcode.zonecode,
    roadAddress: postcode.roadAddress,
    jibunAddress: postcode.jibunAddress,
    userSelectedType: postcode.userSelectedType,
    buildingName: postcode.buildingName,
    latitude: coords.latitude,
    longitude: coords.longitude,
  );
}
