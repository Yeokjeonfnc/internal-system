// 전자결재 문서 상세 — 본문·결재선·첨부 확인.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/data/mock/mock_eap_documents.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001DetailView extends StatelessWidget {
  const Eap001DetailView({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context) {
    final doc = MockEapDocuments.find(docId);
    if (doc == null) {
      return ColoredBox(
        color: AppTheme.appSurface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '문서를 찾을 수 없습니다.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(EapRoutes.home),
                child: const Text('전자결재 홈으로'),
              ),
            ],
          ),
        ),
      );
    }

    return DetailScreenScrollBody(
      title: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: '목록으로',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                doc.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            EapStatusBadge(status: doc.status),
            const SizedBox(width: 8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaCard(doc: doc),
          const SizedBox(height: 12),
          _ContentCard(doc: doc),
          if (doc.attachmentCount > 0) ...[
            const SizedBox(height: 12),
            _AttachmentCard(count: doc.attachmentCount),
          ],
          const SizedBox(height: 12),
          _ApprovalLineCard(status: doc.status),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '문서 정보',
      child: Column(
        children: [
          _metaRow('문서번호', doc.docNum.isEmpty ? '(미부여)' : doc.docNum),
          _metaRow('결재양식', doc.formName),
          _metaRow('기안일', doc.draftDateLabel),
          _metaRow('기안자', doc.drafterName.isEmpty ? '-' : doc.drafterName),
          _metaRow('긴급', doc.urgent ? 'Y' : 'N'),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '본문',
      child: SelectableText(
        doc.contentHtml,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppTheme.textSecondary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '첨부파일',
      child: Column(
        children: List.generate(
          count,
          (i) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file, size: 20),
            title: Text('첨부_${i + 1}.pdf'),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('다우오피스 연동 후 첨부 다운로드가 가능합니다.'),
                  ),
                );
              },
              child: const Text('보기'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovalLineCard extends StatelessWidget {
  const _ApprovalLineCard({required this.status});

  final EapDocStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('기안', true),
      ('검토', status != EapDocStatus.draft),
      ('승인', status == EapDocStatus.complete),
    ];

    return _SectionCard(
      title: '결재선',
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: steps[i].$2 ? AppTheme.accentRed : AppTheme.hairline,
                ),
              ),
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: steps[i].$2
                      ? AppTheme.accentRed
                      : AppTheme.chipNeutralBackground,
                  child: Icon(
                    steps[i].$2 ? Icons.check : Icons.person_outline,
                    size: 16,
                    color: steps[i].$2 ? Colors.white : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i].$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        steps[i].$2 ? FontWeight.w600 : FontWeight.w500,
                    color: steps[i].$2
                        ? AppTheme.accentRed
                        : AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
