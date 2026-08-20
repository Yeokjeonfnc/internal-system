import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_token_store.dart';
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

  /// 모든 가맹점 목록 조회 — 실패해도 화면이 계속 돌아야 하는 소비처용(빈 목록).
  ///
  /// 목록 화면은 '조회 실패'와 '0건'을 구분해 보여줘야 하므로
  /// [getAllStoresOrThrow] 를 쓴다. 여기서 삼키는 쪽은 대시보드·출입 태그처럼
  /// 가맹점 목록이 부수적인 화면들이다.
  Future<List<Store>> getAllStores() async {
    try {
      return await getAllStoresOrThrow();
    } catch (e, st) {
      debugPrint('Error fetching stores: $e\n$st');
      return [];
    }
  }

  /// 실패를 그대로 던지는 가맹점 목록 조회.
  ///
  /// 서버 500·타임아웃·응답 형식 변경을 빈 배열로 삼키면 화면에 '총 0개'로 찍혀
  /// 사용자가 데이터가 지워진 줄 안다. 장애는 장애로 보이게 던진다.
  Future<List<Store>> getAllStoresOrThrow() async {
    final r = await client.get(StoreMstApiPaths.root);
    if (!isHttpSuccess(r.statusCode) || r.data == null) {
      throw StateError('가맹점 목록을 불러오지 못했습니다. (HTTP ${r.statusCode})');
    }
    final root = responseMap(r);
    if (root['success'] != true) {
      throw StateError(envelopeMessage(r.data) ?? '가맹점 목록을 불러오지 못했습니다.');
    }
    final data = root['data'];
    if (data is! List) {
      throw StateError('가맹점 목록 응답 형식이 올바르지 않습니다.');
    }

    final out = <Store>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      try {
        out.add(Store.fromJson(m));
      } catch (e, st) {
        // 한 행이 깨졌다고 목록 전체를 버리지는 않는다(기존 동작 유지).
        debugPrint(
          'Store.fromJson skip storeIdx=${m['storeIdx']}: $e\n$st',
        );
      }
    }
    if (out.length != data.length) {
      debugPrint(
        'getAllStores: parsed ${out.length} of ${data.length} rows',
      );
    }
    return out;
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

  /// 가맹점 삭제. 실패 시 서버 [message]를 [onServerMessage]로 넘긴다.
  ///
  /// 상태코드만 보고 버리면 "점주 계정·NFC 태그가 연결돼 있다" 같은 서버가 이미
  /// 알려준 사유가 사라져, 사용자는 무엇을 정리해야 하는지 모른 채 반복 시도한다.
  Future<bool> deleteStore(
    int storeIdx, {
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('deleteStore: $m');
      }
    }

    try {
      final r = await client.delete(StoreMstApiPaths.one(storeIdx));
      if (!isHttpSuccess(r.statusCode) || !envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '삭제에 실패했습니다.');
        return false;
      }
      return true;
    } catch (e, st) {
      debugPrint('Error deleting store: $e\n$st');
      if (e is DioException) {
        final apiMsg = _envelopeMessageFromDio(e);
        if (apiMsg != null) {
          fail(apiMsg);
          return false;
        }
      }
      fail('삭제에 실패했습니다.\n(${_describeStoreCreateFailure(e)})');
      return false;
    }
  }

  /// 가맹점 히스토리 조회
  Future<List<HistoryEntry>> getStoreHistories(int storeIdx) async {
    try {
      final r = await client.get(StoreMstApiPaths.histories(storeIdx));
      if (r.statusCode != 200 || r.data == null) {
        debugPrint(
          'getStoreHistories: HTTP ${r.statusCode} storeIdx=$storeIdx',
        );
        return const [];
      }
      final root = responseMap(r);
      if (root['success'] != true) {
        final msg = envelopeMessage(r.data) ?? '히스토리 조회에 실패했습니다.';
        throw StateError(msg);
      }
      final data = root['data'];
      if (data is! List) {
        debugPrint('getStoreHistories: data is not List ($data)');
        return const [];
      }

      final entries = <HistoryEntry>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        try {
          entries.add(
            HistoryEntry.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (e) {
          debugPrint('히스토리 행 파싱 실패: $e / raw=$raw');
        }
      }
      if (kDebugMode) {
        debugPrint(
          'getStoreHistories: storeIdx=$storeIdx raw=${data.length} parsed=${entries.length}',
        );
      }
      return entries;
    } catch (e) {
      debugPrint('Error fetching store histories: $e');
      rethrow;
    }
  }

  /// 가맹점 문서 목록
  Future<List<Document>> getStoreDocuments(int storeIdx) async {
    try {
      return await getDataList(
        StoreMstApiPaths.documents(storeIdx),
        fromJson: Document.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching store documents: $e');
      return const [];
    }
  }

  /// 가맹점 문서 업로드
  Future<Document?> uploadStoreDocument({
    required int storeIdx,
    required String fileName,
    required List<int> bytes,
    required String userId,
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('uploadStoreDocument: $m');
      }
    }

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final r = await client.postMultipart(
        StoreMstApiPaths.documents(storeIdx),
        formData: formData,
        queryParameters: {
          if (userId.isNotEmpty) 'userId': userId,
        },
      );
      if (r.data == null) {
        fail('서버 응답이 비어 있습니다.');
        return null;
      }
      if (!envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '업로드에 실패했습니다.');
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) {
        fail('업로드에 실패했습니다.');
        return null;
      }
      return parseDataOrNull(r.data, Document.fromJson);
    } catch (e, st) {
      debugPrint('Error uploading store document: $e\n$st');
      if (e is DioException) {
        final apiMsg = _envelopeMessageFromDio(e);
        if (apiMsg != null) {
          fail(apiMsg);
          return null;
        }
      }
      fail('업로드에 실패했습니다.\n(${_describeStoreCreateFailure(e)})');
    }
    return null;
  }

  /// 가맹점 문서 파일 바이트 (미리보기·인앱 처리용)
  Future<Uint8List?> downloadStoreDocumentBytes(
    int storeIdx,
    int storeDocIdx,
  ) async {
    try {
      final r = await client.get(
        StoreMstApiPaths.documentDownload(storeIdx, storeDocIdx),
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          headers: {Headers.acceptHeader: '*/*'},
        ),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      final data = r.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } catch (e, st) {
      debugPrint('downloadStoreDocumentBytes: $e\n$st');
      return null;
    }
  }

  /// 가맹점 문서 다운로드 URL (브라우저 저장용)
  String storeDocumentDownloadUrl(int storeIdx, int storeDocIdx) {
    final base = ApiClient.resolveBaseUrl();
    final path = StoreMstApiPaths.documentDownload(storeIdx, storeDocIdx);
    final String url;
    if (base.endsWith('/') && path.startsWith('/')) {
      url = '${base.substring(0, base.length - 1)}$path';
    } else if (!base.endsWith('/') && !path.startsWith('/')) {
      url = '$base/$path';
    } else {
      url = '$base$path';
    }
    // 이 URL 은 새 탭(launchUrl)으로 직접 열려 Dio 인터셉터를 타지 않는다 —
    // Authorization 헤더가 실리지 않아 그대로 두면 항상 401 이다.
    // 서버가 /download 로 끝나는 경로에 한해 쿼리 토큰을 허용하므로 함께 붙인다
    // (메신저 첨부 attachmentUrl 과 같은 규약).
    if (!AuthTokenStore.hasToken) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}token=${Uri.encodeQueryComponent(AuthTokenStore.token)}';
  }
}
