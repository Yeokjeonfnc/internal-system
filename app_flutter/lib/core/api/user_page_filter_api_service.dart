import 'dart:convert';

import 'package:app_flutter/core/api/base_repository.dart';

/// DB에 저장되는 사용자별 화면 필터 API.
class UserPageFilterApiService extends BaseRepository {
  Future<Map<String, dynamic>?> load({
    required String userId,
    required String pageCode,
  }) async {
    final response = await client.get(
      '/user-page-filters',
      queryParameters: <String, dynamic>{
        'userId': userId,
        'pageCode': pageCode,
      },
    );
    final root = parseEnvelopeRoot(response.data);
    final data = root?['data'];
    if (data is! Map) return null;
    final raw = data['filterJson']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> save({
    required String userId,
    required String pageCode,
    required Map<String, dynamic> filter,
  }) async {
    final response = await client.put(
      '/user-page-filters',
      queryParameters: <String, dynamic>{'userId': userId},
      data: <String, dynamic>{
        'pageCode': pageCode,
        'filterJson': jsonEncode(filter),
      },
    );
    if (!isHttpSuccess(response.statusCode) || !readEnvelopeSuccess(response.data)) {
      throw StateError(
        readEnvelopeMessage(response.data) ?? '검색 조건 저장 요청이 처리되지 않았습니다.',
      );
    }
  }
}
