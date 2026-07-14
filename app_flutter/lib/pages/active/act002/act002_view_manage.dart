// 활동관리 — 가맹점 목록과 동일 [ListPageTemplate] + 공통 검색 칩·본문 검색.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/core/search/erp_activity_row_keyword.dart';
import 'package:app_flutter/core/widgets/common/erp_list_date_range_field.dart';
import 'package:app_flutter/pages/active/act002/act002_api.dart';
import 'package:app_flutter/pages/active/act002/act002_model.dart';
import 'package:app_flutter/pages/active/act002/act002_view_register.dart';
import 'package:app_flutter/pages/active/act002/act002_widget_drafts.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_checklist.dart';
import 'package:app_flutter/pages/active/act002/act002_note_tab_view.dart';

/// 활동관리 화면 본문에 항상 노출하는 검색 항목.
const Set<CommonSearchFieldId> kActivityManagementSupportedSearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.activityDateRange,
};

/// `/activities/drafts` 등에서 열릴 때 [initialTab] 으로 탭 선택.
class ActivityManagementView extends StatefulWidget {
  const ActivityManagementView({super.key, required this.initialTab});

  final int initialTab;

  @override
  State<ActivityManagementView> createState() => _ActivityManagementViewState();
}

class _ActivityManagementViewState extends State<ActivityManagementView>
    with SingleTickerProviderStateMixin {
  static const _brands = ['전체', '역전할머니맥주', '지미존스'];

  late final TabController _tabController;
  final _keywordCtrl = TextEditingController();
  String _brand = '전체';

  /// 활동일자 구간(칩·표시용).
  late DateTime _activityRangeStart;
  late DateTime _activityRangeEnd;

  /// 읽기 전용 탭(0·2·3) 재진입 시 테이블 위젯 재생성으로 API 재조회.
  late final List<int> _readTabReloadEpoch;

  int? _listRowCount;

  (DateTime, DateTime) _defaultActivityDateRange() {
    return erpPresetDateRange('최근1개월');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tabController.addListener(_onTabChanged);
    final r = _defaultActivityDateRange();
    _activityRangeStart = r.$1;
    _activityRangeEnd = r.$2;
    _readTabReloadEpoch = List<int>.filled(4, 0);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final i = _tabController.index;
    if (i == 1) return;
    setState(() {
      _readTabReloadEpoch[i]++;
      _listRowCount = null;
    });
  }

  /// [ListPageTemplate] 새로고침 — 현재 탭 테이블 위젯을 재생성해 API를 다시 호출한다.
  void _reloadList() {
    if (!mounted) return;
    final i = _tabController.index;
    if (i == 1) return;
    setState(() {
      _readTabReloadEpoch[i]++;
      _listRowCount = null;
    });
  }

  void _onListRowCount(int tabIndex, int? count) {
    if (!mounted || _tabController.index != tabIndex) return;
    if (_listRowCount == count) return;
    setState(() => _listRowCount = count);
  }

  @override
  void didUpdateWidget(covariant ActivityManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = widget.initialTab.clamp(0, 3);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _resetFilter(CommonSearchFieldId id) {
    switch (id) {
      case CommonSearchFieldId.storeCd:
      case CommonSearchFieldId.storeNm:
      case CommonSearchFieldId.supervisorCd:
      case CommonSearchFieldId.activityConsultMemo:
        return;
      case CommonSearchFieldId.brandCd:
        _brand = '전체';
        return;
      case CommonSearchFieldId.activityDateRange:
        final d = _defaultActivityDateRange();
        _activityRangeStart = d.$1;
        _activityRangeEnd = d.$2;
        return;
      default:
        return;
    }
  }

  void _clearChip(CommonSearchFieldId id) {
    setState(() => _resetFilter(id));
  }

  String _formatYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  List<SearchFilterItemData> _inlineFilters() {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(
      kActivityManagementSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.storeNm:
        case CommonSearchFieldId.storeCd:
        case CommonSearchFieldId.supervisorCd:
        case CommonSearchFieldId.activityConsultMemo:
          break;
        case CommonSearchFieldId.brandCd:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: _brand,
              options: _brands,
              onSelected: (v) => setState(() => _brand = v),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          items.add(
            SearchFilterItemData(
              label: '활동일자',
              child: ErpListDateRangeField(
                start: _activityRangeStart,
                end: _activityRangeEnd,
                onRangeChanged: (a, b) {
                  setState(() {
                    _activityRangeStart = a;
                    _activityRangeEnd = b;
                  });
                },
              ),
            ),
          );
          break;
        default:
          break;
      }
    }
    return items;
  }

  /// 적용 중인 검색·필터 칩(통합 검색·브랜드·활동일자).
  List<ActiveFilterChip> _chips() {
    final chips = <ActiveFilterChip>[];
    final kw = _keywordCtrl.text.trim();
    if (kw.isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: $kw',
          onClear: () => setState(() => _keywordCtrl.clear()),
        ),
      );
    }
    for (final def in commonSearchDefsOrdered(
      kActivityManagementSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.brandCd:
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: $_brand',
              onClear: () => _clearChip(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_formatYmd(_activityRangeStart)} ~ ${_formatYmd(_activityRangeEnd)}',
              onClear: () => _clearChip(def.id),
            ),
          );
          break;
        default:
          break;
      }
    }
    return chips;
  }

  /// 검색·필터 카드 **위** 빨간 탭 — [DetailMainTabBar]·예비창업자 등록과 동일한 높이·타이포.
  Widget _tabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.accentRed,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '임시보관'),
          Tab(text: '활동관리 등록'),
          Tab(text: '지시사항(결재특이사항)'),
          Tab(text: '체크리스트'),
        ],
      ),
    );
  }

  /// 임시보관 / 지시사항 / 체크리스트 — [ListPageTemplate] + 개별 테이블.
  Widget _listShell(Widget mainFields, Widget table) {
    final countText = _listRowCount == null
        ? '조회 중입니다.'
        : '총 $_listRowCount건이 조회되었습니다.';
    return ListPageTemplate(
      activeFilters: _chips(),
      mainSearchFields: mainFields,
      countText: countText,
      onRefresh: _reloadList,
      table: table,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchFilterTextField(
          controller: _keywordCtrl,
          hint: '키워드 검색',
          borderRadius: 8,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 22,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(items: _inlineFilters()),
      ],
    );

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _listShell(
                  mainFields,
                  ActivityDraftsTable(
                    key: ValueKey<int>(_readTabReloadEpoch[0]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    rangeStart: _activityRangeStart,
                    rangeEnd: _activityRangeEnd,
                    onFilteredRowCount: (c) => _onListRowCount(0, c),
                  ),
                ),
                const ActivityRegisterView(),
                _listShell(
                  mainFields,
                  ActivityNoteTabView(
                    key: ValueKey<int>(_readTabReloadEpoch[2]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandLabel: _brand,
                    rangeStart: _activityRangeStart,
                    rangeEnd: _activityRangeEnd,
                    onFilteredRowCount: (c) => _onListRowCount(2, c),
                  ),
                ),
                _listShell(
                  mainFields,
                  ActivityChecklistTable(
                    key: ValueKey<int>(_readTabReloadEpoch[3]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    rangeStart: _activityRangeStart,
                    rangeEnd: _activityRangeEnd,
                    onFilteredRowCount: (c) => _onListRowCount(3, c),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 체크리스트 탭 테이블 (활동관리 & 활동관리결재 공유)
class ActivityChecklistTable extends StatefulWidget {
  const ActivityChecklistTable({
    super.key,
    this.rowKeywordFilter = '',
    this.rangeStart,
    this.rangeEnd,
    this.onFilteredRowCount,
  });

  /// 가맹점명·코드·수퍼바이저·상담내용 등 통합 키워드 (부모에서 전달).
  final String rowKeywordFilter;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  /// 필터 적용 후 행 수. null = 조회 중.
  final ValueChanged<int?>? onFilteredRowCount;

  @override
  State<ActivityChecklistTable> createState() => ActivityChecklistTableState();
}

class ActivityChecklistTableState extends State<ActivityChecklistTable> {
  late Future<List<ActivityRow>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _activitiesFuture = Act002Api().fetchChkActs();
  }

  String _text(String value) {
    final t = value.trim();
    return t.isEmpty ? '—' : t;
  }

  String _dateText(String value) {
    final str = value.trim();
    if (str.isEmpty) return '—';
    if (str.length >= 10) return str.substring(0, 10);
    if (str.contains('T')) return str.split('T').first;
    return str;
  }

  List<Widget> _rowCells(BuildContext context, ActivityRow row) {
    void openRow() {
      final actIdx = row.actIdx;
      if (actIdx != null) {
        showActivityChecklistDetailDialog(context, actIdx);
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Center(child: _ChecklistStatusChip(row.chkYn)),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActivityRow>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          erpNotifyFilteredRowCount(widget.onFilteredRowCount, null);
          return const Center(child: CircularProgressIndicator());
        }
        final raw = snapshot.data ?? const <ActivityRow>[];
        final start = widget.rangeStart;
        final end = widget.rangeEnd;
        final byDate = start != null && end != null
            ? raw
                  .where((e) => erpActivityRowInDateRange(e, start, end))
                  .toList()
            : raw;
        final kw = widget.rowKeywordFilter.trim();
        final rows = kw.isEmpty
            ? byDate
            : byDate.where((e) => erpActivityRowMatchesKeyword(e, kw)).toList();

        erpNotifyFilteredRowCount(widget.onFilteredRowCount, rows.length);
        if (rows.isEmpty) {
          return Center(
            child: Text(
              raw.isEmpty ? '조회된 활동이 없습니다.' : '검색·필터 조건에 맞는 활동이 없습니다.',
            ),
          );
        }

        return ErpDataTable(
          minWidth: AppDimensions.tableMinWidthDefault + 220,
          tableBuilder: (context, w) {
            return Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: kErpTableInnerGridBorder,
              columnWidths: const {
                0: FlexColumnWidth(0.3),
                1: FlexColumnWidth(0.4),
                2: FlexColumnWidth(0.4),
                3: FlexColumnWidth(0.5),
                4: FlexColumnWidth(0.8),
                5: FlexColumnWidth(0.4),
                6: FlexColumnWidth(0.3),
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
                    children: [..._rowCells(context, rows[i])],
                  ),
              ],
            );
          },
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
    return StatusBadge(
      done ? '완료' : '미점검',
      color: done ? AppTheme.statusNew : AppTheme.textMuted,
    );
  }
}
