import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_token_store.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/core/property_mst/property_mst_write_request.dart';

/// 물건 API — 백엔드 `DevController` (`/properties`).

class PropertyApiService extends BaseRepository {
  Future<List<Property>> getAllProperties() async {
    try {
      return await getDataList(
        PropertyMstApiPaths.root,
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
    return const [];
  }

  Future<Property?> getProperty(int propIdx) async {
    try {
      return await getDataOrNull(
        PropertyMstApiPaths.one(propIdx),
        fromJson: Property.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching property: $e');
    }
    return null;
  }

  /// 성공 시 `(property, null)`, 실패 시 `(null, 서버 message 또는 안내 문구)`.
  Future<(Property?, String?)> createProperty(
    PropertyMstWriteRequest body,
  ) async {
    try {
      final r = await client.post(
        PropertyMstApiPaths.root,
        data: body.toRequestBody(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      if (!envelopeSuccess(r.data)) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      final p = parseDataOrNull(r.data, Property.fromJson);
      if (p == null) {
        return (null, '저장에 실패했습니다.');
      }
      return (p, null);
    } on DioException catch (e) {
      debugPrint('Error creating property: $e');
      final msg = envelopeMessage(e.response?.data);
      return (null, (msg != null && msg.isNotEmpty) ? msg : '저장에 실패했습니다.');
    } catch (e) {
      debugPrint('Error creating property: $e');
      return (null, '저장에 실패했습니다.');
    }
  }

  /// 성공 시 `(property, null)`, 실패 시 `(null, 서버 message 또는 안내 문구)`.
  Future<(Property?, String?)> updateProperty(
    int propIdx,
    PropertyMstWriteRequest body,
  ) async {
    try {
      final r = await client.put(
        PropertyMstApiPaths.one(propIdx),
        data: body.toRequestBody(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      if (!envelopeSuccess(r.data)) {
        return (null, envelopeMessage(r.data) ?? '저장에 실패했습니다.');
      }
      final p = parseDataOrNull(r.data, Property.fromJson);
      if (p == null) {
        return (null, '저장에 실패했습니다.');
      }
      return (p, null);
    } on DioException catch (e) {
      debugPrint('Error updating property: $e');
      final msg = envelopeMessage(e.response?.data);
      return (null, (msg != null && msg.isNotEmpty) ? msg : '저장에 실패했습니다.');
    } catch (e) {
      debugPrint('Error updating property: $e');
      return (null, '저장에 실패했습니다.');
    }
  }

  Future<bool> deleteProperty(int propIdx) =>
      deleteOk(PropertyMstApiPaths.one(propIdx));

  /// 물건 문서 목록
  Future<List<PropertyDocument>> getPropertyDocuments(int propIdx) async {
    try {
      return await getDataList(
        PropertyMstApiPaths.documents(propIdx),
        fromJson: PropertyDocument.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching property documents: $e');
      return const [];
    }
  }

  /// 물건 문서 업로드
  Future<PropertyDocument?> uploadPropertyDocument({
    required int propIdx,
    required String fileName,
    required List<int> bytes,
    required String userId,
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('uploadPropertyDocument: $m');
      }
    }

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final r = await client.postMultipart(
        PropertyMstApiPaths.documents(propIdx),
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
      return parseDataOrNull(r.data, PropertyDocument.fromJson);
    } on DioException catch (e) {
      debugPrint('Error uploading property document: $e');
      final msg = envelopeMessage(e.response?.data);
      if (msg != null && msg.isNotEmpty) {
        fail(msg);
      } else {
        fail('업로드에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('Error uploading property document: $e');
      fail('업로드에 실패했습니다.');
    }
    return null;
  }

  /// 물건 문서 파일 바이트 (미리보기용)
  Future<Uint8List?> downloadPropertyDocumentBytes(
    int propIdx,
    int propertyDocIdx,
  ) async {
    try {
      final r = await client.get(
        PropertyMstApiPaths.documentDownload(propIdx, propertyDocIdx),
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
      debugPrint('downloadPropertyDocumentBytes: $e\n$st');
      return null;
    }
  }

  /// 물건 문서 삭제
  Future<bool> deletePropertyDocument(int propIdx, int propertyDocIdx) {
    return deleteOk(PropertyMstApiPaths.documentOne(propIdx, propertyDocIdx));
  }

  /// 물건 문서 다운로드 URL (브라우저 저장용)
  String propertyDocumentDownloadUrl(int propIdx, int propertyDocIdx) {
    final base = ApiClient.resolveBaseUrl();
    final path = PropertyMstApiPaths.documentDownload(propIdx, propertyDocIdx);
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
