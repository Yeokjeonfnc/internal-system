import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/act001/act001_model_checklist.dart';

class Act001ChecklistApi extends BaseRepository {
  Future<List<ChecklistItem>> getChecklistsByBrand(String brandCd) async {
    try {
      return await getDataList(
        '/checklists',
        queryParameters: {'brandCd': brandCd},
        fromJson: ChecklistItem.fromJson,
      );
    } catch (e) {
      debugPrint('체크리스트 조회 에러: $e');
    }
    return const [];
  }
}
