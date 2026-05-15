// 영업지역 관리 — 필터·집계 탭·테이블.

import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/erp_list_date_range_field.dart';
import 'package:app_flutter/core/date/erp_list_date_presets.dart'
    show erpPresetDateRange;
import 'package:app_flutter/pages/development/dev003/dev003_controller.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/dev003_provider.dart';

/// 영업지역 관리 — 본문에 항상 노출하는 검색 항목(통합 텍스트 검색은 상단 필드).
const Set<CommonSearchFieldId> kSalesAreaListSupportedSearchFields = {
  CommonSearchFieldId.brandCd,
  CommonSearchFieldId.regionCd,
  CommonSearchFieldId.salesAreaSettingDateRange,
};

/// 영업지역 관리.
class SalesAreaListView extends ConsumerStatefulWidget {
  const SalesAreaListView({super.key});

  @override
  ConsumerState<SalesAreaListView> createState() => _SalesAreaListViewState();
}

class _SalesAreaListViewState extends ConsumerState<SalesAreaListView> {
  late final TextEditingController _keywordCtrl;
  List<CodeOption> _brandOptions = const [];
  List<CodeOption> _regionOptions = const [];

  (DateTime, DateTime) _defRange() {
    return erpPresetDateRange('전체');
  }

  @override
  void initState() {
    super.initState();
    final f = ref.read(salesAreaProvider);
    _keywordCtrl = TextEditingController(text: f.keyword);
    _loadBrands();
    _loadRegions();
  }

  Future<void> _loadBrands() async {
    final brands = await CommonCodeApiService().getCodes(40);
    if (!mounted) return;
    setState(() => _brandOptions = brands);
  }

  List<String> _brandChipLabels() {
    return ['전체', ..._brandOptions.map((e) => e.codeNm)];
  }

  Future<void> _loadRegions() async {
    final regions = await CommonCodeApiService().getCodes(20);
    if (!mounted) return;
    setState(() => _regionOptions = regions);
  }

  List<String> _regionChipLabels() {
    return ['전체', ..._regionOptions.map((e) => e.codeNm)];
  }

  String _formatYmd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _resetFilter(SalesAreaNotifier n, CommonSearchFieldId id) {
    switch (id) {
      case CommonSearchFieldId.regionCd:
        n.setRegionCd('전체');
        return;
      case CommonSearchFieldId.brandCd:
        n.setBrandCd('전체');
        return;
      case CommonSearchFieldId.salesAreaSettingDateRange:
        final d = _defRange();
        n.setDateRange(d.$1, d.$2);
        return;
      default:
        return;
    }
  }

  void _clearChip(SalesAreaNotifier n, CommonSearchFieldId id) {
    setState(() => _resetFilter(n, id));
  }

  List<SearchFilterItemData> _mainFilterItems(
    SalesAreaFilter filter,
    SalesAreaNotifier n,
    List<String> brands,
    List<String> regions,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(
      kSalesAreaListSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.brandCd:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.brandCd,
              options: brands,
              onSelected: (v) => setState(() => n.setBrandCd(v)),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.regionCd:
          final regionOpts = regions.where((e) => e != '전체').toList();
          items.add(
            SearchFilterItemData(
              label: def.label,
              child: SearchFilterMultiSelectField(
                summaryText: searchFilterMultiSelectSummary(
                  filter.regionNms,
                  formatMultiple: searchFilterMultiSelectSummarySortedPreview,
                ),
                onTap: () => showDialogWithRef(
                  context: context,
                  options: regionOpts,
                  bindings: (ref) => SearchFilterMultiPickBindings(
                    selected: ref.watch(salesAreaProvider).regionNms,
                    onToggle: ref.read(salesAreaProvider.notifier).toggleRegion,
                  ),
                  title: '지역 검색',
                  searchHint: '지역명을 검색해주세요',
                  emptyOptionsMessage: '등록된 지역이 없습니다.',
                  emptySearchMessage: '검색 결과가 없습니다.',
                ),
              ),
            ),
          );
          break;
        case CommonSearchFieldId.salesAreaSettingDateRange:
          items.add(
            SearchFilterItemData(
              label: def.label,
              child: ErpListDateRangeField(
                initialPresetLabel: '전체',
                start: filter.rangeStart,
                end: filter.rangeEnd,
                onRangeChanged: (a, b) {
                  setState(() => n.setDateRange(a, b));
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

  List<ActiveFilterChip> _chips(SalesAreaFilter f, SalesAreaNotifier n) {
    final chips = <ActiveFilterChip>[];
    final kw = _keywordCtrl.text.trim();
    if (kw.isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: $kw',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setKeyword('');
            });
          },
        ),
      );
    }
    for (final def in commonSearchDefsOrdered(
      kSalesAreaListSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.brandCd:
          if (f.brandCd != '전체') {
            chips.add(
              ActiveFilterChip(
                label: '${def.label}: ${f.brandCd}',
                onClear: () => _clearChip(n, def.id),
              ),
            );
          }
          break;
        case CommonSearchFieldId.regionCd:
          if (f.regionNms.isNotEmpty) {
            final sorted = f.regionNms.toList()..sort();
            final label = sorted.length <= 3
                ? sorted.join(', ')
                : '${sorted.take(3).join(', ')} 외 ${sorted.length - 3}건';
            chips.add(
              ActiveFilterChip(
                label: '지역: $label',
                onClear: () => n.clearRegions(),
              ),
            );
          }
          break;
        case CommonSearchFieldId.salesAreaSettingDateRange:
          chips.add(
            ActiveFilterChip(
              label:
                  '${def.label}: ${_formatYmd(f.rangeStart)} ~ ${_formatYmd(f.rangeEnd)}',
              onClear: () => _clearChip(n, def.id),
            ),
          );
          break;
        default:
          break;
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(salesAreaProvider);
    final n = ref.read(salesAreaProvider.notifier);
    final listAsync = ref.watch(dev003DataProvider);
    final regionOptions =
        ref.watch(salesAreaCodeOptionsProvider(20)).valueOrNull ??
        const <CodeOption>[];
    final rawRows = listAsync.valueOrNull ?? const <SalesAreaRow>[];
    final rows = dev003ApplyClientFilters(filter, rawRows, regionOptions);

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
          onChanged: (_) => setState(() => n.setKeyword(_keywordCtrl.text)),
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(
          items: _mainFilterItems(
            filter,
            n,
            _brandChipLabels(),
            _regionChipLabels(),
          ),
        ),
      ],
    );
    final counts = dev003AreaSummary(rows);
    return ListPageTemplate(
      activeFilters: _chips(filter, n),
      mainSearchFields: mainFields,
      belowMainSearch: _SalesAreaSummaryBar(
        total: counts.total,
        configured: counts.configured,
        unset: counts.unset,
      ),
      countText: listAsync.when(
        data: (_) => '총 ${rows.length}건이 조회되었습니다.',
        loading: () => '목록을 불러오는 중…',
        error: (_, _) => '목록을 불러오지 못했습니다.',
      ),
      onRefresh: () {
        ref.invalidate(dev003DataProvider);
        setState(() {});
      },
      table: listAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('오류: $e', style: const TextStyle(fontSize: 14)),
          ),
        ),
        data: (_) => _SalesAreaTable(
          rows: rows,
          regionOptions: regionOptions,
          onRowDoubleTap: (row) =>
              context.go('${AppRoutes.salesAreas}/register/${row.id}'),
        ),
      ),
    );
  }
}

