import 'package:app_flutter/core/api/api_base_url_config.dart';
import 'package:app_flutter/core/api/api_runtime_platform.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API 클라이언트 싱글톤
class ApiClient {
  static ApiClient? _instance;
  factory ApiClient() => _instance ??= ApiClient._internal();

  late final Dio dio;

  /// 1) `--dart-define=API_BASE_URL=...` (회사 서버·로컬 PC 모두)
  /// 2) Android → [kCompanyApiBaseUrl] (기본: test.yeokjeon.com)
  /// 3) 그 외 → 로컬 개발 PC localhost
  static String resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (!kIsWeb && isAndroidHost) {
      return kCompanyApiBaseUrl;
    }
    return buildDevApiBaseUrl('localhost');
  }

  /// Hot reload·재실행 후에도 최신 baseUrl 을 쓰도록 갱신한다.
  static void applyBaseUrl() {
    final url = resolveBaseUrl();
    if (_instance != null) {
      _instance!.dio.options.baseUrl = url;
    }
    if (kDebugMode) {
      debugPrint(
        '[ApiClient] baseUrl=$url (android=${!kIsWeb && isAndroidHost})',
      );
    }
  }

  ApiClient._internal() {
    final baseUrl = resolveBaseUrl();
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = resolveBaseUrl();
          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      debugPrint('[ApiClient] init baseUrl=$baseUrl');
      dio.interceptors.add(_DebugLogInterceptor());
    }
  }

  /// GET 요청
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST 요청
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT 요청
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH 요청
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE 요청
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// multipart POST — [FormData]일 때 Content-Type은 Dio가 boundary 포함해 설정한다.
  Future<Response> postMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        headers: {Headers.acceptHeader: 'application/json'},
      ),
    );
  }
}

/// 개발용 — 영업지역·지도 등 대용량 JSON 본문은 건수만 로그.
class _DebugLogInterceptor extends Interceptor {
  static bool _omitResponseBody(String path, String method) {
    if (path.contains('map-points')) return true;
    if (method == 'GET' && path.contains('sales-areas')) return true;
    return false;
  }

  static int? _envelopeListCount(dynamic data) {
    if (data is! Map) return null;
    final list = data['data'];
    return list is List ? list.length : null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DIO] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    final method = response.requestOptions.method;
    if (_omitResponseBody(path, method)) {
      final n = _envelopeListCount(response.data);
      debugPrint(
        '[DIO] ← ${response.statusCode} $method $path'
        '${n != null ? ' ($n rows)' : ''}',
      );
    } else {
      debugPrint('[DIO] ← ${response.statusCode} $method $path');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[DIO] ✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
      '${err.message}',
    );
    handler.next(err);
  }
}
