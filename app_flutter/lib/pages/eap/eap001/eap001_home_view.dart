// 전자결재 홈 — API 요약.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001HomeView extends ConsumerWidget {
  const Eap001HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(eapHomeSummaryProvider);

    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EapPageHeader(title: '전자결재 홈'),
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => const EapEmptyBanner(message: '홈 요약을 불러오지 못했습니다'),
              data: (summary) {
                void openDoc(doc) => EapRoutes.openDocument(context, doc);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EapEmptyBanner(
                      message: summary.pending.isEmpty
                          ? '결재할 문서가 없습니다'
                          : '결재 대기 ${summary.pending.length}건',
                    ),
                    const EapSectionTitle(title: '기안 진행 문서'),
                    EapDocumentTable(
                      documents: summary.inProgress,
                      onRowTap: openDoc,
                    ),
                    const EapSectionTitle(title: '완료 문서'),
                    EapDocumentTable(
                      documents: summary.completed,
                      showDocNum: true,
                      onRowTap: openDoc,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
