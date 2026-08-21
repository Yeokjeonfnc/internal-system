// 전자결재 홈 — 받은/올린 건수와 문서함 미리보기를 한 화면에 보여 준다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_widgets.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001HomeView extends ConsumerWidget {
  const Eap001HomeView({super.key});

  static const _previewLimit = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = provider.Provider.of<AuthProvider>(context).userId;
    final pending = ref.watch(
      eapDocumentsProvider(eapDocListKey(uid, 'inbox-pending')),
    );
    final inboxDone = ref.watch(
      eapDocumentsProvider(eapDocListKey(uid, 'inbox-complete')),
    );
    final inboxReject = ref.watch(
      eapDocumentsProvider(eapDocListKey(uid, 'inbox-rejected')),
    );
    final sent = ref.watch(eapDocumentsProvider(eapDocListKey(uid, 'sent')));
    final temp = ref.watch(
      eapDocumentsProvider(eapDocListKey(uid, 'sent-temp')),
    );
    final cc = ref.watch(eapDocumentsProvider(eapDocListKey(uid, 'cc')));
    final asyncs = [pending, inboxDone, inboxReject, sent, temp, cc];

    Future<void> refresh() async {
      for (final folder in const [
        'inbox-pending',
        'inbox-complete',
        'inbox-rejected',
        'sent',
        'sent-temp',
        'cc',
      ]) {
        ref.invalidate(eapDocumentsProvider(eapDocListKey(uid, folder)));
      }
      await Future.wait([
        ref.read(
          eapDocumentsProvider(eapDocListKey(uid, 'inbox-pending')).future,
        ),
        ref.read(
          eapDocumentsProvider(eapDocListKey(uid, 'inbox-complete')).future,
        ),
        ref.read(
          eapDocumentsProvider(eapDocListKey(uid, 'inbox-rejected')).future,
        ),
        ref.read(eapDocumentsProvider(eapDocListKey(uid, 'sent')).future),
        ref.read(eapDocumentsProvider(eapDocListKey(uid, 'sent-temp')).future),
        ref.read(eapDocumentsProvider(eapDocListKey(uid, 'cc')).future),
      ]);
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailScreenHeadline.plain(text: '전자결재'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: asyncs.any((a) => a.isLoading && !a.hasValue)
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : asyncs.every((a) => a.hasError)
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EapEmptyBanner(
                          message: _homeErrorMessage(asyncs.first.error),
                        ),
                      ],
                    )
                  : _HomeBody(
                      pending: pending.value ?? const [],
                      inboxDone: inboxDone.value ?? const [],
                      inboxReject: inboxReject.value ?? const [],
                      sent: sent.value ?? const [],
                      temp: temp.value ?? const [],
                      cc: cc.value ?? const [],
                      previewLimit: _previewLimit,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _homeErrorMessage(Object? error) {
  final raw = error?.toString() ?? '';
  if (raw.contains('로그인')) {
    return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
  }
  if (raw.contains('권한')) {
    return '전자결재 조회 권한이 없습니다.';
  }
  if (raw.contains('서버 오류') || raw.contains('500')) {
    return '전자결재 서버 오류입니다. 백엔드를 재시작한 뒤 다시 로그인해 주세요.';
  }
  if (raw.contains('네트워크') || raw.contains('연결')) {
    return '네트워크 연결을 확인해 주세요.';
  }
  return '전자결재 현황을 불러오지 못했습니다. 백엔드 재시작 후 다시 로그인해 주세요.';
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.pending,
    required this.inboxDone,
    required this.inboxReject,
    required this.sent,
    required this.temp,
    required this.cc,
    required this.previewLimit,
  });

  final List<EapDocument> pending;
  final List<EapDocument> inboxDone;
  final List<EapDocument> inboxReject;
  final List<EapDocument> sent;
  final List<EapDocument> temp;
  final List<EapDocument> cc;
  final int previewLimit;

  List<EapDocument> get _sentOpen => sent
      .where(
        (d) =>
            d.status == EapDocStatus.inProgress ||
            d.status == EapDocStatus.draft ||
            d.status == EapDocStatus.writing,
      )
      .toList();

  List<EapDocument> get _sentDone =>
      sent.where((d) => d.status == EapDocStatus.complete).toList();

  List<EapDocument> get _sentReject =>
      sent.where((d) => d.status == EapDocStatus.returned).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        AppDimensions.listScreenBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _receivedGroup(context)),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _sentGroup(context)),
            ],
          ),
          const SizedBox(height: 20),
          _PreviewSection(
            title: '결재대기 문서',
            morePath: EapRoutes.inbox,
            documents: pending,
            limit: previewLimit,
            columns: _PreviewColumns.standard,
          ),
          _PreviewSection(
            title: '임시보관',
            morePath: EapRoutes.sent,
            documents: temp,
            limit: previewLimit,
            columns: _PreviewColumns.temp,
          ),
          _PreviewSection(
            title: '상신 문서',
            morePath: EapRoutes.sent,
            documents: _sentOpen,
            limit: previewLimit,
            columns: _PreviewColumns.standard,
          ),
          _PreviewSection(
            title: '수신 및 참조',
            morePath: EapRoutes.cc,
            documents: cc,
            limit: previewLimit,
            columns: _PreviewColumns.cc,
          ),
        ],
      ),
    );
  }

  Widget _receivedGroup(BuildContext context) {
    return _EapHomeSummaryRow(
      title: '받은결재',
      tiles: [
        _CountTile(
          label: '결재대기 문서',
          count: pending.length,
          onTap: () => context.go(EapRoutes.inbox),
        ),
        _CountTile(
          label: '결재완료 문서',
          count: inboxDone.length,
          onTap: () => context.go(EapRoutes.inbox),
        ),
        _CountTile(
          label: '반려 문서',
          count: inboxReject.length,
          onTap: () => context.go(EapRoutes.inbox),
        ),
        _CountTile(
          label: '참조·열람',
          count: cc.length,
          onTap: () => context.go(EapRoutes.cc),
        ),
      ],
    );
  }

  Widget _sentGroup(BuildContext context) {
    return _EapHomeSummaryRow(
      title: '올린결재',
      tiles: [
        _CountTile(
          label: '상신 문서',
          count: _sentOpen.length,
          onTap: () => context.go(EapRoutes.sent),
        ),
        _CountTile(
          label: '결재완료 문서',
          count: _sentDone.length,
          onTap: () => context.go(EapRoutes.sent),
        ),
        _CountTile(
          label: '임시 보관',
          count: temp.length,
          onTap: () => context.go(EapRoutes.sent),
        ),
        _CountTile(
          label: '반려 문서',
          count: _sentReject.length,
          onTap: () => context.go(EapRoutes.sent),
        ),
      ],
    );
  }
}

