// 전자결재 문서함 목록 — API 연동.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001ListView extends ConsumerWidget {
  const Eap001ListView({super.key, required this.path});

  final String path;

  bool get _showDocNum =>
      path == EapRoutes.approved ||
      path == EapRoutes.ccRead ||
      path == EapRoutes.sent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(eapDocumentsProvider(path));
    final title = EapRoutes.titleFor(path);

    Future<void> refresh() async {
      ref.invalidate(eapDocumentsProvider(path));
      ref.invalidate(eapHomeSummaryProvider);
      await ref.read(eapDocumentsProvider(path).future);
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EapPageHeader(
                title: title,
                trailing: IconButton(
                  tooltip: '새로고침',
                  onPressed: () => refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                ),
              ),
              docsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => EapEmptyBanner(
                  message: '$title 조회에 실패했습니다',
                ),
                data: (docs) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (docs.isEmpty)
                        EapEmptyBanner(message: '$title에 표시할 문서가 없습니다'),
                      EapDocumentTable(
                        documents: docs,
                        showDocNum: _showDocNum,
                        onRowTap: (doc) =>
                            EapRoutes.openDocument(context, doc),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
