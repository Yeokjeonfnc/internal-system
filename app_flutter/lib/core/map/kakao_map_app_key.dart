import 'package:flutter/foundation.dart';

/// Kakao Maps JavaScript 앱 키 — `--dart-define` / Web localStorage.
const String kKakaoMapJavaScriptKeyDefine = String.fromEnvironment(
  'KAKAO_MAP_JAVASCRIPT_KEY',
);

/// 로컬 개발용 — [dart_defines.local.example.json] 과 동일. release 에서는 미사용.
const String kKakaoMapJavaScriptKeyDevExample =
    '3649c96a39bc8cff269119d8cffbe4e0';

const String kKakaoMapLocalStorageKey = 'YJ_KAKAO_MAP_APP_KEY';

String resolveKakaoMapAppKey({String localStorageValue = ''}) {
  final fromDefine = kKakaoMapJavaScriptKeyDefine.trim();
  if (fromDefine.isNotEmpty) return fromDefine;
  final stored = localStorageValue.trim();
  if (stored.isNotEmpty) return stored;
  if (kDebugMode) return kKakaoMapJavaScriptKeyDevExample;
  return '';
}

bool get hasKakaoMapAppKeyFromDefine =>
    kKakaoMapJavaScriptKeyDefine.trim().isNotEmpty;