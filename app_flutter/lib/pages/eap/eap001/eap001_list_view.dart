// 전자결재 문서함 목록 — 폴더별 문서 테이블.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/data/mock/mock_eap_documents.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001ListView extends StatelessWidget {
  const Eap001ListView({super.key, required this.path});

  final String path;

  List<EapDocument> _documents() {
    return switch (path) {
      EapRoutes.pending => MockEapDocuments.pendingForMe(),
      EapRoutes.received => MockEapDocuments.inProgress(),
      EapRoutes.ccPending => MockEapDocuments.inProgress(),
      EapRoutes.scheduled => [],
      EapRoutes.drafted => MockEapDocuments.drafted(),
      EapRoutes.tempSaved => MockEapDocuments.tempSaved(),
      EapRoutes.approved => MockEapDocuments.completed(),
      EapRoutes.ccRead => MockEapDocuments.completed(),
      EapRoutes.inbox => [],
      EapRoutes.sent => MockEapDocuments.drafted(),
      EapRoutes.official => [],
      _ => [],
    };
  }

  bool get _showDocNum =>
      path == EapRoutes.approved ||
      path == EapRoutes.ccRead ||
      path == EapRoutes.sent;

  @override
  Widget build(BuildContext context) {
    final docs = _documents();
    final title = EapRoutes.titleFor(path);
    void openDoc(EapDocument doc) => EapRoutes.openDocument(context, doc);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EapPageHeader(title: title),
            if (docs.isEmpty)
              EapEmptyBanner(message: '$title에 표시할 문서가 없습니다'),
            EapDocumentTable(
              documents: docs,
              showDocNum: _showDocNum,
              onRowTap: openDoc,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
