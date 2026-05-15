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
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';

/// [ActivityNoteTabView] 목록 API 분기.
enum ActivityInstructionsQueryKind {
  /// 활동관리 — `sv_id` = 로그인, `memo_txt`·비`PENDING`.
  writerMemoSv,

  /// 활동관리결재 — `notif_mst` + `appr_id` 결재선·본인.
  approverMemoNotif,
}

/// 활동관리·활동관리결재 탭 — 지시사항(결재특이사항) 목록.
class ActivityNoteTabView extends StatefulWidget {
  const ActivityNoteTabView({
    super.key,
    this.queryKind = ActivityInstructionsQueryKind.writerMemoSv,
    this.rowKeywordFilter = '',
    required this.brandLabel,
    this.brandCdFilter,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final ActivityInstructionsQueryKind queryKind;

  final String rowKeywordFilter;
  final String brandLabel;

  /// 공통코드에서 선택한 브랜드 [CodeOption.codeCd]. 있으면 행 [ActivityRow.brandCd] 와만 비교한다.
  final String? brandCdFilter;

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
          : switch (widget.queryKind) {
              ActivityInstructionsQueryKind.writerMemoSv =>
                Act002Api().fetchRowsForSvWithApprNote(uid),
              ActivityInstructionsQueryKind.approverMemoNotif =>
                Act002Api().fetchRowsForApproverMemoInstructions(uid),
            };
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
    final cdFilter = widget.brandCdFilter?.trim() ?? '';
    if (cdFilter.isNotEmpty) {
      return row.brandCd.trim() == cdFilter;
    }
    final label = widget.brandLabel.trim();
    if (label.isEmpty || label == '전체') return true;
    final nm = row.brandNm.trim();
    final cd = row.brandCd.trim();
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
          rows = rows
              .where((e) => erpActivityRowMatchesKeyword(e, kw))
              .toList();
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
                  ErpTableHeaderCell('지시사항(결재특이사항)'),
                  ErpTableHeaderCell('담당 수퍼바이저'),
                  ErpTableHeaderCell('체크리스트'),
                  ErpTableHeaderCell('상세보기'),
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: _ChecklistStatusChip(_cell(rows[i].chkYn)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: DetailButton(
                          onPressed: () {
                            final actIdx = rows[i].actIdx;
                            if (actIdx != null) {
                              context.go(
                                widget.queryKind ==
                                        ActivityInstructionsQueryKind
                                            .approverMemoNotif
                                    ? ActivityRoutes.approvalActivityDetail(
                                        actIdx,
                                      )
                                    : ActivityRoutes.manageDetail(actIdx),
                              );
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

class _ChecklistStatusChip extends StatelessWidget {
  const _ChecklistStatusChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final done = value?.toString().trim().toUpperCase() == 'Y';
    return _StatusChip(
      label: done ? '완료' : '미완료',
      foreground: done
          ? const Color.fromARGB(255, 5, 102, 119)
          : const Color.fromARGB(255, 97, 104, 119),
      background: done
          ? const Color.fromARGB(255, 171, 211, 238)
          : const Color(0xFFF3F4F6),
      border: done ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
    );
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
