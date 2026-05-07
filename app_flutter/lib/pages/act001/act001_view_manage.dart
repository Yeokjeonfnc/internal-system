// 활동관리 — 가맹점 목록과 동일 [ListPageTemplate] + 공통 검색 칩·본문 검색.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'act001_api_service.dart';
import 'act001_dialog_checklist.dart';
import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/core/search/erp_activity_row_keyword.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';
import 'act001_widget_drafts.dart';
import 'package:app_flutter/core/widgets/common/erp_list_date_range_field.dart';
import 'act001_view_register.dart';

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
    _tabController.addListener(_onManageTabChanged);
    final r = _defaultActivityDateRange();
    _activityRangeStart = r.$1;
    _activityRangeEnd = r.$2;
    _readTabReloadEpoch = List<int>.filled(4, 0);
  }

  void _onManageTabChanged() {
    if (_tabController.indexIsChanging) return;
    final i = _tabController.index;
    if (i == 1) return;
    setState(() => _readTabReloadEpoch[i]++);
  }

  /// [ListPageTemplate] 새로고침 — 현재 탭 테이블 위젯을 재생성해 API를 다시 호출한다.
  void _reloadCurrentManagementListTab() {
    if (!mounted) return;
    final i = _tabController.index;
    if (i == 1) return;
    setState(() => _readTabReloadEpoch[i]++);
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
    _tabController.removeListener(_onManageTabChanged);
    _tabController.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _clearActivityFilterField(CommonSearchFieldId id) {
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

  void _clearActivityFilterChip(CommonSearchFieldId id) {
    setState(() => _clearActivityFilterField(id));
  }

  String _formatYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  List<SearchFilterItemData> _mainFilterItems() {
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
  List<ActiveFilterChip> _activeFilterChips() {
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
              onClear: () => _clearActivityFilterChip(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_formatYmd(_activityRangeStart)} ~ ${_formatYmd(_activityRangeEnd)}',
              onClear: () => _clearActivityFilterChip(def.id),
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
  Widget _topActivityTabBar() {
    return Container(
      color: FormStylePalette.accent,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        labelStyle: const TextStyle(
          fontSize: 17,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
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
  Widget _managementListPage(Widget mainFields, Widget table) {
    return ListPageTemplate(
      activeFilters: _activeFilterChips(),
      mainSearchFields: mainFields,
      countText: '총 0건이 조회되었습니다.',
      onRefresh: _reloadCurrentManagementListTab,
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
          hint: '가맹점명, 가맹점코드, 수퍼바이저, 상담내용 검색',
          borderRadius: 8,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 22,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(items: _mainFilterItems()),
      ],
    );

    /// 가맹점 목록 등 다른 관리 화면과 동일한 [MediaQuery.textScaler]를 쓴다.
    /// (이전에 본문만 1.1배 했을 때 [ErpTableHeaderCell]/[ErpTableBodyCell]이
    /// 가맹점 테이블보다 크게 보였음.)
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topActivityTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _managementListPage(
                  mainFields,
                  ActivityDraftsTable(
                    key: ValueKey<int>(_readTabReloadEpoch[0]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                  ),
                ),
                const ActivityRegisterView(),
                _managementListPage(
                  mainFields,
                  _ActivityInstructionsTable(
                    key: ValueKey<int>(_readTabReloadEpoch[2]),
                  ),
                ),
                _managementListPage(
                  mainFields,
                  ActivityChecklistTable(
                    key: ValueKey<int>(_readTabReloadEpoch[3]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
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

class _ActivityInstructionsTable extends StatelessWidget {
  const _ActivityInstructionsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthDefault + 200,
      tableBuilder: (context, w) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: kErpTableInnerGridBorder,
          columnWidths: const {
            0: FlexColumnWidth(0.45),
            1: FlexColumnWidth(0.5),
            2: FlexColumnWidth(0.4),
            3: FlexColumnWidth(0.5),
            4: FlexColumnWidth(0.9),
            5: FlexColumnWidth(0.5),
            6: FlexColumnWidth(0.4),
            7: FlexColumnWidth(0.5),
          },
          children: const [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.accentRed),
              children: [
                ErpTableHeaderCell('활동구분'),
                ErpTableHeaderCell('활동일자'),
                ErpTableHeaderCell('브랜드'),
                ErpTableHeaderCell('가맹점명'),
                ErpTableHeaderCell('주요상담내용'),
                ErpTableHeaderCell('담당 수퍼바이저'),
                ErpTableHeaderCell('확인여부'),
                ErpTableHeaderCell('체크리스트'),
              ],
            ),
            TableRow(
              decoration: BoxDecoration(color: AppTheme.tableRowOdd),
              children: [
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell(''),
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell('', center: true),
                ErpTableBodyCell('', center: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 체크리스트 탭 테이블 (활동관리 & 활동관리결재 공유)
class ActivityChecklistTable extends StatefulWidget {
  const ActivityChecklistTable({super.key, this.rowKeywordFilter = ''});

  /// 가맹점명·코드·수퍼바이저·상담내용 등 통합 키워드 (부모에서 전달).
  final String rowKeywordFilter;

  @override
  State<ActivityChecklistTable> createState() => ActivityChecklistTableState();
}

class ActivityChecklistTableState extends State<ActivityChecklistTable> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _activitiesFuture = ActivityApiService().getChecklistActivities();
  }

  String _text(dynamic value) {
    if (value == null) return '—';
    return value.toString();
  }

  String _dateText(dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    if (str.length >= 10) return str.substring(0, 10);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final raw = snapshot.data ?? const <Map<String, dynamic>>[];
        final kw = widget.rowKeywordFilter.trim();
        final rows = kw.isEmpty
            ? raw
            : raw.where((e) => erpActivityRowMatchesKeyword(e, kw)).toList();

        if (rows.isEmpty) {
          return Center(
            child: Text(raw.isEmpty ? '조회된 활동이 없습니다.' : '검색 조건에 맞는 활동이 없습니다.'),
          );
        }

        return ErpDataTable(
          minWidth: AppDimensions.tableMinWidthDefault + 240,
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
                6: FlexColumnWidth(0.4),
                7: FlexColumnWidth(0.3),
                8: FlexColumnWidth(0.4),
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
                    ErpTableHeaderCell('담당 수퍼바이저'),
                    ErpTableHeaderCell('등록일'),
                    ErpTableHeaderCell('체크리스트'),
                    ErpTableHeaderCell('상세'),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppTheme.tableRowOdd,
                    ),
                    children: [
                      ErpTableBodyCell(_text(row['actType']), center: true),
                      ErpTableBodyCell(_dateText(row['actDt']), center: true),
                      ErpTableBodyCell(
                        _text(
                          row.jsonString('brandNm').isNotEmpty
                              ? row.jsonString('brandNm')
                              : row.jsonString('brandCd'),
                        ),
                        center: true,
                      ),
                      ErpTableBodyCell(_text(row['storeNm']), center: true),
                      ErpTableBodyCell(_text(row['actNotes'])),
                      ErpTableBodyCell(_text(row['svNm']), center: true),
                      ErpTableBodyCell(_dateText(row['creatDt']), center: true),
                      ErpTableBodyCell(_text(row['chkYn']), center: true),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: DetailButton(
                            onPressed: () {
                              final actIdx = asJsonIntOpt(row['actIdx']);
                              if (actIdx != null) {
                                showActivityChecklistDetailDialog(
                                  context,
                                  actIdx,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
