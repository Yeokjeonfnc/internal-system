// 가맹점 기본정보 — 방문이력 모달(목록·필터·페이지, 프로젝트 ERP·폼 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';

/// [방문이력 보기] — 가맹점 등록·상세 등에서 공통 사용.
Future<void> showActivityVisitHistoryDialog(
  BuildContext context, {
  String brand = '역전할머니맥주',
  String storeName = '서울송리단길석촌역점',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _VisitHistoryDialog(
          initialBrand: brand,
          initialStoreName: storeName,
        ),
      );
    },
  );
}

class _VisitHistoryRow {
  const _VisitHistoryRow(
    this.activity,
    this.date,
    this.memo,
    this.drafter,
    this.checklist,
    this.approval,
  );

  final String activity;
  final String date;
  final String memo;
  final String drafter;
  final String checklist;
  final String approval;
}

const _visitHistoryRows = <_VisitHistoryRow>[];

class _VisitHistoryDialog extends StatefulWidget {
  const _VisitHistoryDialog({
    required this.initialBrand,
    required this.initialStoreName,
  });

  final String initialBrand;
  final String initialStoreName;

  @override
  State<_VisitHistoryDialog> createState() => _VisitHistoryDialogState();
}

class _VisitHistoryDialogState extends State<_VisitHistoryDialog> {
  late final TextEditingController _brand;
  late final TextEditingController _store;

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController(text: widget.initialBrand);
    _store = TextEditingController(text: widget.initialStoreName);
  }

  @override
  void dispose() {
    _brand.dispose();
    _store.dispose();
    super.dispose();
  }

  InputDecoration _deco(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: FormStylePalette.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1000,
        maxHeight: h.clamp(400.0, 720.0),
      ),
      child: Material(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
              child: Row(
                children: [
                  const Text(
                    '방문이력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: FormStylePalette.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: FormStylePalette.textSecondary,
                    ),
                    icon: const Icon(Icons.close, size: 24),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: FormStylePalette.panelBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    child: Text(
                      '브랜드',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _brand,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                      decoration: _deco('브랜드'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 64,
                    child: Text(
                      '가맹점명',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _store,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                      decoration: _deco('가맹점명'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ErpDataTable(
                  minWidth: 880,
                  tableBuilder: (context, width) {
                    return Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: kErpTableInnerGridBorder,
                      columnWidths: {
                        0: const FlexColumnWidth(0.35),
                        1: const FlexColumnWidth(0.45),
                        2: const FlexColumnWidth(1.4),
                        3: const FlexColumnWidth(0.4),
                        4: const FlexColumnWidth(0.35),
                        5: const FlexColumnWidth(0.4),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: AppTheme.accentRed),
                          children: [
                            ErpTableHeaderCell('활동구분'),
                            ErpTableHeaderCell('활동일자'),
                            ErpTableHeaderCell('주요상담내용'),
                            ErpTableHeaderCell('기안자'),
                            ErpTableHeaderCell('체크리스트'),
                            ErpTableHeaderCell('결재상태'),
                          ],
                        ),
                        for (var i = 0; i < _visitHistoryRows.length; i++)
                          TableRow(
                            decoration: BoxDecoration(
                              color: i.isEven
                                  ? AppTheme.tableRowOdd
                                  : AppTheme.tableRowEven,
                            ),
                            children: [
                              ErpTableBodyCell(
                                _visitHistoryRows[i].activity,
                                center: true,
                              ),
                              ErpTableBodyCell(
                                _visitHistoryRows[i].date,
                                center: true,
                              ),
                              ErpTableBodyCell(_visitHistoryRows[i].memo),
                              ErpTableBodyCell(
                                _visitHistoryRows[i].drafter,
                                center: true,
                              ),
                              ErpTableBodyCell(
                                _visitHistoryRows[i].checklist,
                                center: true,
                              ),
                              ErpTableBodyCell(
                                _visitHistoryRows[i].approval,
                                center: true,
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
