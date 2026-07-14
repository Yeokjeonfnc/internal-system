import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/core/search/erp_activity_row_keyword.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';

String _activityNoteCell(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}

String _activityNoteYmd(String value) {
  final t = _activityNoteCell(value);
  if (t == '-') return t;
  return t.split('T').first;
}

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
    this.onFilteredRowCount,
  });

  final ActivityInstructionsQueryKind queryKind;

  final String rowKeywordFilter;
  final String brandLabel;

  /// 공통코드에서 선택한 브랜드 [CodeOption.codeCd]. 있으면 행 [ActivityRow.brandCd] 와만 비교한다.
  final String? brandCdFilter;

  final DateTime rangeStart;
  final DateTime rangeEnd;

  /// 필터 적용 후 행 수. null = 조회 중.
  final ValueChanged<int?>? onFilteredRowCount;

  @override
  State<ActivityNoteTabView> createState() => _ActivityNoteTabViewState();
}

class _ActivityNoteTabViewState extends State<ActivityNoteTabView> {
  List<ActivityRow>? _rows;
  bool _refreshing = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  void _load() {
    final uid = context.read<AuthProvider>().userId.trim();
    if (uid.isEmpty) {
      setState(() => _rows = const <ActivityRow>[]);
      return;
    }
    final key = 'act002note:${widget.queryKind.name}:$uid';
    final epoch = ++_loadEpoch;
    setState(() {
      _rows = SessionListCache.get<ActivityRow>(key);
      _refreshing = true;
    });
    final future = switch (widget.queryKind) {
      ActivityInstructionsQueryKind.writerMemoSv =>
        Act002Api().fetchRowsForSvWithApprNote(uid),
      ActivityInstructionsQueryKind.approverMemoNotif =>
        Act002Api().fetchRowsForApproverMemoInstructions(uid),
    };
    future.then((fresh) {
      SessionListCache.put<ActivityRow>(key, fresh);
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _rows = fresh;
        _refreshing = false;
      });
    }).catchError((Object _) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _rows ??= const <ActivityRow>[];
        _refreshing = false;
      });
    });
  }


  bool _inRange(ActivityRow row) =>
      erpActivityRowInDateRange(row, widget.rangeStart, widget.rangeEnd);

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
    return Builder(
      builder: (context) {
        final cached = _rows;
        if (cached == null) {
          erpNotifyFilteredRowCount(widget.onFilteredRowCount, null);
          return const Center(child: CircularProgressIndicator());
        }
        final uid = context.read<AuthProvider>().userId.trim();
        if (uid.isEmpty) {
          erpNotifyFilteredRowCount(widget.onFilteredRowCount, 0);
          return const Center(child: Text('로그인 후 지시사항(결재특이사항)을 조회할 수 있습니다.'));
        }

        final raw = cached;
        var rows = raw.where(_inRange).where(_brandOk).toList();

        final kw = widget.rowKeywordFilter.trim();
        if (kw.isNotEmpty) {
          rows = rows
              .where((e) => erpActivityRowMatchesKeyword(e, kw))
              .toList();
        }

        erpNotifyFilteredRowCount(widget.onFilteredRowCount, rows.length);
        if (rows.isEmpty) {
          return Center(
            child: Text(
              raw.isEmpty ? '조회된 지시사항이 없습니다.' : '검색·필터 조건에 맞는 지시사항이 없습니다.',
            ),
          );
        }

        final table = ErpDataTable(
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
            },
            children: [
              const TableRow(
                decoration: kErpTableHeaderRowDecoration,
                children: [
                  ErpTableHeaderCell('활동구분'),
                  ErpTableHeaderCell('활동일자'),
                  ErpTableHeaderCell('브랜드'),
                  ErpTableHeaderCell('가맹점명'),
                  ErpTableHeaderCell('주요상담내용'),
                  ErpTableHeaderCell('지시사항(결재특이사항)'),
                  ErpTableHeaderCell('담당 수퍼바이저'),
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
                  children: _instructionRowCells(
                    context,
                    rows[i],
                    queryKind: widget.queryKind,
                  ),
                ),
            ],
          ),
        );
        if (!_refreshing) return table;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(minHeight: 2),
            Expanded(child: table),
          ],
        );
      },
    );
  }
}

List<Widget> _instructionRowCells(
  BuildContext context,
  ActivityRow row, {
  required ActivityInstructionsQueryKind queryKind,
}) {
  void openDetail() {
    final actIdx = row.actIdx;
    if (actIdx == null) return;
    context.go(
      queryKind == ActivityInstructionsQueryKind.approverMemoNotif
          ? ActivityRoutes.approvalActivityDetail(actIdx)
          : ActivityRoutes.manageDetail(actIdx),
    );
  }

  Widget tap(Widget child) => ErpTableDoubleTapCell(
    onDoubleTap: openDetail,
    child: child,
  );

  return [
    tap(ErpTableBodyCell(_activityNoteCell(row.actType), center: true)),
    tap(ErpTableBodyCell(_activityNoteYmd(row.actDt), center: true)),
    tap(
      ErpTableBodyCell(
        _activityNoteCell(
          row.brandNm.isNotEmpty ? row.brandNm : row.brandCd,
        ),
        center: true,
      ),
    ),
    tap(ErpTableBodyCell(_activityNoteCell(row.storeNm), center: true)),
    tap(ErpTableBodyCell(_activityNoteCell(row.actNotes))),
    tap(ErpTableBodyCell(_activityNoteCell(row.apprNotes))),
    tap(ErpTableBodyCell(_activityNoteCell(row.svNm), center: true)),
    tap(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Center(
          child: _ChecklistStatusChip(_activityNoteCell(row.chkYn)),
        ),
      ),
    ),
  ];
}

class _ChecklistStatusChip extends StatelessWidget {
  const _ChecklistStatusChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final done = value?.toString().trim().toUpperCase() == 'Y';
    return StatusBadge(
      done ? '완료' : '미점검',
      color: done ? AppTheme.statusNew : AppTheme.textMuted,
    );
  }
}
