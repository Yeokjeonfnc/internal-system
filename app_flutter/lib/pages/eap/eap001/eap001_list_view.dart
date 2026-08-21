// 전자결재 문서함 목록 — API 연동. 더블클릭 시 상세.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_filter.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001ListView extends ConsumerWidget {
  const Eap001ListView({
    super.key,
    required this.folder,
    this.emptyMessage,
    this.keyword = '',
  });

  final String folder;
  final String? emptyMessage;
  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = provider.Provider.of<AuthProvider>(context).userId;
    final key = eapDocListKey(uid, folder);
    final docsAsync = ref.watch(eapDocumentsProvider(key));
    final q = keyword.trim();

    Future<void> refresh() async {
      ref.invalidate(eapDocumentsProvider(key));
      await ref.read(eapDocumentsProvider(key).future);
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
              docsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => EapEmptyBanner(
                  message: e is StateError && e.message.contains('로그인')
                      ? '로그인이 만료되었습니다. 다시 로그인해 주세요.'
                      : '문서 조회에 실패했습니다. 백엔드 재시작 후에는 다시 로그인해야 합니다.',
                ),
                data: (docs) {
                  final filtered = eapDocumentsMatchingKeyword(docs, keyword);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (q.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.listScreenHPadding,
                            4,
                            AppDimensions.listScreenHPadding,
                            0,
                          ),
                          child: Text(
                            '총 ${filtered.length}건이 조회되었습니다.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                      if (filtered.isEmpty)
                        EapEmptyBanner(
                          message: q.isNotEmpty && docs.isNotEmpty
                              ? '검색 결과가 없습니다'
                              : (emptyMessage ?? '표시할 문서가 없습니다'),
                        ),
                      EapDocumentTable(
                        documents: filtered,
                        onRowDoubleTap: (doc) =>
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
