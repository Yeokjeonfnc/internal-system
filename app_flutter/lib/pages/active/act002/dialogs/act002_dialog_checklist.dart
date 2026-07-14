// 활동 체크리스트 상세보기 다이얼로그

import 'package:flutter/material.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';

/// 체크리스트 상세보기 다이얼로그
Future<void> showActivityChecklistDetailDialog(
  BuildContext context,
  int actIdx,
) async {
  await showDialog(
    context: context,
    builder: (context) => _ActivityChecklistDetailDialog(actIdx: actIdx),
  );
}

class _ActivityChecklistDetailDialog extends StatefulWidget {
  const _ActivityChecklistDetailDialog({required this.actIdx});

  final int actIdx;

  @override
  State<_ActivityChecklistDetailDialog> createState() =>
      _ActivityChecklistDetailDialogState();
}

class _ActivityChecklistDetailDialogState
    extends State<_ActivityChecklistDetailDialog> {
  List<ChkResultRow> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklistResults();
  }

  Future<void> _loadChecklistResults() async {
    setState(() => _loading = true);
    final results = await Act002Api().chkResults(widget.actIdx);
    if (!mounted) return;
    setState(() {
      _items = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 1200,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '체크리스트 상세',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const CommonLoadingIndicator()
                  : _items.isEmpty
                  ? const Center(child: Text('체크리스트 결과가 없습니다.'))
                  : ErpDataTable(
                      minWidth: 800,
                      tableBuilder: (context, w) {
                        return Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: kErpTableInnerGridBorder,
                          columnWidths: const {
                            0: FlexColumnWidth(0.4),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(0.3),
                            3: FlexColumnWidth(0.4),
                            4: FlexColumnWidth(0.5),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed,
                              ),
                              children: [
                                ErpTableHeaderCell('구분'),
                                ErpTableHeaderCell('체크항목'),
                                ErpTableHeaderCell('배점'),
                                ErpTableHeaderCell('점수'),
                                ErpTableHeaderCell('체크결과'),
                              ],
                            ),
                            for (var i = 0; i < _items.length; i++)
                              TableRow(
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? AppTheme.tableRowOdd
                                      : AppTheme.tableRowEven,
                                ),
                                children: [
                                  ErpTableBodyCell(
                                    _text(_items[i].chkTypeNm),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(_text(_items[i].chkContent)),
                                  ErpTableBodyCell(
                                    _text(_items[i].baseScore),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _formatScore(_items[i]),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _formatResult(_items[i].answerVal),
                                    center: true,
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '점수 합계  :  $_totalAnswerScore',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _totalAnswerScore => _items.fold<int>(
    0,
    (sum, row) => sum + (_isUnevaluated(row.answerVal) ? 0 : row.answerScore),
  );

  String _text(Object value) {
    final s = value.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  bool _isUnevaluated(String answerVal) => answerVal.trim().isEmpty;

  String _formatScore(ChkResultRow row) {
    if (_isUnevaluated(row.answerVal)) return '미평가';
    return '${row.answerScore}';
  }

  String _formatResult(String answerVal) {
    final val = answerVal.trim();
    if (val.isEmpty) return '미평가';
    if (val == 'Y' || val == '1' || val == '적합') return '적합';
    if (val == 'N' || val == '0' || val == '미적합') return '미적합';
    return val;
  }
}
