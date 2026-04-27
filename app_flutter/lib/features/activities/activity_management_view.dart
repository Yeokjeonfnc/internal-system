// 활동관리 — 가맹점 목록과 동일 [ListPageTemplate] + 공통 검색 칩·필터 시트.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_field_picker.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'activity_date_presets.dart';
import 'activity_drafts_table.dart';
import 'activity_list_date_field.dart';
import 'activity_register_view.dart';

/// 활동관리 화면에서 켤 수 있는 공통 검색 항목.
const Set<CommonSearchFieldId> kActivityManagementSupportedSearchFields = {
  CommonSearchFieldId.storeCd,
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.storeNm,
  CommonSearchFieldId.supervisorCd,
  CommonSearchFieldId.activityConsultMemo,
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
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _supCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String _brand = '전체';

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  /// 활동일자 구간(칩·API 연동용). [activityDateRange] 항목이 켜져 있을 때 사용.
  late DateTime _activityRangeStart;
  late DateTime _activityRangeEnd;

  (DateTime, DateTime) _defaultActivityDateRange() {
    return kActivityPresetDateRange('최근1개월');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    final r = _defaultActivityDateRange();
    _activityRangeStart = r.$1;
    _activityRangeEnd = r.$2;
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
    _tabController.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _supCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _clearActivityFilterField(CommonSearchFieldId id) {
    switch (id) {
      case CommonSearchFieldId.storeCd:
        _codeCtrl.clear();
        return;
      case CommonSearchFieldId.storeNm:
        _nameCtrl.clear();
        return;
      case CommonSearchFieldId.brandCd:
        _brand = '전체';
        return;
      case CommonSearchFieldId.supervisorCd:
        _supCtrl.clear();
        return;
      case CommonSearchFieldId.activityConsultMemo:
        _memoCtrl.clear();
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

  void _removeMainSearchField(CommonSearchFieldId id) {
    setState(() {
      _visibleMainSearchFields.remove(id);
      _clearActivityFilterField(id);
    });
  }

  String _formatYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _onMainSearchFieldToggle(CommonSearchFieldId id, bool nowVisible) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearActivityFilterField(id);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems() {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.storeNm:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점명을 입력하세요.',
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeCd:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점코드를 입력하세요.',
              controller: _codeCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
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
        case CommonSearchFieldId.supervisorCd:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '담당 수퍼바이저',
              controller: _supCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.activityConsultMemo:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '상담내용·의견 키워드',
              controller: _memoCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          items.add(
            SearchFilterItemData(
              label: '활동일자',
              child: ActivityListDateField(
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

  Widget _filterPickerSheet(VoidCallback refreshSheet) {
    return CommonSearchFieldPicker(
      supported: kActivityManagementSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible);
        refreshSheet();
      },
    );
  }

  /// [필터]에서 켜 둔 본문 검색 항목마다 칩 1개(값이 없으면 `(미입력)`·브랜드는 현재 값).
  /// 예전엔 [activityDateRange]만 필드 켜짐으로「구간 검색」이 붙고 나머지는 입력 후에만
  /// 떴기 때문에, 활동일자만 유독 보이는 것처럼 느껴질 수 있었다.
  List<ActiveFilterChip> _activeFilterChips() {
    final chips = <ActiveFilterChip>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.storeCd:
          final c = _codeCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${c.isEmpty ? '(미입력)' : c}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.storeNm:
          final n = _nameCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${n.isEmpty ? '(미입력)' : n}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.brandCd:
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: $_brand',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.supervisorCd:
          final s = _supCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${s.isEmpty ? '(미입력)' : s}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.activityConsultMemo:
          final m = _memoCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${m.isEmpty ? '(미입력)' : m}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_formatYmd(_activityRangeStart)} ~ ${_formatYmd(_activityRangeEnd)}',
              onClear: () => _removeMainSearchField(def.id),
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
  Widget _managementListPage(
    Widget filterSheet,
    Widget? mainFields,
    Widget table,
  ) {
    return ListPageTemplate(
      activeFilters: _activeFilterChips(),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: '총 0건이 조회되었습니다.',
      onRefresh: () => setState(() {}),
      table: table,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterSheet = StatefulBuilder(
      builder: (context, setModalState) {
        void refreshSheet() => setModalState(() {});
        return _filterPickerSheet(refreshSheet);
      },
    );

    final mainFields = _visibleMainSearchFields.isNotEmpty
        ? SearchFilterStackedItems(items: _mainFilterItems())
        : null;

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
                  filterSheet,
                  mainFields,
                  const ActivityDraftsTable(),
                ),
                const ActivityRegisterView(),
                _managementListPage(
                  filterSheet,
                  mainFields,
                  const _ActivityInstructionsTable(),
                ),
                _managementListPage(
                  filterSheet,
                  mainFields,
                  const _ActivityChecklistTable(),
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
  const _ActivityInstructionsTable();

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
                ErpTableBodyCell('방문', center: true),
                ErpTableBodyCell('2024-04-10', center: true),
                ErpTableBodyCell('할맥', center: true),
                ErpTableBodyCell('서초점', center: true),
                ErpTableBodyCell('지시 이행'),
                ErpTableBodyCell('김철', center: true),
                ErpTableBodyCell('완료', center: true),
                ErpTableBodyCell('활동일지', center: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActivityChecklistTable extends StatelessWidget {
  const _ActivityChecklistTable();

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthDefault + 240,
      tableBuilder: (context, w) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: kErpTableInnerGridBorder,
          columnWidths: const {
            0: FlexColumnWidth(0.45),
            1: FlexColumnWidth(0.5),
            2: FlexColumnWidth(0.4),
            3: FlexColumnWidth(0.5),
            4: FlexColumnWidth(0.75),
            5: FlexColumnWidth(0.5),
            6: FlexColumnWidth(0.5),
            7: FlexColumnWidth(0.45),
            8: FlexColumnWidth(0.4),
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
                ErpTableHeaderCell('등록일'),
                ErpTableHeaderCell('체크리스트'),
                ErpTableHeaderCell('상세'),
              ],
            ),
            TableRow(
              decoration: BoxDecoration(color: AppTheme.tableRowOdd),
              children: [
                ErpTableBodyCell('방문', center: true),
                ErpTableBodyCell('2024-04-21', center: true),
                ErpTableBodyCell('할맥', center: true),
                ErpTableBodyCell('사당역점', center: true),
                ErpTableBodyCell('기본 점검'),
                ErpTableBodyCell('박담', center: true),
                ErpTableBodyCell('2024-04-21', center: true),
                ErpTableBodyCell('완료', center: true),
                ErpTableBodyCell('상세', center: true),
              ],
            ),
          ],
        );
      },
    );
  }
}
