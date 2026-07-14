import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/api/code_option.dart';

export 'package:app_flutter/core/api/code_option.dart';

class CommonCodeApiService extends BaseRepository {
  Future<List<CodeOption>> getCodes(int grpCd) async {
    final r = await client.get(
      CodeMstApiPaths.root,
      queryParameters: {CodeMstQueryParamKeys.grpCd: grpCd},
    );
    if (r.statusCode != 200 || r.data == null) {
      debugPrint(
        'GET /codes failed: grpCd=$grpCd status=${r.statusCode}',
      );
      throw StateError('공통코드 조회 실패 (grpCd=$grpCd, HTTP ${r.statusCode})');
    }
    final rows = parseDataListMap(r.data);
    final out = <CodeOption>[];
    for (final row in rows) {
      try {
        final opt = CodeOption.fromJson(row);
        if (opt.codeCd.isNotEmpty) out.add(opt);
      } catch (e, st) {
        debugPrint('CodeOption parse skip grpCd=$grpCd row=$row: $e\n$st');
      }
    }
    return out;
  }
}
