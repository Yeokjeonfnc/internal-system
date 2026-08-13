// 전자결재 Riverpod — 문서함·양식·기안 (API만 사용).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/eap/eap001/eap001_api.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

final eapApiProvider = Provider<EapApiService>((ref) => EapApiService());

/// folder 경로(`/eap/drafted` 등) → API folder 키.
String eapFolderKeyFromPath(String path) {
  if (path.startsWith('${EapRoutes.root}/')) {
    return path.substring(EapRoutes.root.length + 1);
  }
  return path;
}

final eapDocumentsProvider =
    FutureProvider.family<List<EapDocument>, String>((ref, pathOrFolder) async {
  final folder = eapFolderKeyFromPath(pathOrFolder);
  final api = ref.watch(eapApiProvider);
  return api.listDocuments(folder);
});

final eapDocumentDetailProvider =
    FutureProvider.family<EapDocument?, String>((ref, docId) async {
  final api = ref.watch(eapApiProvider);
  return api.getDocument(docId);
});

final eapFormsProvider = FutureProvider<List<EapFormConfig>>((ref) async {
  final api = ref.watch(eapApiProvider);
  return api.listForms();
});

final eapEnabledFormsProvider = FutureProvider<List<EapFormConfig>>((ref) async {
  final api = ref.watch(eapApiProvider);
  return api.listForms(enabledOnly: true);
});

class EapHomeSummary {
  const EapHomeSummary({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  final List<EapDocument> pending;
  final List<EapDocument> inProgress;
  final List<EapDocument> completed;
}

final eapHomeSummaryProvider = FutureProvider<EapHomeSummary>((ref) async {
  final pending = await ref.watch(eapDocumentsProvider(EapRoutes.pending).future);
  final drafted = await ref.watch(eapDocumentsProvider(EapRoutes.drafted).future);
  final approved = await ref.watch(eapDocumentsProvider(EapRoutes.approved).future);
  final inProgress = drafted
      .where((d) =>
          d.status == EapDocStatus.writing ||
          d.status == EapDocStatus.inProgress ||
          d.status == EapDocStatus.draft ||
          d.status == EapDocStatus.tempSave)
      .toList();
  return EapHomeSummary(
    pending: pending,
    inProgress: inProgress,
    completed: approved,
  );
});
