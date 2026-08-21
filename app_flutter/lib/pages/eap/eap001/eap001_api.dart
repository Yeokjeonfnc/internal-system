// 전자결재 API.

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

abstract final class EapApiPaths {
  static const String forms = '/eap/forms';
  static String form(String formCode) => '/eap/forms/$formCode';
  static const String documents = '/eap/documents';
  static String document(String docId) => '/eap/documents/$docId';
  static String approve(String docId) => '/eap/documents/$docId/approve';
  static String reject(String docId) => '/eap/documents/$docId/reject';
  static const String draft = '/eap/draft';
}

class EapApiService extends BaseRepository {
  Future<List<EapFormConfig>> listForms({bool enabledOnly = false}) async {
    try {
      return await getDataList(
        EapApiPaths.forms,
        queryParameters: {'enabledOnly': enabledOnly},
        fromJson: EapFormConfig.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.listForms: $e');
      return const [];
    }
  }

  Future<EapFormConfig?> createForm(EapFormConfig form) async {
    try {
      return await postDataOrNull(
        EapApiPaths.forms,
        data: form.toCreateBody(),
        fromJson: EapFormConfig.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.createForm: $e');
      rethrow;
    }
  }

  Future<EapFormConfig?> updateForm(EapFormConfig form) async {
    try {
      return await putDataOrNull(
        EapApiPaths.form(form.formCode),
        data: form.toUpdateBody(),
        fromJson: EapFormConfig.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.updateForm: $e');
      rethrow;
    }
  }

  Future<void> deleteForm(String formCode) async {
    try {
      final response = await client.delete(EapApiPaths.form(formCode));
      if (!isHttpSuccess(response.statusCode)) {
        final msg = envelopeMessage(response.data)?.trim();
        throw StateError(
          msg == null || msg.isEmpty
              ? '서식 삭제에 실패했습니다 (${response.statusCode})'
              : msg,
        );
      }
    } catch (e) {
      debugPrint('EapApiService.deleteForm: $e');
      rethrow;
    }
  }

  Future<EapFormConfig?> getForm(String formCode) async {
    try {
      return await getDataOrNull(
        EapApiPaths.form(formCode),
        fromJson: EapFormConfig.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.getForm: $e');
      return null;
    }
  }

  Future<List<EapDocument>> listDocuments(String folder) async {
    try {
      final r = await client.get(
        EapApiPaths.documents,
        queryParameters: {'folder': folder},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        final msg = envelopeMessage(r.data)?.trim();
        throw StateError(
          msg == null || msg.isEmpty
              ? '문서 목록 조회에 실패했습니다 (${r.statusCode})'
              : msg,
        );
      }
      return parseDataList(r.data, EapDocument.fromJson);
    } on DioException catch (e) {
      throw StateError(dioErrorMessage(e, fallback: '문서 목록 조회에 실패했습니다.'));
    }
  }

  Future<EapDocument?> getDocument(String docId) async {
    try {
      return await getDataOrNull(
        EapApiPaths.document(docId),
        fromJson: EapDocument.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.getDocument: $e');
      return null;
    }
  }

  Future<EapDraftResult?> draft(EapDraftRequest request) async {
    try {
      return await postDataOrNull(
        EapApiPaths.draft,
        data: request.toJson(),
        fromJson: EapDraftResult.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.draft: $e');
      rethrow;
    }
  }

  Future<EapDocument> approve(String docId) async {
    return postData(
      EapApiPaths.approve(docId),
      data: const <String, dynamic>{},
      fromJson: EapDocument.fromJson,
    );
  }

  Future<EapDocument> reject(String docId) async {
    return postData(
      EapApiPaths.reject(docId),
      data: const <String, dynamic>{},
      fromJson: EapDocument.fromJson,
    );
  }

  Future<void> deleteDocument(String docId) async {
    try {
      final response = await client.delete(EapApiPaths.document(docId));
      if (!isHttpSuccess(response.statusCode)) {
        final msg = envelopeMessage(response.data)?.trim();
        throw StateError(
          msg == null || msg.isEmpty
              ? '문서 삭제에 실패했습니다 (${response.statusCode})'
              : msg,
        );
      }
    } catch (e) {
      debugPrint('EapApiService.deleteDocument: $e');
      rethrow;
    }
  }
}
