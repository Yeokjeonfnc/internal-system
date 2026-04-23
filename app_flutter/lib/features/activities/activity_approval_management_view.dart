// 활동관리결재 — [ListPageTemplate] + 임시보관과 동일 필터/표(목업).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_field_picker.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

import 'activity_date_presets.dart';
import 'activity_drafts_table.dart';
import 'activity_list_date_field.dart';
import 'activity_management_view.dart' show kActivityManagementSupportedSearchFields;

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
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _supCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String _brand = '전체';

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};
  late DateTime _activityRangeStart;
  late DateTime _activityRangeEnd;

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
    final r = _defaultActivityDateRange();
    _activityRangeStart = r.$1;
    _activityRangeEnd = r.$2;
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
    _tabController.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _supCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _clearActivityFilterField(CommonSearchFieldId id) {
    switch (id) {
      case CommonSearchFieldId.storeCode:
        _codeCtrl.clear();
        return;
      case CommonSearchFieldId.storeName:
        _nameCtrl.clear();
        return;
      case CommonSearchFieldId.brand:
        _brand = '전체';
        return;
      case CommonSearchFieldId.supervisor:
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
        case CommonSearchFieldId.storeName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점명을 입력하세요.',
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeCode:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점코드를 입력하세요.',
              controller: _codeCtrl,
              onChanged: (_) => setState(() {}),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.brand:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: _brand,
              options: _brands,
              onSelected: (v) => setState(() => _brand = v),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.supervisor:
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

  List<ActiveFilterChip> _activeFilterChips() {
    final chips = <ActiveFilterChip>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.storeCode:
          final c = _codeCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${c.isEmpty ? '(미입력)' : c}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.storeName:
          final n = _nameCtrl.text.trim();
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: ${n.isEmpty ? '(미입력)' : n}',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.brand:
          chips.add(
            ActiveFilterChip(
              label: '${def.label}: $_brand',
              onClear: () => _removeMainSearchField(def.id),
            ),
          );
          break;
        case CommonSearchFieldId.supervisor:
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
          Tab(text: '결재진행'),
          Tab(text: '건의사항'),
          Tab(text: '체크리스트'),
        ],
      ),
    );
  }

  Widget _approvalListPage(Widget filterSheet, Widget? mainFields) {
    return ListPageTemplate(
      activeFilters: _activeFilterChips(),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: '총 1건이 조회되었습니다. (목업)',
      table: const ActivityDraftsTable(),
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
                _approvalListPage(filterSheet, mainFields),
                _approvalListPage(filterSheet, mainFields),
                _approvalListPage(filterSheet, mainFields),
                _approvalListPage(filterSheet, mainFields),
                _approvalListPage(filterSheet, mainFields),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
