// 가맹점 기본정보 — 지시사항 모달(방문이력 다이얼로그와 동일 셸·프로젝트 ERP 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';

/// [지시사항 보기] — 가맹점 등록·상세 등에서 공통 사용.
Future<void> showActivityInstructionsDialog(
  BuildContext context, {
  required int storeIdx,
  required String brandNm,
  required String storeNm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      final compact = useCompactErpLayout(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(compact ? 12 : 24),
        child: _InstructionsDialog(
          storeIdx: storeIdx,
          initialBrand: brandNm,
          initialStoreName: storeNm,
        ),
      );
    },
  );
}

/// `yyyy-MM-dd` 가 잘리지 않도록 활동일자 열 고정.
const double _kInstructionActDateColW = 112;
const double _kInstructionActTypeColW = 72;

Map<int, TableColumnWidth> _instructionTableColumnWidths() {
  return {
    0: const FixedColumnWidth(_kInstructionActTypeColW),
    1: const FixedColumnWidth(_kInstructionActDateColW),
    2: const FlexColumnWidth(2.2),
    3: const FixedColumnWidth(96),
    4: const FixedColumnWidth(72),
    5: const FixedColumnWidth(84),
    6: const FixedColumnWidth(72),
  };
}

double get _instructionTableMinWidth =>
    _kInstructionActTypeColW +
    _kInstructionActDateColW +
    96 +
    72 +
    84 +
    72 +
    240;

class _InstructionsDialog extends StatefulWidget {
  const _InstructionsDialog({
    required this.storeIdx,
    required this.initialBrand,
    required this.initialStoreName,
  });

  final int storeIdx;
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
  late final Future<List<ActivityRow>> _future;

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController(text: widget.initialBrand);
    _store = TextEditingController(text: widget.initialStoreName);
    _future = _load();
  }

  Future<List<ActivityRow>> _load() async {
    return Act002Api().fetchRowsForStoreInstructions(widget.storeIdx);
  }

  @override
  void dispose() {
    _brand.dispose();
    _store.dispose();
    super.dispose();
  }

  static String _cell(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _ymd(String value) {
    final t = _cell(value);
    if (t == '-') return t;
    return t.split('T').first;
  }

  static String _chkLabel(String value) {
    final str = value.trim().toUpperCase();
    if (str.isEmpty) return '—';
    if (str == 'Y') return '작성';
    if (str == 'N') return '미작성';
    return str;
  }

  static String _apprStatusLabel(String value) {
    return switch (value.trim().toUpperCase()) {
      'PENDING' => '결재대기',
      'APPROVED' => '결재완료',
      'DRAFT' => '임시저장',
      '' => '-',
      _ => value.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final h = MediaQuery.sizeOf(context).height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? double.infinity : 1100,
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
              child: Builder(
                builder: (context) {
                  final brandVal =
                      _brand.text.trim().isEmpty ? '-' : _brand.text;
                  final storeVal =
                      _store.text.trim().isEmpty ? '-' : _store.text;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _instructionReadonlyField(context, '브랜드', brandVal),
                        const SizedBox(height: 8),
                        _instructionReadonlyField(
                          context,
                          '가맹점명',
                          storeVal,
                        ),
                      ],
                    );
                  }
                  return Row(
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
                      Expanded(child: ReadonlyValue(brandVal)),
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
                      Expanded(flex: 2, child: ReadonlyValue(storeVal)),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FutureBuilder<List<ActivityRow>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CommonLoadingIndicator();
                    }
                    final rows = snapshot.data ?? const <ActivityRow>[];
                    if (rows.isEmpty) {
                      return const _InstructionsEmptyTable();
                    }
                    return ErpDataTable(
                      minWidth: compact
                          ? _instructionTableMinWidth
                          : 1050,
                      tableBuilder: (context, width) {
                        return Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: kErpTableInnerGridBorder,
                          columnWidths: _instructionTableColumnWidths(),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed,
                              ),
                              children: [
                                ErpTableHeaderCell('활동구분'),
                                ErpTableHeaderCell('활동일자'),
                                ErpTableHeaderCell('지시사항(결재특이사항)'),
                                ErpTableHeaderCell('담당수퍼바이저'),
                                ErpTableHeaderCell('기안자'),
                                ErpTableHeaderCell('결재상태'),
                                ErpTableHeaderCell('체크리스트'),
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
                                  ErpTableBodyCell(
                                    _cell(rows[i].actType),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _ymd(rows[i].actDt),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(_cell(rows[i].apprNotes)),
                                  ErpTableBodyCell(
                                    _cell(rows[i].ssvNm.isNotEmpty
                                        ? rows[i].ssvNm
                                        : rows[i].svNm),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _cell(rows[i].svNm),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _apprStatusLabel(rows[i].apprStatus),
                                    center: true,
                                  ),
                                  ErpTableBodyCell(
                                    _chkLabel(rows[i].chkYn),
                                    center: true,
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
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

Widget _instructionReadonlyField(
  BuildContext context,
  String label,
  String value,
) {
  final compact = useCompactErpLayout(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: FormStylePalette.inputBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: FormStylePalette.panelBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: compact ? 3 : 1,
              overflow: compact ? TextOverflow.visible : TextOverflow.ellipsis,
              softWrap: compact,
              style: const TextStyle(
                fontSize: 14,
                color: FormStylePalette.textPrimary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 헤더만 있는 표 + 본문 안내(데이터 없음) — [ErpDataTable] 톤 맞춤.
class _InstructionsEmptyTable extends StatelessWidget {
  const _InstructionsEmptyTable();

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErpDataTable(
          minWidth: compact ? _instructionTableMinWidth : 1050,
          tableBuilder: (context, width) {
            return Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: kErpTableInnerGridBorder,
              columnWidths: _instructionTableColumnWidths(),
              children: const [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.accentRed),
                  children: [
                    ErpTableHeaderCell('활동구분'),
                    ErpTableHeaderCell('활동일자'),
                    ErpTableHeaderCell('지시사항(결재특이사항)'),
                    ErpTableHeaderCell('담당수퍼바이저'),
                    ErpTableHeaderCell('기안자'),
                    ErpTableHeaderCell('결재상태'),
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
                '조회된 지시사항이 없습니다.',
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
