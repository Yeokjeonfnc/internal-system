// act003 — 활동관리결재. [ListPageTemplate] + 본문 검색·활동관리(act002)와 동일 패턴.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/date/erp_list_date_presets.dart'
    show erpPresetDateRange;
import 'package:app_flutter/core/widgets/common/erp_list_date_range_field.dart';
import 'package:app_flutter/pages/active/act003/act003_filter.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/active/act002/act002_view_manage.dart'
    show kActivityManagementSupportedSearchFields, ActivityChecklistTable;
import 'package:app_flutter/pages/active/act002/act002_widget_drafts.dart';

const Set<CommonSearchFieldId> kAct003SearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.activityDateRange,
};

/// 결재 화면 탭 순서와 [GoRouter] 경로 (상단 배너 제목 동기화).
final List<String> kApprTabs = [
  ActivityRoutes.approvalAll,
  ActivityRoutes.approvalPending,
  ActivityRoutes.approvalActive,
  ActivityRoutes.approvalSuggestions,
  ActivityRoutes.approvalChecklist,
];

/// `/activities/approval/...` 등에서 열릴 때 [initialTab]으로 탭 선택(0=전체 … 4=체크리스트).
class Act003View extends StatefulWidget {
  const Act003View({super.key, required this.initialTab});

  final int initialTab;

  @override
  State<Act003View> createState() => _Act003ViewState();
}

class _Act003ViewState extends State<Act003View>
    with SingleTickerProviderStateMixin {
  List<CodeOption> _brandOptions = const [];
  String _brandNm = '전체';
  late final TabController _tabController;
  final _keywordCtrl = TextEditingController();
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  /// 탭 전환 시 해당 목록 API 재조회용 키.
  late final List<int> _tabEpoch;

  (DateTime, DateTime) _defRange() {
    return erpPresetDateRange('최근1개월');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
    _tabController.addListener(_onTabChanged);
    final r = _defRange();
    _rangeStart = r.$1;
    _rangeEnd = r.$2;
    _tabEpoch = List<int>.filled(5, 0);
    _loadBrands();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!mounted) return;
    final idx = _tabController.index.clamp(0, kApprTabs.length - 1);
    setState(() => _tabEpoch[idx]++);
    final target = kApprTabs[idx];
    final loc = GoRouterState.of(context).uri.path;
    if (loc != target) {
      context.go(target);
    }
  }

  Future<void> _loadBrands() async {
    final brands = await CommonCodeApiService().getCodes(40);
    if (!mounted) return;
    setState(() => _brandOptions = brands);
  }

  List<String> _brandChipLabels() {
    return ['전체', ..._brandOptions.map((e) => e.codeNm)];
  }

  String? _brandFilterCd() {
    if (_brandNm == '전체') return null;
    for (final o in _brandOptions) {
      if (o.codeNm == _brandNm) return o.codeCd;
    }
    return null;
  }

  /// 목록 [ListPageTemplate] 새로고침 — 현재 탭 테이블을 재생성해 API 재조회.
  void _reloadList() {
    if (!mounted) return;
    final idx = _tabController.index.clamp(0, _tabEpoch.length - 1);
    setState(() => _tabEpoch[idx]++);
  }

  @override
  void didUpdateWidget(covariant Act003View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = widget.initialTab.clamp(0, 4);
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
        _brandNm = '전체';
        return;
      case CommonSearchFieldId.activityDateRange:
        final d = _defRange();
        _rangeStart = d.$1;
        _rangeEnd = d.$2;
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

  List<SearchFilterItemData> _inlineFilters(
    BuildContext context,
    Act003Filter filter,
    List<String> brands,
  ) {
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
              value: filter.brandCd,
              options: brands,
              onSelected: (v) => setState(() => _brandNm = v),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          items.add(
            SearchFilterItemData(
              label: '활동일자',
              child: ErpListDateRangeField(
                start: _rangeStart,
                end: _rangeEnd,
                onRangeChanged: (a, b) {
                  setState(() {
                    _rangeStart = a;
                    _rangeEnd = b;
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
              label: '${def.label}: $_brandNm',
              onClear: () => _clearChip(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.activityDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_formatYmd(_rangeStart)} ~ ${_formatYmd(_rangeEnd)}',
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

  Widget _tabBar() {
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
          Tab(text: '전체활동관리'),
          Tab(text: '결재대기'),
          Tab(text: '결재완료'),
          Tab(text: '건의사항'),
          Tab(text: '체크리스트'),
        ],
      ),
    );
  }

  Widget _listShell(Widget mainFields, {Widget? customTable}) {
    return ListPageTemplate(
      activeFilters: _chips(),
      mainSearchFields: mainFields,
      countText: '총 0건이 조회되었습니다.',
      onRefresh: _reloadList,
      table: customTable ?? const ActivityDraftsTable(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = Act003Filter(
      brandCd: _brandNm,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      keyword: _keywordCtrl.text.trim(),
    );
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
        SearchFilterStackedItems(
          items: _inlineFilters(context, filter, _brandChipLabels()),
        ),
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
              children: [
                _listShell(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_tabEpoch[0]),
                    mode: ActivityDraftsTableMode.approvalAll,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandCdFilter: _brandFilterCd(),
                  ),
                ),
                _listShell(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_tabEpoch[1]),
                    mode: ActivityDraftsTableMode.approvalPending,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandCdFilter: _brandFilterCd(),
                  ),
                ),
                _listShell(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_tabEpoch[2]),
                    mode: ActivityDraftsTableMode.approvalApproved,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandCdFilter: _brandFilterCd(),
                  ),
                ),
                _listShell(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_tabEpoch[3]),
                    mode: ActivityDraftsTableMode.approvalSuggestions,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandCdFilter: _brandFilterCd(),
                  ),
                ),
                _listShell(
                  mainFields,
                  customTable: ActivityChecklistTable(
                    key: ValueKey<int>(_tabEpoch[4]),
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
