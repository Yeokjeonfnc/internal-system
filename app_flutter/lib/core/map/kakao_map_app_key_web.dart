// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:app_flutter/core/map/kakao_map_app_key.dart';

/// 컴파일 타임·debug 예시 키를 iframe·SDK가 읽는 localStorage에 맞춘다.
void syncKakaoMapAppKeyToLocalStorage() {
  final key = resolveKakaoMapAppKey(
    localStorageValue: html.window.localStorage[kKakaoMapLocalStorageKey] ?? '',
  );
  if (key.isEmpty) return;
  html.window.localStorage[kKakaoMapLocalStorageKey] = key;
}

String readKakaoMapAppKeyFromLocalStorage() =>
    html.window.localStorage[kKakaoMapLocalStorageKey] ?? '';

void writeKakaoMapAppKeyToLocalStorage(String key) {
  final trimmed = key.trim();
  if (trimmed.isEmpty) {
    html.window.localStorage.remove(kKakaoMapLocalStorageKey);
  } else {
    html.window.localStorage[kKakaoMapLocalStorageKey] = trimmed;
  }
}

bool _kakaoSdkWarmStarted = false;

/// Kakao 지도 SDK 를 부모 페이지에서 미리 받아 HTTP 캐시에 올려둔다.
///
/// 영업지역 지도 iframe 이 동일 URL(`autoload=false&libraries=drawing,services`)
/// 을 캐시에서 즉시 로드하도록 해 팝업 첫 로딩을 단축한다. autoload=false 라
/// 실제 지도 초기화는 하지 않아 부모 페이지에 영향이 없다. 중복 호출은 무시한다.
void warmKakaoMapSdk() {
  if (_kakaoSdkWarmStarted) return;
  syncKakaoMapAppKeyToLocalStorage();
  final key = resolveKakaoMapAppKey(
    localStorageValue: readKakaoMapAppKeyFromLocalStorage(),
  );
  if (key.isEmpty) return;
  _kakaoSdkWarmStarted = true;
  final url =
      'https://dapi.kakao.com/v2/maps/sdk.js'
      '?appkey=${Uri.encodeComponent(key)}'
      '&autoload=false&libraries=drawing,services';
  final script = html.ScriptElement()
    ..src = url
    ..async = true;
  html.document.head?.append(script);
}