class _EapHomeSummaryRow extends StatelessWidget {
  const _EapHomeSummaryRow({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.appSurface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 245, 137, 137),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '총 $count건',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 70, 70, 70),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PreviewColumns { standard, temp, cc }

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.title,
    required this.morePath,
    required this.documents,
    required this.limit,
    required this.columns,
  });

  final String title;
  final String morePath;
  final List<EapDocument> documents;
  final int limit;
  final _PreviewColumns columns;

  @override
  Widget build(BuildContext context) {
    final rows = documents.take(limit).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.chromeBlack,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(morePath),
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _PreviewTable(documents: rows, columns: columns),
        ],
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.documents, required this.columns});

  final List<EapDocument> documents;
  final _PreviewColumns columns;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.hairline),
        ),
        alignment: Alignment.center,
        child: const Text(
          '표시할 데이터가 없습니다',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }

    final minWidth = switch (columns) {
      _PreviewColumns.temp => 640.0,
      _PreviewColumns.cc => 860.0,
      _PreviewColumns.standard => 920.0,
    };

    return ErpDataTable(
      minWidth: minWidth,
      tableBuilder: (context, width) {
        return Table(
          columnWidths: erpTableColumnWidths(context, _widths),
          border: kErpTableInnerGridBorder,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: kErpTableHeaderRowDecoration,
              children: [for (final h in _headers) ErpTableHeaderCell(h)],
            ),
            for (var i = 0; i < documents.length; i++)
              _row(context, documents[i], i),
          ],
        );
      },
    );
  }

  List<String> get _headers => switch (columns) {
    _PreviewColumns.temp => const ['문서분류', '제목', '작성일'],
    _PreviewColumns.cc => const ['품의번호', '문서분류', '제목', '기안자', '기안일자'],
    _PreviewColumns.standard => const [
      '품의번호',
      '문서분류',
      '제목',
      '기안자',
      '기안일자',
      '상태',
    ],
  };

  Map<int, TableColumnWidth> get _widths => switch (columns) {
    _PreviewColumns.temp => const {
      0: FixedColumnWidth(120),
      1: FlexColumnWidth(3),
      2: FixedColumnWidth(110),
    },
    _PreviewColumns.cc => const {
      0: FixedColumnWidth(130),
      1: FixedColumnWidth(110),
      2: FlexColumnWidth(3),
      3: FixedColumnWidth(100),
      4: FixedColumnWidth(110),
    },
    _PreviewColumns.standard => const {
      0: FixedColumnWidth(130),
      1: FixedColumnWidth(110),
      2: FlexColumnWidth(3),
      3: FixedColumnWidth(100),
      4: FixedColumnWidth(110),
      5: FixedColumnWidth(88),
    },
  };

  TableRow _row(BuildContext context, EapDocument doc, int index) {
    final bg = index.isEven ? AppTheme.tableRowEven : AppTheme.tableRowOdd;
    Widget cell(Widget child) {
      return ErpTableDoubleTapCell(
        onDoubleTap: () => EapRoutes.openDocument(context, doc),
        child: child,
      );
    }

    final title = cell(
      _PreviewTitle(
        title: doc.title,
        onTap: () => EapRoutes.openDocument(context, doc),
      ),
    );

    final children = switch (columns) {
      _PreviewColumns.temp => [
        cell(ErpTableBodyCell(doc.formCategory, center: true)),
        title,
        cell(ErpTableBodyCell(doc.draftDateLabel, center: true)),
      ],
      _PreviewColumns.cc => [
        cell(
          ErpTableBodyCell(doc.docNum.isEmpty ? '-' : doc.docNum, center: true),
        ),
        cell(ErpTableBodyCell(doc.formCategory, center: true)),
        title,
        cell(
          ErpTableBodyCell(
            doc.drafterName.isEmpty ? '-' : doc.drafterName,
            center: true,
          ),
        ),
        cell(ErpTableBodyCell(doc.draftDateLabel, center: true)),
      ],
      _PreviewColumns.standard => [
        cell(
          ErpTableBodyCell(doc.docNum.isEmpty ? '-' : doc.docNum, center: true),
        ),
        cell(ErpTableBodyCell(doc.formCategory, center: true)),
        title,
        cell(
          ErpTableBodyCell(
            doc.drafterName.isEmpty ? '-' : doc.drafterName,
            center: true,
          ),
        ),
        cell(ErpTableBodyCell(doc.draftDateLabel, center: true)),
        cell(EapStatusBadge(status: doc.status)),
      ],
    };

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: children,
    );
  }
}

class _PreviewTitle extends StatelessWidget {
  const _PreviewTitle({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2563C7),
            fontWeight: FontWeight.w500,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
