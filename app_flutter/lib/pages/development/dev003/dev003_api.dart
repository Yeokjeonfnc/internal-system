import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';

/// 영업지역 API — 백엔드 `DevController` (`GET|POST /sales-areas`).
abstract final class SalesAreaApiPaths {
  static const String list = '/sales-areas';
}

class SalesAreaApiService extends BaseRepository {
  /// 목록 조회. 실패 시 예외를 던져 [FutureProvider]가 [AsyncError]로 표시되게 한다.
  Future<List<SalesAreaRow>> fetchList() async {
    try {
      final r = await client.get(SalesAreaApiPaths.list);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        throw StateError('HTTP ${r.statusCode}');
      }
      if (!envelopeSuccess(r.data)) {
        throw StateError(envelopeMessage(r.data)?.trim().isNotEmpty == true
            ? envelopeMessage(r.data)!
            : 'success=false');
      }
      return parseDataList(r.data, SalesAreaRow.fromJson);
    } on DioException catch (e) {
      debugPrint('SalesAreaApiService.fetchList Dio: $e');
      final code = e.response?.statusCode;
      final tail = e.message ?? 'Dio';
      if (code != null) {
        throw StateError('HTTP $code: $tail');
      }
      throw StateError(
        '$tail — 연결 실패 시 PC면 localhost, Android 에뮬레이터면 10.0.2.2 등 API 주소를 확인하세요.',
      );
    }
  }
}
