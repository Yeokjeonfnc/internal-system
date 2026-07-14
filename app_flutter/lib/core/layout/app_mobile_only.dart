import 'package:flutter/foundation.dart';

/// Android·iOS 네이티브 앱 (웹·데스크톱 제외).
bool get isNativeMobileApp {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}
