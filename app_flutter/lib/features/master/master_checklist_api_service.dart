import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';

class MasterChecklistItem {
  const MasterChecklistItem({
    required this.chkIdx,
    required this.brandCd,
    required this.chkType,
    required this.chkTypeNm,
    required this.chkContent,
    required this.baseScore,
    required this.useYn,
  });

  final int chkIdx;
  final String brandCd;
  final String chkType;
  final String chkTypeNm;
  final String chkContent;
  final int baseScore;
  final String useYn;

  factory MasterChecklistItem.fromJson(Map<String, dynamic> json) {
    return MasterChecklistItem(
      chkIdx: _intValue(json['chkIdx']),
      brandCd: json['brandCd']?.toString() ?? '',
      chkType: json['chkType']?.toString() ?? '',
      chkTypeNm: json['chkTypeNm']?.toString() ?? '',
      chkContent: json['chkContent']?.toString() ?? '',
      baseScore: _intValue(json['baseScore']),
      useYn: json['useYn']?.toString() ?? '',
    );
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MasterChecklistApiService {
  final ApiClient _client = ApiClient();

  Future<MasterChecklistItem?> createChecklist(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.post('/checklists', data: data);
      if (response.statusCode == 201 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final row = body['data'];
        if (row is Map<String, dynamic>) {
          return MasterChecklistItem.fromJson(row);
        }
      }
    } catch (e) {
      debugPrint('Error creating checklist: $e');
    }
    return null;
  }

  Future<MasterChecklistItem?> updateChecklist(
    int chkIdx,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put('/checklists/$chkIdx', data: data);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final row = body['data'];
        if (row is Map<String, dynamic>) {
          return MasterChecklistItem.fromJson(row);
        }
      }
    } catch (e) {
      debugPrint('Error updating checklist: $e');
    }
    return null;
  }

  Future<List<MasterChecklistItem>> getChecklists({
    String? brandCd,
    String? chkType,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (brandCd != null && brandCd.isNotEmpty) {
        queryParameters['brandCd'] = brandCd;
      }
      if (chkType != null && chkType.isNotEmpty) {
        queryParameters['chkType'] = chkType;
      }

      final response = await _client.get(
        '/checklists',
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        final rows = body['data'] as List<dynamic>? ?? const [];
        return rows
            .map(
              (json) =>
                  MasterChecklistItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching checklists: $e');
    }
    return [];
  }
}
