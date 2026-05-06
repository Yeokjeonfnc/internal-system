import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/features/stores/store_model.dart';

/// 가맹점 API 서비스
class StoreApiService {
  final ApiClient _client = ApiClient();

  /// 모든 가맹점 목록 조회
  Future<List<Store>> getAllStores() async {
    try {
      final response = await _client.get('/stores');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> storesJson = data['data'] ?? [];

        return storesJson.map((json) => _mapToStore(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching stores: $e');
      return [];
    }
  }

  /// 가맹점 인덱스로 조회
  Future<Store?> getStoreByIndex(int storeIdx) async {
    try {
      final response = await _client.get('/stores/$storeIdx');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final storeJson = data['data'];

        if (storeJson != null) {
          return _mapToStore(storeJson);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching store by index: $e');
      return null;
    }
  }

  /// 가맹점 이름으로 검색
  Future<List<Store>> searchStores({String? name, String? brand}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (name != null && name.isNotEmpty) {
        queryParams['storeNm'] = name;
      }

      final response = await _client.get(
        '/stores/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> storesJson = data['data'] ?? [];

        return storesJson.map((json) => _mapToStore(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error searching stores: $e');
      return [];
    }
  }

  /// 가맹점 신규 등록
  Future<Store?> createStore(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/stores', data: data);

      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final storeJson = responseData['data'];

        if (storeJson != null) {
          return _mapToStore(storeJson);
        }
      }
    } catch (e) {
      debugPrint('Error creating store: $e');
    }
    return null;
  }

  /// 가맹점 수정
  Future<Store?> updateStore(int storeIdx, Map<String, dynamic> data) async {
    try {
      final response = await _client.put('/stores/$storeIdx', data: data);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final storeJson = responseData['data'];

        if (storeJson != null) {
          return _mapToStore(storeJson);
        }
      }
    } catch (e) {
      debugPrint('Error updating store: $e');
    }
    return null;
  }

  /// 가맹점 삭제
  Future<bool> deleteStore(int storeIdx) async {
    try {
      final response = await _client.delete('/stores/$storeIdx');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting store: $e');
      return false;
    }
  }

  /// 가맹점 히스토리 조회
  Future<List<HistoryEntry>> getStoreHistories(int storeIdx) async {
    try {
      final response = await _client.get('/stores/$storeIdx/histories');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> historiesJson = data['data'] ?? [];

        return historiesJson
            .map((json) => _mapToHistoryEntry(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching store histories: $e');
    }
    return [];
  }

  /// 백엔드 JSON을 Flutter Store 모델로 변환
  Store _mapToStore(Map<String, dynamic> json) {
    return Store(
      floor: json['floor'] ?? 0,
      parkingCount: json['parkingCount'] ?? 0,
      storeIdx: json['storeIdx'] ?? 0,
      no: json['id'] ?? 0,
      storeNm: json['storeNm'] ?? '',
      brandCd: json['brandCd'] ?? '',
      brandNm: json['brandNm'] ?? json['brandCd'] ?? '',
      storeCd: json['storeCd'] ?? '',
      storeStatus: json['storeStatus'] ?? '',
      storeStatusNm: json['storeStatusNm'] ?? '',
      ownerNm: json['ownerNm'] ?? '',
      storeTel: json['storeTel'] ?? '',
      zipCd: json['zipCd'] ?? '',
      address: json['address'] ?? '',
      addressDetail: json['adressDetail'] ?? '',
      contStartDt: json['contStartDt'] ?? json['contractStartDate'] ?? '',
      contEndDt: json['contEndDt'] ?? json['contractEndDate'] ?? '',
      firstContDt: json['firstContDt'] ?? '',
      regionCd: json['regionCd'] ?? '',
      regionNm: json['regionNm'] ?? '',
      storeType: json['storeType'] ?? '',
      storeTypeNm: json['storeTypeNm'] ?? '',
      svId: json['svId'] ?? json['supervisorId'] ?? '',
      businessNumber: json['businessNumber'] ?? '',
      notes: json['notes'] ?? '',
      frFee: json['frFee']?.toString() ?? '',
      eduFee: json['eduFee']?.toString() ?? '',
      insuDeposit: json['insuDeposit']?.toString() ?? '',
      contDeposit: json['contDeposit']?.toString() ?? '',
      contManager: json['contManager'] ?? '',
      eduManager: json['eduManager'] ?? '',
      contArea: json['contArea']?.toString() ?? '',
      realArea: json['realArea']?.toString() ?? '',
      monthlyRent: json['monthlyRent'] ?? 0,
      rentDeposit: json['rentDeposit'] ?? 0,
      premiumFee: json['premiumFee'] ?? 0,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }

  HistoryEntry _mapToHistoryEntry(Map<String, dynamic> json) {
    final rawContent = json['chgContent'];
    final fallbackContent = json['content']?.toString() ?? '';
    return HistoryEntry(
      chgDt: _formatHistoryDate(
        json['chgDt']?.toString() ?? json['createdAt']?.toString() ?? '',
      ),
      chgContent: rawContent == null ? '[]' : jsonEncode(rawContent),
      content: _formatHistoryContent(rawContent, fallbackContent),
      chgUserId:
          json['chgUserId']?.toString() ?? json['createdBy']?.toString() ?? '',
    );
  }

  String _formatHistoryContent(dynamic rawContent, String fallbackContent) {
    if (rawContent is List && rawContent.isNotEmpty) {
      return rawContent.map(_formatHistoryChange).join(', ');
    }
    if (rawContent is Map<String, dynamic>) {
      return _formatHistoryChange(rawContent);
    }
    if (fallbackContent.isNotEmpty) return fallbackContent;
    return '-';
  }

  String _formatHistoryChange(dynamic rawChange) {
    if (rawChange is! Map) return rawChange.toString();
    final col = rawChange['column_desc']?.toString().trim().isNotEmpty == true
        ? rawChange['column_desc'].toString()
        : rawChange['column_nm']?.toString() ??
              rawChange['col']?.toString() ??
              '변경값';
    final before =
        rawChange['before_value']?.toString() ??
        rawChange['before']?.toString();
    final after =
        rawChange['after_value']?.toString() ?? rawChange['after']?.toString();
    if ((before == null || before.isEmpty) &&
        (after == null || after.isEmpty)) {
      return '$col 변경';
    }
    if (before == null || before.isEmpty) return '$col: $after';
    if (after == null || after.isEmpty) return '$col: $before -> -';
    return '$col: $before -> $after';
  }

  String _formatHistoryDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.replaceFirst('T', ' ');
    }
    String two(int value) => value.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} '
        '${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
  }
}
