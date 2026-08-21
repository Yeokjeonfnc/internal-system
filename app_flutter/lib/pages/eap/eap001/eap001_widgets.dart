// 전자결재 화면 공용 위젯 — 좌측 네비·문서 테이블·상태 뱃지.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

class EapPageHeader extends StatelessWidget {
  const EapPageHeader({
    super.key,
    required this.title,
    this.showSearch = true,
    this.trailing,
  });

  final String title;
  final bool showSearch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 14, compact ? 12 : 18, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.chromeBlack,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const Spacer(),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 4),
          ],
          if (showSearch && !compact)
            SizedBox(
              width: 280,
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '전자결재 검색',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPlaceholder,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EapEmptyBanner extends StatelessWidget {
  const EapEmptyBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.chipNeutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EapSectionTitle extends StatelessWidget {
  const EapSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EapDocumentTable extends StatelessWidget {
  const EapDocumentTable({
    super.key,
    required this.documents,
    this.onRowDoubleTap,
  });

  final List<EapDocument> documents;
  final void Function(EapDocument doc)? onRowDoubleTap;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: ErpDataTable(
        minWidth: 920,
        tableBuilder: (context, width) {
          const cols = <int, TableColumnWidth>{
            0: FixedColumnWidth(130),
            1: FixedColumnWidth(110),
            2: FlexColumnWidth(3),
            3: FixedColumnWidth(100),
            4: FixedColumnWidth(110),
            5: FixedColumnWidth(88),
          };

          return Table(
            columnWidths: erpTableColumnWidths(context, cols),
            border: kErpTableInnerGridBorder,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: kErpTableHeaderRowDecoration,
                children: [
                  ErpTableHeaderCell('품의번호'),
                  ErpTableHeaderCell('문서분류'),
                  ErpTableHeaderCell('제목'),
                  ErpTableHeaderCell('기안자'),
                  ErpTableHeaderCell('기안일자'),
                  ErpTableHeaderCell('상태'),
                ],
              ),
              for (var i = 0; i < documents.length; i++)
                _docRow(context, documents[i], i),
            ],
          );
        },
      ),
    );
  }

  TableRow _docRow(BuildContext context, EapDocument doc, int index) {
    final bg = index.isEven ? AppTheme.tableRowEven : AppTheme.tableRowOdd;
    Widget cell(Widget child) {
      return ErpTableDoubleTapCell(
        onDoubleTap: () => onRowDoubleTap?.call(doc),
        child: child,
      );
    }

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        cell(ErpTableBodyCell(
          doc.docNum.isEmpty ? '-' : doc.docNum,
          center: true,
        )),
        cell(ErpTableBodyCell(doc.formCategory, center: true)),
        cell(_TitleCell(
          title: doc.title,
          onTap: () => onRowDoubleTap?.call(doc),
        )),
        cell(ErpTableBodyCell(
          doc.drafterName.isEmpty ? '-' : doc.drafterName,
          center: true,
        )),
        cell(ErpTableBodyCell(doc.draftDateLabel, center: true)),
        cell(EapStatusBadge(status: doc.status)),
      ],
    );
  }
}

class _TitleCell extends StatelessWidget {
  const _TitleCell({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 8,
        vertical: compact ? 4 : 6,
      ),
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

class EapStatusBadge extends StatelessWidget {
  const EapStatusBadge({super.key, required this.status});

  final EapDocStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      EapDocStatus.writing => (
          const Color(0xFFFFF7E8),
          const Color(0xFFB45309),
        ),
      EapDocStatus.inProgress => (
          const Color(0xFFE8F5EC),
          const Color(0xFF1E8E4E),
        ),
      EapDocStatus.complete => (
          AppTheme.chipNeutralBackground,
          AppTheme.textSecondary,
        ),
      EapDocStatus.returned => (
          const Color(0xFFFDEEEE),
          AppTheme.accentRed,
        ),
      EapDocStatus.cancelled => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
        ),
      EapDocStatus.tempSave => (
          const Color(0xFFEFF6FF),
          const Color(0xFF2563C7),
        ),
      _ => (
          AppTheme.chipNeutralBackground,
          AppTheme.textMuted,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ),
    );
  }
}

