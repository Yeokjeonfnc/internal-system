import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';
import 'package:app_flutter/core/store_mst/store_mst_write_request.dart';

String _describeStoreCreateFailure(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    final type = e.type.name;
    final msg = e.message?.trim();
    final buf = StringBuffer('Dio $type');
    if (code != null) buf.write(' HTTP $code');
    if (msg != null && msg.isNotEmpty) buf.write(': $msg');
    return buf.toString();
  }
  return e.toString();
}

/// 가맹점 API 서비스
class StoreApiService extends BaseRepository {
  String? _envelopeMessageFromDio(DioException e) =>
      envelopeMessage(e.response?.data);

  /// 모든 가맹점 목록 조회
  Future<List<Store>> getAllStores() async {
    try {
      return await getDataList(StoreMstApiPaths.root, fromJson: Store.fromJson);
    } catch (e) {
      debugPrint('Error fetching stores: $e');
      return [];
    }
  }

  /// 가맹점 인덱스로 조회
  Future<Store?> getStoreByIndex(int storeIdx) async {
    try {
      return await getDataOrNull(
        StoreMstApiPaths.one(storeIdx),
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
        queryParams[StoreMstWriteRequest.jsonKeyStoreNm] = name;
      }

      return await getDataList(
        StoreMstApiPaths.search,
        queryParameters: queryParams,
        fromJson: Store.fromJson,
      );
    } catch (e) {
      debugPrint('Error searching stores: $e');
      return [];
    }
  }

  /// 가맹점 신규 등록. 실패 시 서버 [message]를 [onServerMessage]로 넘긴다(중복 주소 400 등).
  Future<Store?> createStore(
    StoreMstWriteRequest body, {
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('createStore: $m');
      }
    }

    try {
      final r = await client.post(
        StoreMstApiPaths.root,
        data: body.toRequestBody(),
      );
      if (r.data == null) {
        fail('서버 응답이 비어 있습니다.');
        return null;
      }
      try {
        responseMap(r);
      } catch (e, st) {
        debugPrint('createStore responseMap: $e\n$st');
        fail('서버 응답 형식 오류: 본문이 JSON 객체가 아닙니다.\n(${e.toString()})');
        return null;
      }
      if (!envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '저장에 실패했습니다.');
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) {
        fail('저장에 실패했습니다.');
        return null;
      }
      try {
        final store = parseDataOrNull(r.data, Store.fromJson);
        if (store == null) {
          fail('응답 데이터를 해석할 수 없습니다.');
        }
        return store;
      } catch (e, st) {
        debugPrint('Store JSON parse error: $e\n$st');
        fail('응답 형식 오류');
        return null;
      }
    } catch (e, st) {
      debugPrint('Error creating store: $e\n$st');
      if (e is DioException) {
        final apiMsg = _envelopeMessageFromDio(e);
        if (apiMsg != null) {
          fail(apiMsg);
          return null;
        }
      }
      fail('저장에 실패했습니다.\n(${_describeStoreCreateFailure(e)})');
    }
    return null;
  }

  /// 가맹점 수정 (400 시 서버 message 표시 — Dio 기본값은 4xx에서 예외 발생)
  Future<Store?> updateStore(
    int storeIdx,
    StoreMstWriteRequest body, {
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('updateStore: $m');
      }
    }

    try {
      final r = await client.put(
        StoreMstApiPaths.one(storeIdx),
        data: body.toRequestBody(),
      );
      if (r.data == null) {
        fail('서버 응답이 비어 있습니다.');
        return null;
      }
      try {
        responseMap(r);
      } catch (e, st) {
        debugPrint('updateStore responseMap: $e\n$st');
        fail('서버 응답 형식 오류: 본문이 JSON 객체가 아닙니다.\n(${e.toString()})');
        return null;
      }
      if (!envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '저장에 실패했습니다.');
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) {
        fail('저장에 실패했습니다.');
        return null;
      }
      try {
        final store = parseDataOrNull(r.data, Store.fromJson);
        if (store == null) {
          fail('응답 데이터를 해석할 수 없습니다.');
        }
        return store;
      } catch (e, st) {
        debugPrint('Store JSON parse error (update): $e\n$st');
        fail('응답 형식 오류');
        return null;
      }
    } catch (e, st) {
      debugPrint('Error updating store: $e\n$st');
      if (e is DioException) {
        final apiMsg = _envelopeMessageFromDio(e);
        if (apiMsg != null) {
          fail(apiMsg);
          return null;
        }
      }
      fail('저장에 실패했습니다.\n(${_describeStoreCreateFailure(e)})');
    }
    return null;
  }

  /// 가맹점 삭제
  Future<bool> deleteStore(int storeIdx) async {
    try {
      final response = await client.delete(StoreMstApiPaths.one(storeIdx));
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
        StoreMstApiPaths.histories(storeIdx),
        fromJson: HistoryEntry.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching store histories: $e');
    }
    return [];
  }
}
