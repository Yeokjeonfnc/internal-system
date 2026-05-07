import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/str001/str001_model.dart';

/// 가맹점 API 서비스
class StoreApiService extends BaseRepository {
  /// 모든 가맹점 목록 조회
  Future<List<Store>> getAllStores() async {
    try {
      return await getDataList('/stores', fromJson: Store.fromJson);
    } catch (e) {
      debugPrint('Error fetching stores: $e');
      return [];
    }
  }

  /// 가맹점 인덱스로 조회
  Future<Store?> getStoreByIndex(int storeIdx) async {
    try {
      return await getDataOrNull(
        '/stores/$storeIdx',
        fromJson: Store.fromJson,
      );
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

      return await getDataList(
        '/stores/search',
        queryParameters: queryParams,
        fromJson: Store.fromJson,
      );
    } catch (e) {
      debugPrint('Error searching stores: $e');
      return [];
    }
  }

  /// 가맹점 신규 등록
  Future<Store?> createStore(Map<String, dynamic> data) async {
    try {
      return await postDataOrNull(
        '/stores',
        data: data,
        fromJson: Store.fromJson,
      );
    } catch (e) {
      debugPrint('Error creating store: $e');
    }
    return null;
  }

  /// 가맹점 수정
  Future<Store?> updateStore(int storeIdx, Map<String, dynamic> data) async {
    try {
      return await putDataOrNull(
        '/stores/$storeIdx',
        data: data,
        fromJson: Store.fromJson,
      );
    } catch (e) {
      debugPrint('Error updating store: $e');
    }
    return null;
  }

  /// 가맹점 삭제
  Future<bool> deleteStore(int storeIdx) async {
    try {
      final response = await client.delete('/stores/$storeIdx');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting store: $e');
      return false;
    }
  }

  /// 가맹점 히스토리 조회
  Future<List<HistoryEntry>> getStoreHistories(int storeIdx) async {
    try {
      return await getDataList(
        '/stores/$storeIdx/histories',
        fromJson: HistoryEntry.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching store histories: $e');
    }
    return [];
  }
}