class _SalesAreaSummaryBar extends StatelessWidget {
  const _SalesAreaSummaryBar({
    required this.total,
    required this.configured,
    required this.unset,
  });

  final int total;
  final int configured;
  final int unset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryTile(label: '총가맹점', count: total),
              const SizedBox(height: 7),
              _summaryTile(label: '설정가맹점', count: configured),
              const SizedBox(height: 7),
              _summaryTile(label: '미설정가맹점', count: unset),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _summaryTile(label: '총가맹점', count: total),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(label: '설정가맹점', count: configured),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(label: '미설정가맹점', count: unset),
            ),
          ],
        );
      },
    );
  }

  static const _purpleBg = Color.fromRGBO(255, 218, 229, 1);
  Widget _summaryTile({required String label, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: _purpleBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kSearchFilterTextColor,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentRed,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          Text(
            '개점',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kSearchFilterTextColor,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesAreaTable extends StatelessWidget {
  const _SalesAreaTable({
    required this.rows,
    required this.regionOptions,
    required this.onRowDoubleTap,
  });

  final List<SalesAreaRow> rows;
  final List<CodeOption> regionOptions;
  final void Function(SalesAreaRow row) onRowDoubleTap;

  static Widget _cell(Widget child, {required void Function() onDoubleTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: 1280,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(110),
          1: FlexColumnWidth(1.1),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(80),
          4: FlexColumnWidth(1.4),
          5: FixedColumnWidth(120),
          6: FixedColumnWidth(100),
          7: FlexColumnWidth(1.2),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.accentRed),
            children: const [
              ErpTableHeaderCell('설정일자'),
              ErpTableHeaderCell('물건명'),
              ErpTableHeaderCell('지역'),
              ErpTableHeaderCell('가맹여부'),
              ErpTableHeaderCell('가맹점명'),
              ErpTableHeaderCell('브랜드'),
              ErpTableHeaderCell('영업지역설정'),
              ErpTableHeaderCell('영업지역명'),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final e = entry.value;
            void open() => onRowDoubleTap(e);
            return TableRow(
              decoration: BoxDecoration(
                color: entry.key.isEven
                    ? AppTheme.tableRowOdd
                    : AppTheme.tableRowEven,
              ),
              children: [
                _cell(
                  ErpTableBodyCell(e.settingDateYmd, center: true),
                  onDoubleTap: open,
                ),
                _cell(
                  ErpTableBodyCell(e.propertyName, center: true),
                  onDoubleTap: open,
                ),
                _cell(
                  ErpTableBodyCell(
                    _regionNm(e.region, regionOptions),
                    center: true,
                  ),
                  onDoubleTap: open,
                ),
                _cell(
                  ErpTableBodyCell(e.franchiseLabel, center: true),
                  onDoubleTap: open,
                ),
                _cell(ErpTableBodyCell(e.storeName), onDoubleTap: open),
                _cell(
                  ErpTableBodyCell(e.brand, center: true),
                  onDoubleTap: open,
                ),
                _cell(
                  ErpTableBodyCell(e.areaSettingLabel, center: true),
                  onDoubleTap: open,
                ),
                _cell(ErpTableBodyCell(e.salesAreaName), onDoubleTap: open),
              ],
            );
          }),
        ],
      ),
    );
  }
}

String _regionNm(String code, List<CodeOption> options) {
  if (code.isEmpty) return '-';
  for (final option in options) {
    if (option.codeCd == code) return option.codeNm;
  }
  return code;
}
