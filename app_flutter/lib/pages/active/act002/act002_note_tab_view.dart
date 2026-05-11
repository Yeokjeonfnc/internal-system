import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/search/erp_activity_row_keyword.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/active/activity_api.dart';
import 'package:app_flutter/pages/active/activity_model.dart';
import 'package:app_flutter/pages/active/activity_routes.dart';

/// 활동관리 탭 — 지시사항(결재특이사항) 목록.
class ActivityNoteTabView extends StatefulWidget {
  const ActivityNoteTabView({
    super.key,
    this.rowKeywordFilter = '',
    required this.brandLabel,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final String rowKeywordFilter;
  final String brandLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  State<ActivityNoteTabView> createState() => _ActivityNoteTabViewState();
}

class _ActivityNoteTabViewState extends State<ActivityNoteTabView> {
  late Future<List<ActivityRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <ActivityRow>[]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    final uid = context.read<AuthProvider>().userId.trim();
    setState(() {
      _future = uid.isEmpty
          ? Future.value(const <ActivityRow>[])
          : ActivityApiService().fetchRowsForSvWithApprNote(uid);
    });
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

  static String _chkYn(String value) {
    final str = value.trim();
    if (str.isEmpty) return '—';
    if (str == 'Y') return 'V';
    if (str == 'N') return 'X';
    return str;
  }

  bool _inRange(ActivityRow row) {
    final raw = row.actDt.trim();
    if (raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw.split('T').first);
    if (parsed == null) return false;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final a = DateTime(
      widget.rangeStart.year,
      widget.rangeStart.month,
      widget.rangeStart.day,
    );
    final b = DateTime(
      widget.rangeEnd.year,
      widget.rangeEnd.month,
      widget.rangeEnd.day,
    );
    return !day.isBefore(a) && !day.isAfter(b);
  }

  bool _brandOk(ActivityRow row) {
    final label = widget.brandLabel.trim();
    if (label.isEmpty || label == '전체') return true;
    final nm = row.brandNm;
    final cd = row.brandCd;
    return nm == label || cd == label;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActivityRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final uid = context.read<AuthProvider>().userId.trim();
        if (uid.isEmpty) {
          return const Center(child: Text('로그인 후 지시사항(결재특이사항)을 조회할 수 있습니다.'));
        }

        final raw = snapshot.data ?? const <ActivityRow>[];
        var rows = raw.where(_inRange).where(_brandOk).toList();

        final kw = widget.rowKeywordFilter.trim();
        if (kw.isNotEmpty) {
          rows = rows.where((e) => erpActivityRowMatchesKeyword(e, kw)).toList();
        }

        if (rows.isEmpty) {
          return Center(
            child: Text(
              raw.isEmpty ? '조회된 지시사항이 없습니다.' : '검색·필터 조건에 맞는 지시사항이 없습니다.',
            ),
          );
        }

        return ErpDataTable(
          minWidth: AppDimensions.tableMinWidthDefault + 280,
          tableBuilder: (context, w) => Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: kErpTableInnerGridBorder,
            columnWidths: const {
              0: FlexColumnWidth(0.35),
              1: FlexColumnWidth(0.4),
              2: FlexColumnWidth(0.35),
              3: FlexColumnWidth(0.45),
              4: FlexColumnWidth(0.55),
              5: FlexColumnWidth(0.75),
              6: FlexColumnWidth(0.4),
              7: FlexColumnWidth(0.3),
              8: FlexColumnWidth(0.35),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.accentRed),
                children: [
                  ErpTableHeaderCell('활동구분'),
                  ErpTableHeaderCell('활동일자'),
                  ErpTableHeaderCell('브랜드'),
                  ErpTableHeaderCell('가맹점명'),
                  ErpTableHeaderCell('주요상담내용'),
                  ErpTableHeaderCell('결재특이사항'),
                  ErpTableHeaderCell('담당 수퍼바이저'),
                  ErpTableHeaderCell('체크리스트'),
                  ErpTableHeaderCell('상세'),
                ],
              ),
              for (var i = 0; i < rows.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i.isEven ? AppTheme.tableRowOdd : AppTheme.tableRowEven,
                  ),
                  children: [
                    ErpTableBodyCell(_cell(rows[i].actType), center: true),
                    ErpTableBodyCell(_ymd(rows[i].actDt), center: true),
                    ErpTableBodyCell(
                      _cell(
                        rows[i].brandNm.isNotEmpty
                            ? rows[i].brandNm
                            : rows[i].brandCd,
                      ),
                      center: true,
                    ),
                    ErpTableBodyCell(_cell(rows[i].storeNm), center: true),
                    ErpTableBodyCell(_cell(rows[i].actNotes)),
                    ErpTableBodyCell(_cell(rows[i].apprNotes)),
                    ErpTableBodyCell(_cell(rows[i].svNm), center: true),
                    ErpTableBodyCell(_chkYn(rows[i].chkYn), center: true),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: DetailButton(
                          onPressed: () {
                            final actIdx = rows[i].actIdx;
                            if (actIdx != null) {
                              context.go(ActivityRoutes.manageDetail(actIdx));
                            }
                          },
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
}
