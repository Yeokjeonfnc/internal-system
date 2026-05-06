// 활동관리결재 — [ListPageTemplate] + 본문 검색·임시보관과 동일 패턴.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

import 'activity_date_presets.dart';
import 'activity_drafts_table.dart';
import 'activity_list_date_field.dart';
import 'activity_management_view.dart'
    show kActivityManagementSupportedSearchFields, ActivityChecklistTable;
import 'activity_routes.dart';

/// 결재 화면 탭 순서와 [GoRouter] 경로 (상단 배너 제목 동기화).
final List<String> kActivityApprovalTabPaths = [
  ActivityRoutes.approvalAll,
  ActivityRoutes.approvalPending,
  ActivityRoutes.approvalActive,
  ActivityRoutes.approvalSuggestions,
  ActivityRoutes.approvalChecklist,
];

/// `/activities/approval/...` 등에서 열릴 때 [initialTab]으로 탭 선택(0=전체 … 4=체크리스트).
class ActivityApprovalManagementView extends StatefulWidget {
  const ActivityApprovalManagementView({super.key, required this.initialTab});

  final int initialTab;

  @override
  State<ActivityApprovalManagementView> createState() =>
      _ActivityApprovalManagementViewState();
}

class _ActivityApprovalManagementViewState
    extends State<ActivityApprovalManagementView>
    with SingleTickerProviderStateMixin {
  static const _brands = ['전체', '역전할머니맥주', '지미존스'];

  late final TabController _tabController;
  final _keywordCtrl = TextEditingController();
  String _brand = '전체';

  late DateTime _activityRangeStart;
  late DateTime _activityRangeEnd;

  /// 탭 전환 시 해당 목록 API 재조회용 키.
  late final List<int> _approvalTabReloadEpoch;

  (DateTime, DateTime) _defaultActivityDateRange() {
    return kActivityPresetDateRange('최근1개월');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
    _tabController.addListener(_onApprovalTabChanged);
    final r = _defaultActivityDateRange();
    _activityRangeStart = r.$1;
    _activityRangeEnd = r.$2;
    _approvalTabReloadEpoch = List<int>.filled(5, 0);
  }

  void _onApprovalTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!mounted) return;
    final idx =
        _tabController.index.clamp(0, kActivityApprovalTabPaths.length - 1);
    setState(() => _approvalTabReloadEpoch[idx]++);
    final target = kActivityApprovalTabPaths[idx];
    final loc = GoRouterState.of(context).uri.path;
    if (loc != target) {
      context.go(target);
    }
  }

  /// 목록 [ListPageTemplate] 새로고침 — 현재 탭 테이블을 재생성해 API 재조회.
  void _reloadCurrentApprovalListTab() {
    if (!mounted) return;
    final idx = _tabController.index.clamp(0, _approvalTabReloadEpoch.length - 1);
    setState(() => _approvalTabReloadEpoch[idx]++);
  }

  @override
  void didUpdateWidget(covariant ActivityApprovalManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = widget.initialTab.clamp(0, 4);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onApprovalTabChanged);
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
    for (final def in commonSearchDefsOrdered(kActivityManagementSupportedSearchFields)) {
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
    for (final def in commonSearchDefsOrdered(kActivityManagementSupportedSearchFields)) {
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

  Widget _topApprovalTabBar() {
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

  Widget _approvalListPage(
    Widget mainFields, {
    Widget? customTable,
  }) {
    return ListPageTemplate(
      activeFilters: _activeFilterChips(),
      mainSearchFields: mainFields,
      countText: '총 0건이 조회되었습니다.',
      onRefresh: _reloadCurrentApprovalListTab,
      table: customTable ?? const ActivityDraftsTable(),
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

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topApprovalTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _approvalListPage(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_approvalTabReloadEpoch[0]),
                    mode: ActivityDraftsTableMode.approvalAll,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                  ),
                ),
                _approvalListPage(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_approvalTabReloadEpoch[1]),
                    mode: ActivityDraftsTableMode.approvalPending,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                  ),
                ),
                _approvalListPage(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_approvalTabReloadEpoch[2]),
                    mode: ActivityDraftsTableMode.approvalApproved,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                  ),
                ),
                _approvalListPage(
                  mainFields,
                  customTable: ActivityDraftsTable(
                    key: ValueKey<int>(_approvalTabReloadEpoch[3]),
                    mode: ActivityDraftsTableMode.approvalSuggestions,
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                  ),
                ),
                _approvalListPage(
                  mainFields,
                  customTable: ActivityChecklistTable(
                    key: ValueKey<int>(_approvalTabReloadEpoch[4]),
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
