// 임시보관(동일 열) — [ErpDataTable].

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/search/erp_activity_row_keyword.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';

/// 활동 목록 격자용 조회 모드 (임시보관 vs 활동관리결재 탭).
enum ActivityDraftsTableMode {
  /// 내 임시보관(DRAFT, 로그인 svId)
  myDrafts,

  /// 결재: 전체 (상태 무관)
  approvalAll,

  /// 결재대기 (PENDING)
  approvalPending,

  /// 결재완료 (APPROVED)
  approvalApproved,

  /// 건의사항 있음 + 결재완료
  approvalSuggestions,
}

/// 활동관리·활동관리결재 목록이 공유하는 격자.
class ActivityDraftsTable extends StatefulWidget {
  const ActivityDraftsTable({
    super.key,
    this.mode = ActivityDraftsTableMode.myDrafts,
    this.rowKeywordFilter = '',
    this.brandLabel = '',
    this.brandCdFilter,
    required this.rangeStart,
    required this.rangeEnd,
    this.onFilteredRowCount,
  });

  final ActivityDraftsTableMode mode;

  /// 가맹점명·코드·수퍼바이저·상담내용 등 통합 키워드 (부모에서 전달).
  final String rowKeywordFilter;

  /// 상단 브랜드 필터(표시명). [brandCdFilter] 가 없을 때 행 이름·코드와 비교한다.
  final String brandLabel;

  /// 공통코드 [CodeOption.codeCd]. 있으면 [ActivityRow.brandCd] 와만 비교한다.
  final String? brandCdFilter;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  /// 필터 적용 후 행 수. null = 조회 중.
  final ValueChanged<int?>? onFilteredRowCount;

  @override
  State<ActivityDraftsTable> createState() => _ActivityDraftsTableState();
}

class _ActivityDraftsTableState extends State<ActivityDraftsTable> {
  /// null = 최초 로딩(세션 캐시도 없음). 캐시가 있으면 즉시 그리고 배경 갱신한다.
  List<ActivityRow>? _rows;
  bool _refreshing = false;
  int _loadEpoch = 0;

