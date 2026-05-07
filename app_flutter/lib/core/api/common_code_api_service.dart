import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/api/code_option.dart';

export 'package:app_flutter/core/api/code_option.dart';

class CommonCodeApiService extends BaseRepository {
  Future<List<CodeOption>> getCodes(int grpCd) async {
    try {
      return await getDataList(
        '/codes',
        queryParameters: {'grpCd': grpCd},
        fromJson: CodeOption.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching common codes: $e');
    }
    return const [];
  }
}
