// API base URL 설정.
//
// **회사 서버 (APK·운영)**
// - 외부/사내 공통: [kCompanyApiBaseUrl]
// - 사내망 전용: [kCompanyLanApiBaseUrl] (Caddy 8080 → 백엔드 3001)
//
// **로컬 개발 PC** (본인 PC에서 Spring Boot 직접 실행)
// - [kDevLanHost] + [kDevApiPort] (기본 3001)
//
// 빌드 시 `--dart-define-from-file=dart_defines.local.json` 또는
// `--dart-define=API_BASE_URL=https://test.yeokjeon.com/api`

/// 회사 테스트 서버 (웹 배포와 동일, HTTPS)
const String kCompanyApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://test.yeokjeon.com/api',
);

/// 회사 서버 사내망 IP — 3001 은 서버 내부 전용, 폰은 8080 게이트웨이 사용
const String kCompanyLanApiBaseUrl = 'http://192.168.30.30:8080/api';

/// 로컬 개발 PC LAN IP
const String kDevLanHost = String.fromEnvironment(
  'DEV_LAN_HOST',
  defaultValue: '192.168.0.10',
);

const int kDevApiPort = int.fromEnvironment('DEV_API_PORT', defaultValue: 3001);

const String kDevApiPathPrefix = '/api';

/// Android 에뮬레이터 → 호스트 PC 루프백
const String kAndroidEmulatorHost = '10.0.2.2';

String buildDevApiBaseUrl(String host) =>
    'http://$host:$kDevApiPort$kDevApiPathPrefix';

/// Kakao Maps WebView 페이지 origin (카카오 Developers → JavaScript SDK 도메인).
/// API 주소([kCompanyApiBaseUrl])와 분리 — LAN API 를 써도 지도 origin 은 등록된 HTTPS 도메인.
const String kKakaoMapRegisteredWebOrigin = String.fromEnvironment(
  'KAKAO_MAP_WEBVIEW_BASE_URL',
  defaultValue: 'https://test.yeokjeon.com/',
);

String resolveKakaoMapWebViewBaseUrl() {
  final base = kKakaoMapRegisteredWebOrigin.trim();
  if (base.isEmpty) return 'https://test.yeokjeon.com/';
  return base.endsWith('/') ? base : '$base/';
}

/// 앱 WebView 에서 불러올 지도 HTML (회사 웹 서버에 배포된 파일).
Uri salesAreaMapEmbedUri({
  required String htmlFile,
  required String appKey,
  Map<String, String> query = const {},
}) {
  final base = resolveKakaoMapWebViewBaseUrl();
  final uri = Uri.parse(base);
  final params = <String, String>{
    ...query,
    if (appKey.isNotEmpty) 'appkey': appKey,
    'bridge': 'webview',
  };
  return uri.replace(path: '/$htmlFile', queryParameters: params);
}
