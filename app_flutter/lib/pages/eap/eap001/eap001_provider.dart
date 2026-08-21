// 전자결재 Riverpod — 문서함·양식·기안 (API만 사용).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_api.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

/// 문서함 캐시 키 — 로그인 사용자가 바뀌면 이전 사람 목록을 쓰지 않는다.
typedef EapDocListKey = ({String userId, String folder});

EapDocListKey eapDocListKey(String userId, String folder) =>
    (userId: userId.trim(), folder: folder);

final eapApiProvider = Provider<EapApiService>((ref) => EapApiService());

final eapDocumentsProvider =
    FutureProvider.family<List<EapDocument>, EapDocListKey>((ref, key) async {
      final api = ref.watch(eapApiProvider);
      return api.listDocuments(key.folder);
    });

final eapDocumentDetailProvider = FutureProvider.family<EapDocument?, String>((
  ref,
  docId,
) async {
  final api = ref.watch(eapApiProvider);
  return api.getDocument(docId);
});

final eapFormsProvider = FutureProvider<List<EapFormConfig>>((ref) async {
  final api = ref.watch(eapApiProvider);
  return api.listForms();
});

final eapEnabledFormsProvider = FutureProvider<List<EapFormConfig>>((
  ref,
) async {
  final api = ref.watch(eapApiProvider);
  return api.listForms(enabledOnly: true);
});

final eapFormDetailProvider = FutureProvider.family<EapFormConfig?, String>((
  ref,
  formCode,
) async {
  if (formCode.trim().isEmpty) return null;
  final api = ref.watch(eapApiProvider);
  return api.getForm(formCode);
});
