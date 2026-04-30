// 임시보관(동일 열) — [ErpDataTable].

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/features/activities/activity_api_service.dart';
import 'package:app_flutter/features/activities/activity_routes.dart';

/// 활동관리·활동관리결재 목록이 공유하는 임시보관 격자.
class ActivityDraftsTable extends StatefulWidget {
  const ActivityDraftsTable({super.key});

  @override
  State<ActivityDraftsTable> createState() => _ActivityDraftsTableState();
}

class _ActivityDraftsTableState extends State<ActivityDraftsTable> {
  late Future<List<Map<String, dynamic>>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _draftsFuture = ActivityApiService().getActivities(apprStatus: 'DRAFT');
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    Map<String, dynamic> row,
  ) async {
    final actIdx = _intValue(row['actIdx']);
    if (actIdx == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('임시보관 삭제'),
        content: Text('${_text(row['storeNm'])} 임시보관 데이터를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ActivityApiService().deleteActivity(actIdx);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(deleted ? '삭제되었습니다.' : '삭제에 실패했습니다.')),
    );
    if (deleted) {
      setState(_refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return const Center(child: Text('임시보관된 활동관리가 없습니다.'));
        }
        return ErpDataTable(
          minWidth: AppDimensions.tableMinWidthDefault + 400,
          tableBuilder: (context, w) => Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: kErpTableInnerGridBorder,
            columnWidths: const {
              0: FlexColumnWidth(0.45),
              1: FlexColumnWidth(0.5),
              2: FlexColumnWidth(0.4),
              3: FlexColumnWidth(0.55),
              4: FlexColumnWidth(0.5),
              5: FlexColumnWidth(0.95),
              6: FlexColumnWidth(0.5),
              7: FlexColumnWidth(0.35),
              8: FlexColumnWidth(0.4),
              9: FlexColumnWidth(0.55),
              10: FlexColumnWidth(0.4),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.accentRed),
                children: [
                  ErpTableHeaderCell('활동구분'),
                  ErpTableHeaderCell('활동일자'),
                  ErpTableHeaderCell('브랜드'),
                  ErpTableHeaderCell('가맹점명'),
                  ErpTableHeaderCell('부진점 판별결과'),
                  ErpTableHeaderCell('주요상담내용'),
                  ErpTableHeaderCell('담당 수퍼바이저'),
                  ErpTableHeaderCell('체크리스트'),
                  ErpTableHeaderCell('결재상태'),
                  ErpTableHeaderCell('상세보기'),
                  ErpTableHeaderCell('삭제'),
                ],
              ),
              for (final row in rows)
                TableRow(
                  decoration: const BoxDecoration(color: AppTheme.tableRowOdd),
                  children: [
                    ErpTableBodyCell(_text(row['actType']), center: true),
                    ErpTableBodyCell(_dateText(row['actDt']), center: true),
                    ErpTableBodyCell(
                      _text(row['brandNm'] ?? row['brandCd']),
                      center: true,
                    ),
                    ErpTableBodyCell(_text(row['storeNm']), center: true),
                    const ErpTableBodyCell('-'),
                    ErpTableBodyCell(_text(row['actNotes'])),
                    ErpTableBodyCell(_text(row['svId']), center: true),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(child: _ChecklistStatusChip(row['chkYn'])),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: _ApprovalStatusChip(row['apprStatus']),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: DetailButton(
                          onPressed: () {
                            final actIdx = _intValue(row['actIdx']);
                            if (actIdx == null) return;
                            context.go(ActivityRoutes.draftDetail(actIdx));
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: _ActivityDeleteButton(
                          onPressed: () => _confirmAndDelete(context, row),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  static String _dateText(dynamic value) {
    final text = _text(value);
    if (text == '-') return text;
    return text.split('T').first;
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class _ChecklistStatusChip extends StatelessWidget {
  const _ChecklistStatusChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final done = value?.toString().trim().toUpperCase() == 'Y';
    return _StatusChip(
      label: done ? '작성' : '미작성',
      foreground: done ? const Color(0xFF047857) : const Color(0xFF6B7280),
      background: done ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
      border: done ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
    );
  }
}

class _ApprovalStatusChip extends StatelessWidget {
  const _ApprovalStatusChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    return switch (raw) {
      'PENDING' => const _StatusChip(
        label: '결재대기',
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFF7ED),
        border: Color(0xFFFED7AA),
      ),
      'APPROVED' => const _StatusChip(
        label: '결재완료',
        foreground: Color(0xFF047857),
        background: Color(0xFFD1FAE5),
        border: Color(0xFFA7F3D0),
      ),
      _ => const _StatusChip(
        label: '임시저장',
        foreground: AppTheme.accentRed,
        background: Color(0xFFFFF1F2),
        border: Color(0xFFFECACA),
      ),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _ActivityDeleteButton extends StatelessWidget {
  const _ActivityDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('삭제'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        foregroundColor: AppTheme.accentRed,
        side: const BorderSide(color: AppTheme.accentRed),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}
