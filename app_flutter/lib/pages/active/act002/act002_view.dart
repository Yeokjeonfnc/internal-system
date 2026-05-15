// act002 — 활동관리(임시보관·등록·지시사항 탭). 활동 다이얼로그는 상위 `active/dialogs/`.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/erp_list_date_range_field.dart';
import 'package:app_flutter/pages/active/act002/act002_note_tab_view.dart';
import 'package:app_flutter/pages/active/act002/act002_view_register.dart';
import 'package:app_flutter/pages/active/act002/act002_widget_drafts.dart';
import 'package:app_flutter/pages/active/act002/act002_filter.dart';

const Set<CommonSearchFieldId> kAct002SearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.activityDateRange,
};

/// 활동관리 > 활동관리 (act002). [initialTab]: 0 임시보관, 1 등록, 2 지시사항.
class Act002View extends StatefulWidget {
  const Act002View({super.key, required this.initialTab});

  final int initialTab;

  @override
  State<Act002View> createState() => _Act002ViewState();
}

class _Act002ViewState extends State<Act002View>
    with SingleTickerProviderStateMixin {
  List<CodeOption> _brandOptions = const [];

  /// 브랜드 필터: `'전체'` 또는 공통코드(grp 40) `codeNm` — `str001_view` 와 동일.
  String _selectedBrandNm = '전체';

  late final TabController _tabController;
  final _keywordCtrl = TextEditingController();
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late final List<int> _tabEpoch;

  (DateTime, DateTime) _defRange() => erpPresetDateRange('최근1개월');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(_onTabChanged);
    final r = _defRange();
    _rangeStart = r.$1;
    _rangeEnd = r.$2;
    _tabEpoch = List<int>.filled(3, 0);
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final brands = await CommonCodeApiService().getCodes(40);
    if (!mounted) return;
    setState(() => _brandOptions = brands);
  }

  List<String> _brandDropdownLabels() {
    return ['전체', ..._brandOptions.map((e) => e.codeNm)];
  }

  /// 선택 브랜드에 대응하는 공통코드 `codeCd` (행 `brandCd` 와 매칭). `'전체'` 는 null.
  String? _brandFilterCd() {
    if (_selectedBrandNm == '전체') return null;
    for (final o in _brandOptions) {
      if (o.codeNm == _selectedBrandNm) return o.codeCd;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant Act002View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = widget.initialTab.clamp(0, 2);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final i = _tabController.index;
    if (i == 1) return;
    setState(() => _tabEpoch[i]++);
  }

  void _reloadList() {
    final i = _tabController.index;
    if (i == 1) return;
    setState(() => _tabEpoch[i]++);
  }

  void _resetFilter(CommonSearchFieldId id) {
    switch (id) {
      case CommonSearchFieldId.brandCd:
        _selectedBrandNm = '전체';
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

  String _fmtYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  List<SearchFilterItemData> _inlineFilters(
    BuildContext context,
    Act002Filter filter,
    List<String> brands,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(kAct002SearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.brandCd:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.brandCd,
              options: brands,
              onSelected: (v) => setState(() => _selectedBrandNm = v),
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
    for (final def in commonSearchDefsOrdered(kAct002SearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.brandCd:
          if (_selectedBrandNm != '전체') {
            chips.add(
              ActiveFilterChip(
                label: '${def.label}: $_selectedBrandNm',
                onClear: () => _clearChip(def.id),
              ),
            );
          }
          break;
        case CommonSearchFieldId.activityDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_fmtYmd(_rangeStart)} ~ ${_fmtYmd(_rangeEnd)}',
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
          Tab(text: '임시보관'),
          Tab(text: '활동관리 등록'),
          Tab(text: '지시사항(결재특이사항)'),
        ],
      ),
    );
  }

  Widget _listShell(Widget mainFields, Widget table) {
    return ListPageTemplate(
      activeFilters: _chips(),
      mainSearchFields: mainFields,
      countText: '총 0건이 조회되었습니다.',
      onRefresh: _reloadList,
      table: table,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = Act002Filter(
      brandCd: _selectedBrandNm,
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
          items: _inlineFilters(context, filter, _brandDropdownLabels()),
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
              // 탭 안 [ErpDataTable] 가로 스크롤과 제스처가 겹치지 않도록 스와이프 전환은 끈다.
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _listShell(
                  mainFields,
                  ActivityDraftsTable(
                    key: ValueKey<int>(_tabEpoch[0]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandLabel: _selectedBrandNm,
                    brandCdFilter: _brandFilterCd(),
                  ),
                ),
                const ActivityRegisterView(),
                _listShell(
                  mainFields,
                  ActivityNoteTabView(
                    key: ValueKey<int>(_tabEpoch[2]),
                    rowKeywordFilter: _keywordCtrl.text.trim(),
                    brandLabel: _selectedBrandNm,
                    brandCdFilter: _brandFilterCd(),
                    rangeStart: _rangeStart,
                    rangeEnd: _rangeEnd,
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
