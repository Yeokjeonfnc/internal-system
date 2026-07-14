// 활동 상신 시 출입 태그 이력 선택.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/usage_log/usage_log_api.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';

/// 미연결 출입 태그 이력 선택. 취소 시 `null`, 선택 시 [UsageLogRow.logIdx].
Future<int?> showActivityTagHistoryPicker({
  required BuildContext context,
  required String userId,
  required int storeIdx,
  required String storeNm,
}) async {
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ActivityTagHistoryPickerDialog(
      userId: userId,
      storeIdx: storeIdx,
      storeNm: storeNm,
    ),
  );
}

class _ActivityTagHistoryPickerDialog extends StatefulWidget {
  const _ActivityTagHistoryPickerDialog({
    required this.userId,
    required this.storeIdx,
    required this.storeNm,
  });

  final String userId;
  final int storeIdx;
  final String storeNm;

  @override
  State<_ActivityTagHistoryPickerDialog> createState() =>
      _ActivityTagHistoryPickerDialogState();
}

class _ActivityTagHistoryPickerDialogState
    extends State<_ActivityTagHistoryPickerDialog> {
  late final Future<List<UsageLogRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = UsageLogApiService().fetchEntryTagsForActivity(
      userId: widget.userId,
      storeIdx: widget.storeIdx,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.75;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: h.clamp(360.0, 640.0),
        ),
        child: Material(
          color: FormStylePalette.panelBg,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErpDialogHeader(
                title: '태그 이력 선택',
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '${widget.storeNm} — 출입 태그 이력을 선택해 주세요.\n선택하지 않으면 상신을 계속할 수 있습니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: FormStylePalette.textSecondary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<UsageLogRow>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CommonLoadingIndicator();
                    }
                    // 태그 후 24시간이 지난 이력은 노출하지 않는다.
                    final cutoff = DateTime.now().subtract(
                      const Duration(hours: 24),
                    );
                    final rows = (snapshot.data ?? const <UsageLogRow>[])
                        .where((r) => r.usedAt.isAfter(cutoff))
                        .toList();
                    if (rows.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '연결할 출입 태그 이력이 없습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: FormStylePalette.textSecondary,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ErpDataTable(
                        minWidth: useCompactErpLayout(context) ? 520 : 640,
                        tableBuilder: (context, width) {
                          return Table(
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            border: kErpTableInnerGridBorder,
                            columnWidths: const {
                              0: FlexColumnWidth(0.9),
                              1: FlexColumnWidth(0.5),
                              2: FlexColumnWidth(0.35),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed,
                                ),
                                children: [
                                  ErpTableHeaderCell('태그 일시'),
                                  ErpTableHeaderCell('거리'),
                                  ErpTableHeaderCell('선택'),
                                ],
                              ),
                              for (var i = 0; i < rows.length; i++)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: i.isEven
                                        ? AppTheme.tableRowOdd
                                        : AppTheme.tableRowEven,
                                  ),
                                  children: [
                                    ErpTableBodyCell(rows[i].usedAtLabel),
                                    ErpTableBodyCell(
                                      rows[i].distanceM != null
                                          ? '${rows[i].distanceM}m'
                                          : '-',
                                      center: true,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Center(
                                        child: FilledButton(
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(rows[i].logIdx),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppTheme.accentRed,
                                            minimumSize: const Size(64, 36),
                                          ),
                                          child: const Text('선택'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(0),
                      style: FilledButton.styleFrom(
                        backgroundColor: FormStylePalette.neutralGray,
                      ),
                      child: const Text('태그 없이 상신'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
