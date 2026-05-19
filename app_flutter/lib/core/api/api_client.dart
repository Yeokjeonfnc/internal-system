import 'package:app_flutter/core/api/api_runtime_platform.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API 클라이언트 싱글톤
class ApiClient {
  static ApiClient? _instance;
  factory ApiClient() => _instance ??= ApiClient._internal();

  late final Dio dio;

  /// 1) `--dart-define=API_BASE_URL=...` 2) Android → 에뮬 호스트 PC 3) 그 외 localhost
  static String resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (!kIsWeb && isAndroidHost) {
      return 'http://10.0.2.2:3001/api';
    }
    return 'http://localhost:3001/api';
  }

  /// Hot reload·재실행 후에도 최신 baseUrl 을 쓰도록 갱신한다.
  static void applyBaseUrl() {
    final url = resolveBaseUrl();
    if (_instance != null) {
      _instance!.dio.options.baseUrl = url;
    }
    if (kDebugMode) {
      debugPrint('[ApiClient] baseUrl=$url (android=${!kIsWeb && isAndroidHost})');
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
    }

    // 로깅 인터셉터 추가 (개발 환경)
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
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
}
