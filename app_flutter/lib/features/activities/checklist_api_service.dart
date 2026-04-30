// 체크리스트 API 서비스

import 'package:flutter/foundation.dart';
import 'package:app_flutter/core/api/api_client.dart';

class ChecklistItem {
  const ChecklistItem({
    required this.chkIdx,
    required this.brandCd,
    required this.chkType,
    required this.chkTypeNm,
    required this.chkContent,
    required this.baseScore,
    required this.displayOrder,
  });

  final int chkIdx;
  final String brandCd;
  final String chkType;
  final String chkTypeNm;
  final String chkContent;
  final int? baseScore;
  final int? displayOrder;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      chkIdx: json['chkIdx'] as int,
      brandCd: json['brandCd']?.toString() ?? '',
      chkType: json['chkType']?.toString() ?? '',
      chkTypeNm: json['chkTypeNm']?.toString() ?? '',
      chkContent: json['chkContent']?.toString() ?? '',
      baseScore: json['baseScore'] as int?,
      displayOrder: json['displayOrder'] as int?,
    );
  }
}

class ChecklistApiService {
  final ApiClient _client = ApiClient();

  Future<List<ChecklistItem>> getChecklistsByBrand(String brandCd) async {
    try {
      final response = await _client.get('/checklists?brandCd=$brandCd');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final itemsJson = data['data'] as List<dynamic>;
        return itemsJson
            .map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('체크리스트 조회 에러: $e');
      return [];
    }
  }
}
