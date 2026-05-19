import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_dimensions.dart';

/// Web·Windows·macOS·Linux 는 항상 PC(와이드) 레이아웃.
/// Android·iOS 만 [shellCompactMaxWidth] 미만일 때 모바일 레이아웃(Drawer·필터 시트 등).
bool useCompactErpLayout(BuildContext context) {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      break;
    default:
      return false;
  }
  return MediaQuery.sizeOf(context).width <
      AppDimensions.shellCompactMaxWidth;
}

/// [LayoutBuilder] 등에서 제약 폭만 알 때(동일 규칙).
bool useCompactErpLayoutForWidth(double width) {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      break;
    default:
      return false;
  }
  return width < AppDimensions.shellCompactMaxWidth;
}
