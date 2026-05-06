// 활동 체크리스트 상세보기 다이얼로그

import 'package:flutter/material.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/features/activities/activity_api_service.dart';

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
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklistResults();
  }

  Future<void> _loadChecklistResults() async {
    setState(() => _loading = true);
    final results = await ActivityApiService().getChecklistResults(
      widget.actIdx,
    );
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
        width: 900,
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
                  ? const Center(child: CircularProgressIndicator())
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
                            1: FlexColumnWidth(1.2),
                            2: FlexColumnWidth(0.5),
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
                                    _text(_items[i]['chkTypeNm']),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(_text(_items[i]['chkContent'])),
                                  ErpTableBodyCell(
                                    _text(_items[i]['baseScore']),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _formatResult(_items[i]['answerScore']),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _formatResult(_items[i]['answerVal']),
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
              child: TextButton(
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _text(dynamic value) {
    if (value == null) return '—';
    return value.toString();
  }

  String _formatResult(dynamic value) {
    if (value == null || value == '') return '미평가';
    final val = value.toString();
    if (val == 'Y' || val == '1') return '적합';
    if (val == 'N' || val == '0') return '미적합';
    return val;
  }
}
