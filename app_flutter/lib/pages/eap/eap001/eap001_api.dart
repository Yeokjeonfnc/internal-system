// 전자결재(다우오피스) API.

import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

class EapConnectionTestResult {
  const EapConnectionTestResult({
    required this.erpApiOk,
    required this.daouConfigured,
    required this.daouReachable,
    required this.daouAuthOk,
    required this.daouMessage,
    required this.erpApiBaseUrl,
    required this.daouApiBaseUrl,
    required this.callbackUrl,
    required this.formCode,
  });

  factory EapConnectionTestResult.fromJson(Map<String, dynamic> json) {
    return EapConnectionTestResult(
      erpApiOk: json['erpApiOk'] == true,
      daouConfigured: json['daouConfigured'] == true,
      daouReachable: json['daouReachable'] == true,
      daouAuthOk: json['daouAuthOk'] == true,
      daouMessage: json['daouMessage']?.toString() ?? '',
      erpApiBaseUrl: json['erpApiBaseUrl']?.toString() ?? '',
      daouApiBaseUrl: json['daouApiBaseUrl']?.toString() ?? '',
      callbackUrl: json['callbackUrl']?.toString() ?? '',
      formCode: json['formCode']?.toString() ?? '',
    );
  }

  final bool erpApiOk;
  final bool daouConfigured;
  final bool daouReachable;
  final bool daouAuthOk;
  final String daouMessage;
  final String erpApiBaseUrl;
  final String daouApiBaseUrl;
  final String callbackUrl;
  final String formCode;
}

abstract final class EapApiPaths {
  static const String health = '/eap/health';
  static const String connectionTest = '/eap/connection-test';
  static const String forms = '/eap/forms';
  static String form(String formCode) => '/eap/forms/$formCode';
  static const String documents = '/eap/documents';
  static String document(String docId) => '/eap/documents/$docId';
  static const String draft = '/eap/draft';
}

class EapApiService extends BaseRepository {
  Future<bool> health() async {
    final map = await getDataMapOrNull(EapApiPaths.health);
    return map?['status'] == 'UP';
  }

  Future<EapConnectionTestResult?> connectionTest() async {
    final map = await getDataMapOrNull(EapApiPaths.connectionTest);
    if (map == null) return null;
    return EapConnectionTestResult.fromJson(map);
  }

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

  Future<bool> deleteForm(String formCode) async {
    try {
      final response = await client.delete(EapApiPaths.form(formCode));
      return isHttpSuccess(response.statusCode);
    } catch (e) {
      debugPrint('EapApiService.deleteForm: $e');
      return false;
    }
  }

  Future<List<EapDocument>> listDocuments(String folder) async {
    try {
      return await getDataList(
        EapApiPaths.documents,
        queryParameters: {'folder': folder},
        fromJson: EapDocument.fromJson,
      );
    } catch (e) {
      debugPrint('EapApiService.listDocuments: $e');
      return const [];
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
}
