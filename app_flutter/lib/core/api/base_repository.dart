import 'package:dio/dio.dart';

import 'package:app_flutter/core/api/api_client.dart';

/// `ApiResponse { data, ... }` 래퍼를 공통으로 풀어 [T] 로 만든다.
abstract class BaseRepository {
  BaseRepository({ApiClient? client}) : client = client ?? ApiClient();

  final ApiClient client;

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException('Expected JSON object, got ${raw.runtimeType}');
  }

  T parseData<T>(dynamic responseBody, T Function(Map<String, dynamic> j) fromJson) {
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
    return data
        .map((e) => fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 조회 응답 `data` 가 객체 배열일 때 — DTO 없이 맵 리스트로 수신.
  List<Map<String, dynamic>> parseDataListMap(dynamic responseBody) {
    final root = _asMap(responseBody);
    final data = root['data'];
    if (data is! List) return const [];
    return data
        .map((e) => _asMap(e))
        .toList(growable: false);
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
  bool envelopeSuccess(dynamic responseBody) {
    try {
      final root = _asMap(responseBody);
      return root['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// [ApiResponse.message] — 비어 있으면 null.
  String? envelopeMessage(dynamic responseBody) {
    try {
      final root = _asMap(responseBody);
      final m = root['message'];
      if (m == null) return null;
      final s = m.toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

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
