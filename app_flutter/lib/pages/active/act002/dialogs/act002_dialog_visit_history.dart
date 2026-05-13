// 가맹점 기본정보 — 방문이력 모달(활동 마스터: active_mst 조회).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/active_mst/active_mst_api_json_keys.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';

class VisitHistoryDialog extends StatefulWidget {
  const VisitHistoryDialog({
    super.key,
    required this.storeIdx,
    required this.brandNm,
    required this.storeNm,
  });

  final int storeIdx;
  final String brandNm;
  final String storeNm;

  @override
  State<VisitHistoryDialog> createState() => _VisitHistoryDialogState();
}

class _VisitHistoryDialogState extends State<VisitHistoryDialog> {
  late final Future<List<ActivityRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ActivityRow>> _load() async {
    try {
      final api = Act002Api();
      var rows = await api.fetchRowsForStoreHistory(
        storeIdx: widget.storeIdx,
        apprStatusCsv: ActiveMstListApprStatus.approvedPendingCsv,
      );
      // 백엔드가 storeIdx 쿼리를 무시/미지원하는 경우를 대비해 한 번 더 필터한다.
      rows = rows.where((e) => e.storeIdx == widget.storeIdx).toList();
      rows.sort((a, b) => _dateText(b.actDt).compareTo(_dateText(a.actDt)));
      return rows;
    } catch (_) {
      return const <ActivityRow>[];
    }
  }

  void _openDetail(int actIdx) {
    Navigator.of(context).pop();
    context.go(ActivityRoutes.manageDetail(actIdx));
  }

  Widget _dblTapCell(Widget child, int? actIdx) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        if (actIdx != null) {
          _openDetail(actIdx);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ConstrainedBox(
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
              ErpDialogHeader(
                title: '활동 이력',
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: FutureBuilder<List<ActivityRow>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CommonLoadingIndicator();
                    }
                    final rows = snapshot.data ?? const <ActivityRow>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _readonlyField('브랜드', widget.brandNm),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _readonlyField('가맹점명', widget.storeNm),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: rows.isEmpty
                                ? const Center(child: Text('조회된 방문이력이 없습니다.'))
                                : ErpDataTable(
                                    minWidth: 880,
                                    tableBuilder: (context, width) {
                                      return Table(
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        border: kErpTableInnerGridBorder,
                                        columnWidths: const {
                                          0: FlexColumnWidth(0.35),
                                          1: FlexColumnWidth(0.45),
                                          2: FlexColumnWidth(1.4),
                                          3: FlexColumnWidth(0.4),
                                          4: FlexColumnWidth(0.35),
                                          5: FlexColumnWidth(0.4),
                                        },
                                        children: [
                                          const TableRow(
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentRed,
                                            ),
                                            children: [
                                              ErpTableHeaderCell('활동구분'),
                                              ErpTableHeaderCell('활동일자'),
                                              ErpTableHeaderCell('주요상담내용'),
                                              ErpTableHeaderCell('기안자'),
                                              ErpTableHeaderCell('체크리스트'),
                                              ErpTableHeaderCell('결재상태'),
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
                                                _dblTapCell(
                                                  ErpTableBodyCell(
                                                    _text(rows[i].actType),
                                                    center: true,
                                                  ),
                                                  rows[i].actIdx,
                                                ),
                                                _dblTapCell(
                                                  ErpTableBodyCell(
                                                    _dateText(rows[i].actDt),
                                                    center: true,
                                                  ),
                                                  rows[i].actIdx,
                                                ),
                                                _dblTapCell(
                                                  ErpTableBodyCell(
                                                    _text(rows[i].actNotes),
                                                  ),
                                                  rows[i].actIdx,
                                                ),
                                                _dblTapCell(
                                                  ErpTableBodyCell(
                                                    _text(rows[i].svNm),
                                                    center: true,
                                                  ),
                                                  rows[i].actIdx,
                                                ),
                                                _dblTapCell(
                                                  ErpTableBodyCell(
                                                    _checklistLabel(
                                                      rows[i].chkYn,
                                                    ),
                                                    center: true,
                                                  ),
                                                  rows[i].actIdx,
                                                ),
                                                _dblTapCell(
                                                  Padding(
                                                    padding: const EdgeInsets.all(
                                                      6,
                                                    ),
                                                    child: Center(
                                                      child: _ApprovalChip(
                                                        rows[i].apprStatus,
                                                      ),
                                                    ),
                                                  ),
                                                  rows[i].actIdx,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '-' : text;
}

String _dateText(dynamic value) {
  final text = _text(value);
  if (text == '-') return text;
  return text.split('T').first;
}

String _checklistLabel(dynamic value) =>
    value?.toString().trim().toUpperCase() == 'Y' ? '작성' : '미작성';

Widget _readonlyField(String label, String value) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: FormStylePalette.inputBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: FormStylePalette.panelBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value.trim(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: FormStylePalette.textPrimary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ApprovalChip extends StatelessWidget {
  const _ApprovalChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    final (label, fg, bg, border) = switch (raw) {
      'PENDING' => (
        '결재대기',
        const Color(0xFFC2410C),
        const Color(0xFFFFEDD5),
        const Color(0xFFF97316),
      ),
      'APPROVED' => (
        '결재승인',
        const Color(0xFF047857),
        const Color(0xFFD1FAE5),
        const Color(0xFFA7F3D0),
      ),
      _ => (
        '-',
        const Color(0xFF6B7280),
        const Color(0xFFF3F4F6),
        const Color(0xFFE5E7EB),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