  String get _cacheKey {
    final uid = context.read<AuthProvider>().userId.trim();
    return 'act002:${widget.mode.name}:$uid';
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<List<ActivityRow>> _fetch(String? relUid) {
    switch (widget.mode) {
      case ActivityDraftsTableMode.myDrafts:
        return Act002Api().fetchDraftRows(svId: relUid);
      case ActivityDraftsTableMode.approvalAll:
        return Act002Api().fetchAllRows();
      case ActivityDraftsTableMode.approvalPending:
        return Act002Api().fetchPendingRowsForRelUser(relUid);
      case ActivityDraftsTableMode.approvalApproved:
        return Act002Api().fetchApprovedRowsForRelUser(relUid);
      case ActivityDraftsTableMode.approvalSuggestions:
        return Act002Api().fetchRowsWithSuggestions();
    }
  }

  void _reload() {
    final userId = context.read<AuthProvider>().userId;
    final relUid = userId.trim().isEmpty ? null : userId.trim();
    final key = _cacheKey;
    final epoch = ++_loadEpoch;

    _rows = SessionListCache.get<ActivityRow>(key);
    _refreshing = true;

    _fetch(relUid).then((fresh) {
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

  String get _emptyMessage {
    switch (widget.mode) {
      case ActivityDraftsTableMode.myDrafts:
        return '임시보관된 활동관리가 없습니다.';
      case ActivityDraftsTableMode.approvalAll:
        return '조회된 활동이 없습니다.';
      case ActivityDraftsTableMode.approvalPending:
        return '결재대기 중인 활동이 없습니다.';
      case ActivityDraftsTableMode.approvalApproved:
        return '결재완료된 활동이 없습니다.';
      case ActivityDraftsTableMode.approvalSuggestions:
        return '건의사항이 등록된 활동이 없습니다.';
    }
  }

  /// 임시보관(act002)·결재 전체(act003) 탭에서만 삭제 열 — 메뉴 삭제 권한 연동.
  bool _showDeleteColumn(BuildContext context) {
    switch (widget.mode) {
      case ActivityDraftsTableMode.myDrafts:
        return context.menuCanDelete(kMenuAct002);
      case ActivityDraftsTableMode.approvalAll:
        return context.menuCanDelete(kMenuAct003);
      default:
        return false;
    }
  }

  void _goDetail(BuildContext context, int actIdx) {
    final path = widget.mode == ActivityDraftsTableMode.myDrafts
        ? ActivityRoutes.draftDetail(actIdx)
        : ActivityRoutes.approvalActivityDetail(actIdx);
    context.go(path);
  }

  Future<void> _confirmDelete(BuildContext context, ActivityRow row) async {
    final actIdx = row.actIdx;
    if (actIdx == null) return;

    final isDraft = widget.mode == ActivityDraftsTableMode.myDrafts;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isDraft ? '임시보관 삭제' : '활동 삭제'),
        content: Text(
          isDraft
              ? '${_text(row.storeNm)} 임시보관 데이터를 삭제하시겠습니까?'
              : '${_text(row.storeNm)} 활동 데이터를 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await Act002Api().deleteOne(actIdx);
    if (!context.mounted) return;
    await showAlertDialog(context, deleted ? '삭제되었습니다.' : '삭제에 실패했습니다.');
    if (deleted) {
      setState(_reload);
    }
  }

  bool _rowMatchesBrand(ActivityRow row) {
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
        final raw = cached;
        final byDate = raw
            .where(
              (e) => erpActivityRowInDateRange(
                e,
                widget.rangeStart,
                widget.rangeEnd,
              ),
            )
            .toList();
        final byBrand = byDate.where(_rowMatchesBrand).toList();
        final kw = widget.rowKeywordFilter.trim();
        final rows = kw.isEmpty
            ? byBrand
            : byBrand
                  .where((e) => erpActivityRowMatchesKeyword(e, kw))
                  .toList();
        erpNotifyFilteredRowCount(widget.onFilteredRowCount, rows.length);
        if (rows.isEmpty) {
          return Center(
            child: Text(raw.isEmpty ? _emptyMessage : '검색·필터 조건에 맞는 활동이 없습니다.'),
          );
        }
        final showDelete = _showDeleteColumn(context);
        final table = ErpDataTable(
          minWidth:
              AppDimensions.tableMinWidthDefault + (showDelete ? 180 : 70),
          tableBuilder: (context, w) {
            final columnWidths = erpTableColumnWidths(
              context,
              !showDelete
                  ? const {
                      0: FlexColumnWidth(0.4),
                      1: FlexColumnWidth(0.5),
                      2: FlexColumnWidth(0.5),
                      3: FlexColumnWidth(0.9),
                      4: FlexColumnWidth(2.5),
                      5: FlexColumnWidth(0.5),
                      6: FixedColumnWidth(84),
                      7: FixedColumnWidth(96),
                    }
                  : const {
                      0: FlexColumnWidth(0.4),
                      1: FlexColumnWidth(0.5),
                      2: FlexColumnWidth(0.7),
                      3: FlexColumnWidth(0.9),
                      4: FlexColumnWidth(2.5),
                      5: FlexColumnWidth(0.5),
                      6: FixedColumnWidth(84),
                      7: FixedColumnWidth(96),
                      8: FixedColumnWidth(72),
                    },
            );
            return Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: kErpTableInnerGridBorder,
              columnWidths: columnWidths,
              children: [
                TableRow(
                  decoration: kErpTableHeaderRowDecoration,
                  children: !showDelete
                      ? [
                          const ErpTableHeaderCell('활동구분'),
                          const ErpTableHeaderCell('활동일자'),
                          const ErpTableHeaderCell('브랜드'),
                          const ErpTableHeaderCell('가맹점명'),
                          const ErpTableHeaderCell('주요상담내용'),
                          const ErpTableHeaderCell('기안자'),
                          const ErpTableHeaderCell('체크리스트'),
                          const ErpTableHeaderCell('결재상태'),
                        ]
                      : [
                          const ErpTableHeaderCell('활동구분'),
                          const ErpTableHeaderCell('활동일자'),
                          const ErpTableHeaderCell('브랜드'),
                          const ErpTableHeaderCell('가맹점명'),
                          const ErpTableHeaderCell('주요상담내용'),
                          const ErpTableHeaderCell('기안자'),
                          const ErpTableHeaderCell('체크리스트'),
                          const ErpTableHeaderCell('결재상태'),
                          const ErpTableHeaderCell('삭제'),
                        ],
                ),
                for (var i = 0; i < rows.length; i++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? AppTheme.tableRowOdd
                          : AppTheme.tableRowEven,
                    ),
                    children: _rowCells(
                      context,
                      rows[i],
                      showDelete: showDelete,
                    ),
                  ),
              ],
            );
          },
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

  List<Widget> _rowCells(
    BuildContext context,
    ActivityRow row, {
    required bool showDelete,
  }) {
    void openRow() {
      final actIdx = row.actIdx;
      if (actIdx != null) _goDetail(context, actIdx);
    }

    Widget tap(Widget child) =>
        ErpTableDoubleTapCell(onDoubleTap: openRow, child: child);

    return [
      tap(ErpTableBodyCell(_text(row.actType), center: true)),
      tap(ErpTableBodyCell(_dateText(row.actDt), center: true)),
      tap(
        ErpTableBodyCell(
          _text(row.brandNm.isNotEmpty ? row.brandNm : row.brandCd),
          center: true,
        ),
      ),
      tap(ErpTableBodyCell(_text(row.storeNm), center: true)),
      tap(ErpTableBodyCell(_text(row.actNotes))),
      tap(ErpTableBodyCell(_text(row.svNm), center: true)),
      tap(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Center(child: _ChecklistStatusChip(row.chkYn)),
        ),
      ),
      tap(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Center(child: _ApprovalStatusChip(row.apprStatus)),
        ),
      ),
      if (showDelete)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Center(
            child: _ActivityDeleteButton(
              onPressed: () => _confirmDelete(context, row),
            ),
          ),
        ),
    ];
  }

  static String _text(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _dateText(String value) {
    final text = _text(value);
    if (text == '-') return text;
    return text.split('T').first;
  }
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

class _ApprovalStatusChip extends StatelessWidget {
  const _ApprovalStatusChip(this.value);

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    final label = switch (raw) {
      'PENDING' => '결재대기',
      'APPROVED' => '결재완료',
      'REJECTED' => '반려',
      _ => '임시저장',
    };
    return StatusBadge(label, color: approvalStatusColor(raw));
  }
}

class _ActivityDeleteButton extends StatelessWidget {
  const _ActivityDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      tooltip: '삭제',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      color: AppTheme.accentRed,
    );
  }
}
