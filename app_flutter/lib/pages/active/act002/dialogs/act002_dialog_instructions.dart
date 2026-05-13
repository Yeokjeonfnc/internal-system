// 가맹점 기본정보 — 지시사항 모달(방문이력 다이얼로그와 동일 셸·프로젝트 ERP 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';

/// [지시사항 보기] — 가맹점 등록·상세 등에서 공통 사용.
Future<void> showActivityInstructionsDialog(
  BuildContext context, {
  required String brandNm,
  required String storeNm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _InstructionsDialog(
          initialBrand: brandNm,
          initialStoreName: storeNm,
        ),
      );
    },
  );
}

class _InstructionRow {
  const _InstructionRow(
    this.activity,
    this.date,
    this.memo,
    this.supervisor,
    this.drafter,
    this.confirmed,
    this.checklist,
  );

  final String activity;
  final String date;
  final String memo;
  final String supervisor;
  final String drafter;
  final String confirmed;
  final String checklist;
}

/// API 연동 전: 빈 목록(스크린샷과 동일하게 본문 안내).
const _instructionRows = <_InstructionRow>[];

class _InstructionsDialog extends StatefulWidget {
  const _InstructionsDialog({
    required this.initialBrand,
    required this.initialStoreName,
  });

  final String initialBrand;
  final String initialStoreName;

  @override
  State<_InstructionsDialog> createState() => _InstructionsDialogState();
}

class ReadonlyValue extends StatelessWidget {
  const ReadonlyValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ReadonlyInputShell(
      child: Text(
        text,
        style: const TextStyle(
          color: FormStylePalette.textPrimary,
          fontSize: 15,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _InstructionsDialogState extends State<_InstructionsDialog> {
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

  int get _totalCount => _instructionRows.length;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1100,
        maxHeight: h.clamp(400.0, 720.0),
      ),
      child: Material(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErpDialogHeader(
              title: '지시사항',
              onClose: () => Navigator.of(context).pop(),
            ),
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
                    child: ReadonlyValue(
                      _brand.text.trim().isEmpty ? '-' : _brand.text,
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
                    child: ReadonlyValue(
                      _store.text.trim().isEmpty ? '-' : _store.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _totalCount == 0
                    ? const _InstructionsEmptyTable()
                    : ErpDataTable(
                        minWidth: 1050,
                        tableBuilder: (context, width) {
                          return Table(
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            border: kErpTableInnerGridBorder,
                            columnWidths: {
                              0: const FlexColumnWidth(0.3),
                              1: const FlexColumnWidth(0.4),
                              2: const FlexColumnWidth(1.2),
                              3: const FlexColumnWidth(0.45),
                              4: const FlexColumnWidth(0.4),
                              5: const FlexColumnWidth(0.35),
                              6: const FlexColumnWidth(0.4),
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRed,
                                ),
                                children: const [
                                  ErpTableHeaderCell('활동구분'),
                                  ErpTableHeaderCell('활동일자'),
                                  ErpTableHeaderCell('주요상담내용'),
                                  ErpTableHeaderCell('담당수퍼바이저'),
                                  ErpTableHeaderCell('기안자'),
                                  ErpTableHeaderCell('확인여부'),
                                  ErpTableHeaderCell('체크리스트'),
                                ],
                              ),
                              for (var i = 0; i < _instructionRows.length; i++)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: i.isEven
                                        ? AppTheme.tableRowOdd
                                        : AppTheme.tableRowEven,
                                  ),
                                  children: [
                                    ErpTableBodyCell(
                                      _instructionRows[i].activity,
                                      center: true,
                                    ),
                                    ErpTableBodyCell(
                                      _instructionRows[i].date,
                                      center: true,
                                    ),
                                    ErpTableBodyCell(_instructionRows[i].memo),
                                    ErpTableBodyCell(
                                      _instructionRows[i].supervisor,
                                      center: true,
                                    ),
                                    ErpTableBodyCell(
                                      _instructionRows[i].drafter,
                                      center: true,
                                    ),
                                    ErpTableBodyCell(
                                      _instructionRows[i].confirmed,
                                      center: true,
                                    ),
                                    ErpTableBodyCell(
                                      _instructionRows[i].checklist,
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

/// 헤더만 있는 표 + 본문 안내(데이터 없음) — [ErpDataTable] 톤 맞춤.
class _InstructionsEmptyTable extends StatelessWidget {
  const _InstructionsEmptyTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErpDataTable(
          minWidth: 1050,
          tableBuilder: (context, width) {
            return Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: kErpTableInnerGridBorder,
              columnWidths: {
                0: const FlexColumnWidth(0.3),
                1: const FlexColumnWidth(0.4),
                2: const FlexColumnWidth(1.2),
                3: const FlexColumnWidth(0.45),
                4: const FlexColumnWidth(0.4),
                5: const FlexColumnWidth(0.35),
                6: const FlexColumnWidth(0.4),
              },
              children: const [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.accentRed),
                  children: [
                    ErpTableHeaderCell('활동구분'),
                    ErpTableHeaderCell('활동일자'),
                    ErpTableHeaderCell('주요상담내용'),
                    ErpTableHeaderCell('담당수퍼바이저'),
                    ErpTableHeaderCell('기안자'),
                    ErpTableHeaderCell('확인여부'),
                    ErpTableHeaderCell('체크리스트'),
                  ],
                ),
              ],
            );
          },
        ),
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.tableRowEven,
              border: Border(
                left: BorderSide(color: Color(0xFFE2E5EB)),
                right: BorderSide(color: Color(0xFFE2E5EB)),
                bottom: BorderSide(color: Color(0xFFE2E5EB)),
              ),
            ),
            child: const Center(
              child: Text(
                '조회된 데이터가 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: FormStylePalette.textSecondary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
