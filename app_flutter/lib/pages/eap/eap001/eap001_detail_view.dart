// 전자결재 문서 상세 — 왼쪽 본문 / 오른쪽 결재선·문서정보.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/active/act002/act002_approval_table.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_approval_line.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_content_html_preview.dart';
import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_quill.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001DetailView extends ConsumerWidget {
  const Eap001DetailView({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(eapDocumentDetailProvider(docId));

    return docAsync.when(
      loading: () => const ColoredBox(
        color: AppTheme.appSurface,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => _notFound(context),
      data: (doc) {
        if (doc == null) return _notFound(context);
        final uid = provider.Provider.of<AuthProvider>(
          context,
          listen: false,
        ).userId;
        final isAdmin = provider.Provider.of<AuthProvider>(
          context,
          listen: false,
        ).isSuperAdmin;
        final showApprove = doc.canActAs(uid);
        return ColoredBox(
          color: AppTheme.appSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EapDetailToolbar(
                title: doc.title,
                status: doc.status,
                showApprove: showApprove,
                showDelete: isAdmin,
                onBack: () => context.pop(),
                onDelete: () => _delete(context, ref, doc),
                onReject: () => _reject(context, ref, doc),
                onApprove: () => _approve(context, ref, doc),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _EapDetailSplitBody(doc: doc),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EapDocument doc,
  ) async {
    final ok = await IframePointerGate.whileBlocked(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('문서 삭제'),
          content: Text('「${doc.title}」 문서를 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(eapApiProvider).deleteDocument(doc.docId);
      ref.invalidate(eapDocumentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문서를 삭제했습니다.')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiUserMessage(e, fallback: '문서 삭제에 실패했습니다.')),
        ),
      );
    }
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    EapDocument doc,
  ) async {
    final ok = await IframePointerGate.whileBlocked(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('결재하기'),
          content: const Text('이 문서를 결재하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('결재'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(eapApiProvider).approve(doc.docId);
      ref.invalidate(eapDocumentDetailProvider(docId));
      ref.invalidate(eapDocumentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결재했습니다.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiUserMessage(e, fallback: '결재에 실패했습니다.')),
        ),
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    EapDocument doc,
  ) async {
    final ok = await IframePointerGate.whileBlocked(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('반려'),
          content: const Text('이 문서를 반려하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
              ),
              child: const Text('반려'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(eapApiProvider).reject(doc.docId);
      ref.invalidate(eapDocumentDetailProvider(docId));
      ref.invalidate(eapDocumentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반려했습니다.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiUserMessage(e, fallback: '반려에 실패했습니다.')),
        ),
      );
    }
  }

  Widget _notFound(BuildContext context) {
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
              onPressed: () => context.go(EapRoutes.compose),
              child: const Text('전자결재 홈으로'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EapDetailToolbar extends StatelessWidget {
  const _EapDetailToolbar({
    required this.title,
    required this.status,
    required this.showApprove,
    required this.showDelete,
    required this.onBack,
    required this.onDelete,
    required this.onReject,
    required this.onApprove,
  });

  final String title;
  final EapDocStatus status;
  final bool showApprove;
  final bool showDelete;
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: '목록으로',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EapStatusBadge(status: status),
          if (showDelete) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
              ),
              child: const Text('삭제'),
            ),
          ],
          if (showApprove) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
              ),
              child: const Text('반려'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onApprove,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('결재하기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EapDetailSplitBody extends StatefulWidget {
  const _EapDetailSplitBody({required this.doc});

  final EapDocument doc;

  @override
  State<_EapDetailSplitBody> createState() => _EapDetailSplitBodyState();
}

class _EapDetailSplitBodyState extends State<_EapDetailSplitBody> {
  var _sideOpen = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _EapDocPreviewPane(doc: widget.doc)),
        _EapSideToggle(
          open: _sideOpen,
          onTap: () => setState(() => _sideOpen = !_sideOpen),
        ),
        if (_sideOpen)
          SizedBox(width: 340, child: _EapDetailSidePanel(doc: widget.doc)),
      ],
    );
  }
}

class _EapSideToggle extends StatelessWidget {
  const _EapSideToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 22,
          child: Center(
            child: Icon(
              open ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 20,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EapDocPreviewPane extends StatelessWidget {
  const _EapDocPreviewPane({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    final raw = eapFormBodyHtml(doc.contentHtml);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E4),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                        child: _EapDetailApprovalTable(
                          doc: doc,
                          embedInDocument: true,
                        ),
                      ),
                      if (raw.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              '저장된 본문이 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                                fontFamilyFallback: AppTheme.koreanFontFallback,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                            child: eapContentHtmlPreview(
                              raw,
                              seamless: true,
                              readOnly: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EapDetailApprovalTable extends StatelessWidget {
  const _EapDetailApprovalTable({
    required this.doc,
    this.embedInDocument = false,
  });

  final EapDocument doc;
  final bool embedInDocument;

  static List<String> _slots(List<String> values) {
    return List<String>.generate(
      kActivityApprovalLineSlotCount,
      (i) => i < values.length ? values[i] : '',
    );
  }

  static List<EapLineMember> _role(EapDocument doc, String role) {
    final rows = doc.lines
        .where((e) => e.roleCd.toUpperCase() == role)
        .toList();
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows;
  }

  static bool _samePerson(EapLineMember a, EapLineMember b) {
    final aid = a.userId.trim().toUpperCase();
    final bid = b.userId.trim().toUpperCase();
    if (aid.isNotEmpty && bid.isNotEmpty && aid == bid) return true;
    final an = a.userNm.trim().toUpperCase();
    final bn = b.userNm.trim().toUpperCase();
    return an.isNotEmpty && bn.isNotEmpty && an == bn;
  }

  static List<EapLineMember> _withoutTaken(
    List<EapLineMember> rows,
    List<EapLineMember> taken,
  ) {
    return rows.where((e) => !taken.any((t) => _samePerson(e, t))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final approvers = _role(doc, 'APPROVER');
    final agreers = _withoutTaken(_role(doc, 'AGREE'), approvers);
    final drafterNm = doc.drafterName.trim().isEmpty
        ? doc.draftUserId
        : doc.drafterName.trim();

    final approvalNames = _slots(
      approvers
          .map((e) => e.userNm.trim().isEmpty ? e.userId : e.userNm)
          .toList(),
    );
    final approvalTitles = _slots(approvers.map((e) => e.titleNm).toList());
    final approvalIds = _slots(approvers.map((e) => e.userId).toList());

    final ackIds = <String>{};
    final ackDates = <String, String>{};
    for (final m in doc.lines) {
      if (m.lineStatus.toUpperCase() != 'DONE') continue;
      final role = m.roleCd.toUpperCase();
      if (role != 'APPROVER' && role != 'AGREE') continue;
      final uid = m.userId.trim();
      if (uid.isEmpty) continue;
      ackIds.add(uid);
      final day = m.actedDateLabel;
      if (day.isNotEmpty) ackDates[uid] = day;
    }

    return ApprovalInfoTable(
      approvalStampSlots: approvalNames,
      rankStampSlots: approvalTitles,
      approvalUserIds: approvalIds,
      apprAckUserIds: ackIds,
      apprAckDateByUserId: ackDates,
      documentWrittenAt: doc.draftDateLabel,
      writerSealDate: '',
      loadedApprStatus: null,
      deptNm: doc.drafterDept.trim().isEmpty ? '-' : doc.drafterDept.trim(),
      drafterNm: drafterNm,
      rankUnderName: true,
      approvalSlot0IsDrafter: false,
      embedInDocument: embedInDocument,
      extraNameRows: [
        ApprovalInfoNameRow(
          label: '합의자',
          names: _slots(
            agreers
                .map((e) => e.userNm.trim().isEmpty ? e.userId : e.userNm)
                .toList(),
          ),
          titles: _slots(agreers.map((e) => e.titleNm).toList()),
          userIds: _slots(agreers.map((e) => e.userId).toList()),
          useSeals: true,
        ),
      ],
    );
  }
}

class _EapDetailSidePanel extends StatelessWidget {
  const _EapDetailSidePanel({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DetailMainTabBar(tabTitles: ['결재선', '문서정보']),
            Expanded(
              child: Builder(
                builder: (context) {
                  final controller = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return IndexedStack(
                        index: controller.index,
                        children: [
                          _EapLineTimeline(doc: doc),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                            child: _DocMetaList(doc: doc),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EapLineTimeline extends StatelessWidget {
  const _EapLineTimeline({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _EapLinePersonTile(
        name: doc.drafterName.isEmpty ? doc.draftUserId : doc.drafterName,
        subtitle: '기안',
        statusText: '기안 상신',
        timeText: doc.draftDateTimeLabel,
        done: true,
      ),
      for (final m in doc.lines)
        _EapLinePersonTile(
          name: m.displayName,
          subtitle: m.roleLabel,
          statusText: m.actionLabel,
          timeText: m.actedAtLabel,
          done: m.lineStatus.toUpperCase() == 'DONE',
          rejected: m.lineStatus.toUpperCase() == 'REJECT',
        ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(left: 18),
        child: SizedBox(
          height: 10,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 1,
              height: 10,
              child: ColoredBox(color: AppTheme.hairline),
            ),
          ),
        ),
      ),
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _EapLinePersonTile extends StatelessWidget {
  const _EapLinePersonTile({
    required this.name,
    required this.subtitle,
    required this.statusText,
    required this.timeText,
    this.done = false,
    this.rejected = false,
  });

  final String name;
  final String subtitle;
  final String statusText;
  final String timeText;
  final bool done;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final statusColor = rejected
        ? AppTheme.accentRed
        : done
        ? AppTheme.statusNew
        : AppTheme.statusPending;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.chipNeutralBackground,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeText.isEmpty ? statusText : '$statusText  |  $timeText',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocMetaList extends StatelessWidget {
  const _DocMetaList({required this.doc});

  final EapDocument doc;

  @override
  Widget build(BuildContext context) {
    final updated = doc.updatedDateTimeLabel;
    return Column(
      children: [
        _metaRow('문서번호', doc.docNum.isEmpty ? '(미부여)' : doc.docNum),
        _metaRow('결재양식', doc.formName),
        if (doc.formCategory.isNotEmpty) _metaRow('문서분류', doc.formCategory),
        if (doc.formCode.isNotEmpty) _metaRow('양식코드', doc.formCode),
        _metaRow('기안일시', doc.draftDateTimeLabel),
        if (updated != null) _metaRow('수정일시', updated),
        _metaRow('기안자', doc.drafterName.isEmpty ? '-' : doc.drafterName),
        _metaRow('상태', doc.status.label),
        _metaRow('긴급', doc.urgent ? 'Y' : 'N'),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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
