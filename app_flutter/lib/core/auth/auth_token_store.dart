// 로그인 토큰 보관소.
//
// [ApiClient] 인터셉터가 매 요청마다 여기서 토큰을 읽어 Authorization 헤더에 싣는다.
// AuthProvider 가 로그인·복원 시 [set], 로그아웃 시 [clear] 를 호출한다.
//
// 서비스 계층이 AuthProvider(위젯 트리 의존)를 직접 참조하지 않도록 분리해 둔다.

import 'package:flutter/foundation.dart';

class AuthTokenStore {
  AuthTokenStore._();

  static String _token = '';

  /// 현재 토큰. 비어 있으면 미로그인 상태.
  static String get token => _token;

  static bool get hasToken => _token.isNotEmpty;

  static void set(String token) => _token = token.trim();

  static void clear() => _token = '';

  /// 서버가 401 을 돌려줬을 때(토큰 만료·무효화·서버 재시작) 올라가는 신호.
  ///
  /// 이게 없으면 세션이 끊겨도 화면은 "로그인 상태"로 남아, 모든 목록이 빈 채로
  /// 그려진다 — 사용자에겐 **데이터가 사라진 것처럼 보인다.** AuthProvider 가
  /// 이 신호를 듣고 세션을 정리하면 라우터가 로그인 화면으로 보낸다.
  static final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

  /// 401 을 받은 쪽에서 호출한다. 토큰을 버리고 한 번만 신호를 올린다.
  static void notifySessionExpired() {
    if (_token.isEmpty && sessionExpired.value > 0) return;
    _token = '';
    sessionExpired.value++;
  }
}
