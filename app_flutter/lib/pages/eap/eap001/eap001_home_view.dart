// 전자결재 홈 — 다우오피스 홈 화면 레이아웃.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/data/mock/mock_eap_documents.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001HomeView extends StatelessWidget {
  const Eap001HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    void openDoc(EapDocument doc) => EapRoutes.openDocument(context, doc);
    final pending = MockEapDocuments.pendingForMe();
    final inProgress = MockEapDocuments.inProgress();
    final completed = MockEapDocuments.completed();

    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EapPageHeader(title: '전자결재 홈'),
            EapEmptyBanner(
              message: pending.isEmpty
                  ? '결재할 문서가 없습니다'
                  : '결재 대기 ${pending.length}건',
            ),
            const EapSectionTitle(title: '기안 진행 문서'),
            EapDocumentTable(documents: inProgress, onRowTap: openDoc),
            const EapSectionTitle(title: '완료 문서'),
            EapDocumentTable(
              documents: completed,
              showDocNum: true,
              onRowTap: openDoc,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
