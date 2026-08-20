import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_paths.dart';
import 'package:app_flutter/pages/active/act001/act001_model.dart';

/// 활동 현황(act001) — `/activities/status/{type}`.
class Act001Api extends BaseRepository {
  Future<List<ActivityStatusPivotRow>> fetchStatus({
    required String type,
    required String startDt,
    required String endDt,
    String? brandCd,
    String? userId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        ActiveMstQueryParamKeys.startDt: startDt,
        ActiveMstQueryParamKeys.endDt: endDt,
      };
      if (brandCd != null && brandCd.isNotEmpty) {
        queryParameters[ActiveMstApiJsonKeys.brandCd] = brandCd;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParameters[ActiveMstApiJsonKeys.userId] = userId;
      }
      // 실패를 빈 목록으로 삼키면 화면에 '조회된 활동현황이 없습니다.' 가 떠서
      // 서버 오류·토큰 만료를 '데이터 없음' 으로 오인하게 된다. 예외를 그대로 올려
      // 호출부 FutureBuilder 의 오류 분기가 살아나도록 한다.
      // (getDataListMap 은 모든 예외를 삼키므로 여기서는 client 를 직접 쓴다.)
      final path = '${ActiveMstApiPaths.root}/status/$type';
      final r = await client.get(path, queryParameters: queryParameters);
      if (r.statusCode != 200 || r.data == null) {
        throw StateError('GET $path failed: status=${r.statusCode}');
      }
      return parseDataListMap(
        r.data,
      ).map(ActivityStatusPivotRow.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching activity status rows: $e');
      rethrow;
    }
  }
}
