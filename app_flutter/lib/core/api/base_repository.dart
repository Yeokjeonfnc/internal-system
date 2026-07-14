import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:app_flutter/core/api/api_client.dart';

/// 서버 [ApiResponse] JSON 루트 — 본문이 문자열이어도 파싱한다.
Map<String, dynamic>? parseEnvelopeRoot(dynamic responseBody) {
  if (responseBody == null) return null;
  try {
    if (responseBody is String) {
      final trimmed = responseBody.trim();
      if (trimmed.isEmpty) return null;
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    }
    if (responseBody is Map<String, dynamic>) return responseBody;
    if (responseBody is Map) return Map<String, dynamic>.from(responseBody);
    return null;
  } catch (_) {
    return null;
  }
}

/// [ApiResponse.message] — 비어 있으면 null.
String? readEnvelopeMessage(dynamic responseBody) {
  final root = parseEnvelopeRoot(responseBody);
  if (root == null) return null;
  final m = root['message'];
  if (m == null) return null;
  final s = m.toString().trim();
  return s.isEmpty ? null : s;
}

/// [ApiResponse.success] 여부 (`success == true`).
bool readEnvelopeSuccess(dynamic responseBody) {
  final root = parseEnvelopeRoot(responseBody);
  if (root == null) return false;
  return root['success'] == true;
}

/// [DioException] → 사용자용 한글 메시지 (서버 [ApiResponse.message] 우선).
String dioErrorMessage(DioException e, {String fallback = '요청에 실패했습니다.'}) {
  final fromBody = readEnvelopeMessage(e.response?.data);
  if (fromBody != null && fromBody.isNotEmpty) return fromBody;

  final root = parseEnvelopeRoot(e.response?.data);
  if (root != null) {
    final data = root['data'];
    if (data is Map && data.isNotEmpty) {
      final first = data.values.first;
      final text = first?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
  }

  switch (e.response?.statusCode) {
    case 400:
      return fallback;
    case 401:
      return '로그인이 필요합니다.';
    case 403:
      return '권한이 없습니다.';
    case 404:
      return '요청한 정보를 찾을 수 없습니다.';
    case 500:
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    default:
      break;
  }

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '네트워크 연결을 확인해 주세요.';
    default:
      break;
  }

  return fallback;
}

/// API·저장 실패를 알림 다이얼로그용 문구로 변환한다.
String formatApiUserMessage(Object error, {String fallback = '요청에 실패했습니다.'}) {
  if (error is StateError) {
    final msg = error.message.trim();
    if (msg.isNotEmpty) return msg;
  }
  if (error is DioException) {
    return dioErrorMessage(error, fallback: fallback);
  }
  final raw = error.toString();
  const badState = 'Bad state: ';
  if (raw.startsWith(badState)) {
    return raw.substring(badState.length);
  }
  if (raw.startsWith('DioException')) {
    return fallback;
  }
  return raw;
}

/// `ApiResponse { data, ... }` 래퍼를 공통으로 풀어 [T] 로 만든다.
abstract class BaseRepository {
  BaseRepository({ApiClient? client}) : client = client ?? ApiClient();

  final ApiClient client;

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException('Expected JSON object, got ${raw.runtimeType}');
  }

  T parseData<T>(
    dynamic responseBody,
    T Function(Map<String, dynamic> j) fromJson,
  ) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data == null) {
      throw StateError('API response missing data field');
    }
    return fromJson(_asMap(data));
  }

  T? parseDataOrNull<T>(
    dynamic responseBody,
    T Function(Map<String, dynamic> j) fromJson,
  ) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data == null) return null;
    return fromJson(_asMap(data));
  }

  List<T> parseDataList<T>(
    dynamic responseBody,
    T Function(Map<String, dynamic> j) fromJson,
  ) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data is! List) return const [];
    return data.map((e) => fromJson(_asMap(e))).toList(growable: false);
  }

  /// 조회 응답 `data` 가 객체 배열일 때 — DTO 없이 맵 리스트로 수신.
  List<Map<String, dynamic>> parseDataListMap(dynamic responseBody) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data is! List) return const [];
    return data.map((e) => _asMap(e)).toList(growable: false);
  }

  Map<String, dynamic>? parseDataMapOrNull(dynamic responseBody) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data == null) return null;
    return _asMap(data);
  }

  Map<String, dynamic> responseMap(Response r) => _asMap(r.data);

  /// `data` 가 객체가 아닌 숫자·문자열 등일 때 (예: 미읽음 건수).
  T? readEnvelopeData<T>(dynamic responseBody, T Function(dynamic raw) parse) {
    try {
      final root = _asMap(responseBody);
      final data = root['data'];
      if (data == null) return null;
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// [ApiResponse.success] 여부 (`success == true`).
  bool envelopeSuccess(dynamic responseBody) =>
      readEnvelopeSuccess(responseBody);

  /// [ApiResponse.message] — 비어 있으면 null.
  String? envelopeMessage(dynamic responseBody) =>
      readEnvelopeMessage(responseBody);

  bool isHttpSuccess(int? statusCode) =>
      statusCode == 200 || statusCode == 201 || statusCode == 204;

  Future<List<T>> getDataList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    try {
      final r = await client.get(path, queryParameters: queryParameters);
      if (r.statusCode != 200 || r.data == null) return const [];
      return parseDataList(r.data, fromJson);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> getDataListMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await client.get(path, queryParameters: queryParameters);
      if (r.statusCode != 200 || r.data == null) return const [];
      return parseDataListMap(r.data);
    } catch (_) {
      return const [];
    }
  }

  Future<T?> getDataOrNull<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    try {
      final r = await client.get(path, queryParameters: queryParameters);
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataOrNull(r.data, fromJson);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDataMapOrNull(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await client.get(path, queryParameters: queryParameters);
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataMapOrNull(r.data);
    } catch (_) {
      return null;
    }
  }

  Future<T> getData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    final r = await client.get(path, queryParameters: queryParameters);
    if (r.statusCode != 200 || r.data == null) {
      throw StateError('GET $path failed: status=${r.statusCode}');
    }
    return parseData(r.data, fromJson);
  }

  Future<T?> postDataOrNull<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    try {
      final r = await client.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataOrNull(r.data, fromJson);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> postDataMapOrNull(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await client.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataMapOrNull(r.data);
    } catch (_) {
      return null;
    }
  }

  Future<T?> putDataOrNull<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    try {
      final r = await client.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataOrNull(r.data, fromJson);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> putDataMapOrNull(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await client.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      return parseDataMapOrNull(r.data);
    } catch (_) {
      return null;
    }
  }

  Future<T> postData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    final r = await client.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    if (!isHttpSuccess(r.statusCode) || r.data == null) {
      throw StateError('POST $path failed: status=${r.statusCode}');
    }
    return parseData(r.data, fromJson);
  }

  Future<T> putData<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> j) fromJson,
  }) async {
    final r = await client.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    if (!isHttpSuccess(r.statusCode) || r.data == null) {
      throw StateError('PUT $path failed: status=${r.statusCode}');
    }
    return parseData(r.data, fromJson);
  }

  Future<bool> deleteOk(String path) async {
    try {
      final r = await client.delete(path);
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
