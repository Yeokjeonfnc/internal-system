// 영업지역 관리 — 필터·집계 탭·테이블.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_field_picker.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/features/activities/activity_list_date_field.dart';
import 'sales_area_controller.dart';
import 'sales_area_model.dart';

/// 영업지역 관리 — 본문에 켤 수 있는 검색 항목(가맹점·창업자 목록과 동일 패턴).
const Set<CommonSearchFieldId> kSalesAreaListSupportedSearchFields = {
  CommonSearchFieldId.salesAreaName,
  CommonSearchFieldId.salesAreaPropertyName,
  CommonSearchFieldId.salesAreaBrand,
  CommonSearchFieldId.salesAreaRegion,
  CommonSearchFieldId.salesAreaSettingDateRange,
};

/// 영업지역 관리.
class SalesAreaListView extends ConsumerStatefulWidget {
  const SalesAreaListView({super.key});

  @override
  ConsumerState<SalesAreaListView> createState() => _SalesAreaListViewState();
}

class _SalesAreaListViewState extends ConsumerState<SalesAreaListView> {
  late final TextEditingController _areaNameCtrl;
  late final TextEditingController _propertyNameCtrl;
  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  @override
  void initState() {
    super.initState();
    final f = ref.read(salesAreaProvider);
    _areaNameCtrl = TextEditingController(text: f.salesAreaName);
    _propertyNameCtrl = TextEditingController(text: f.propertyName);
  }

  @override
  void dispose() {
    _areaNameCtrl.dispose();
    _propertyNameCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearSalesAreaFilterField(CommonSearchFieldId id, SalesAreaNotifier n) {
    switch (id) {
      case CommonSearchFieldId.salesAreaName:
        _areaNameCtrl.clear();
        n.setSalesAreaName('');
        return;
      case CommonSearchFieldId.salesAreaPropertyName:
        _propertyNameCtrl.clear();
        n.setPropertyName('');
        return;
      case CommonSearchFieldId.salesAreaBrand:
        n.setBrand('전체');
        return;
      case CommonSearchFieldId.salesAreaRegion:
        n.setRegion('전체');
        return;
      case CommonSearchFieldId.salesAreaStrategicOnly:
      case CommonSearchFieldId.salesAreaIncludeNonFranchise:
      case CommonSearchFieldId.salesAreaIncludeUnset:
        return;
      case CommonSearchFieldId.salesAreaSettingDateRange:
        n.clearSettingDateRangeToDefault();
        return;
      case CommonSearchFieldId.storeName:
      case CommonSearchFieldId.storeCode:
      case CommonSearchFieldId.brand:
      case CommonSearchFieldId.contractStatus:
      case CommonSearchFieldId.supervisor:
      case CommonSearchFieldId.storeCategory:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
      case CommonSearchFieldId.region:
      case CommonSearchFieldId.mobilePhone:
      case CommonSearchFieldId.registrationDate:
      case CommonSearchFieldId.propertyName:
      case CommonSearchFieldId.propertyOwnership:
      case CommonSearchFieldId.propertyAddress:
      case CommonSearchFieldId.founderName:
      case CommonSearchFieldId.founderEvaluation:
      case CommonSearchFieldId.founderStatus:
      case CommonSearchFieldId.activityConsultMemo:
      case CommonSearchFieldId.activityDateRange:
      case CommonSearchFieldId.employeeName:
      case CommonSearchFieldId.employeeDepartment:
      case CommonSearchFieldId.employeeEmail:
      case CommonSearchFieldId.employeePhone:
        return;
    }
  }

  void _onMainSearchFieldToggle(
    CommonSearchFieldId id,
    bool nowVisible,
    SalesAreaNotifier n,
  ) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearSalesAreaFilterField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    SalesAreaFilter filter,
    List<String> brands,
    List<String> regions,
    SalesAreaNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.salesAreaName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '영업지역명을 입력하세요.',
              controller: _areaNameCtrl,
              onChanged: n.setSalesAreaName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.salesAreaPropertyName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '물건명을 입력하세요.',
              controller: _propertyNameCtrl,
              onChanged: n.setPropertyName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.salesAreaBrand:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.brand,
              options: brands,
              onSelected: n.setBrand,
              forceDropdown: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.salesAreaRegion:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.region,
              options: regions,
              onSelected: n.setRegion,
              forceDropdown: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.salesAreaSettingDateRange:
          items.add(
            SearchFilterItemData(
              label: def.label,
              child: ActivityListDateField(
                start: filter.rangeStart ?? DateTime.now(),
                end: filter.rangeEnd ?? DateTime.now(),
                onRangeChanged: n.setDateRange,
              ),
            ),
          );
          break;
        case CommonSearchFieldId.salesAreaStrategicOnly:
        case CommonSearchFieldId.salesAreaIncludeNonFranchise:
        case CommonSearchFieldId.salesAreaIncludeUnset:
          break;
        case CommonSearchFieldId.storeName:
        case CommonSearchFieldId.storeCode:
        case CommonSearchFieldId.brand:
        case CommonSearchFieldId.contractStatus:
        case CommonSearchFieldId.supervisor:
        case CommonSearchFieldId.storeCategory:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
        case CommonSearchFieldId.region:
        case CommonSearchFieldId.mobilePhone:
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyAddress:
        case CommonSearchFieldId.founderName:
        case CommonSearchFieldId.founderEvaluation:
        case CommonSearchFieldId.founderStatus:
        case CommonSearchFieldId.activityConsultMemo:
        case CommonSearchFieldId.activityDateRange:
        case CommonSearchFieldId.employeeName:
        case CommonSearchFieldId.employeeDepartment:
        case CommonSearchFieldId.employeeEmail:
        case CommonSearchFieldId.employeePhone:
          break;
      }
    }
    return items;
  }

  Widget _filterPickerSheet(VoidCallback refreshSheet, SalesAreaNotifier n) {
    return CommonSearchFieldPicker(
      supported: kSalesAreaListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible, n);
        refreshSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(salesAreaProvider);
    final n = ref.read(salesAreaProvider.notifier);
    final rows = n.getFilteredList();
    final brands = ref.watch(salesAreaRepositoryProvider).brandOptions();
    final regions = ref.watch(salesAreaRepositoryProvider).regionOptions();

    final filterSheet = StatefulBuilder(
      builder: (context, setModalState) {
        void refreshSheet() => setModalState(() {});
        return _filterPickerSheet(refreshSheet, n);
      },
    );

    final mainFilterBlock = _anyMainFilter
        ? SearchFilterStackedItems(
            items: _mainFilterItems(filter, brands, regions, n),
          )
        : null;

    final counts = n.areaSummaryCounts;

    final topBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SalesAreaQuickToggles(filter: filter, notifier: n),
        const SizedBox(height: 12),
        if (mainFilterBlock != null) ...[
          mainFilterBlock,
          const SizedBox(height: 12),
        ],
        _SalesAreaSummaryBar(
          total: counts.total,
          configured: counts.configured,
          unset: counts.unset,
        ),
      ],
    );

    return ListPageTemplate(
      activeFilters: _activeChips(filter, n),
      filterSheetBody: filterSheet,
      mainSearchFields: topBody,
      countText: '총 ${rows.length}건이 조회되었습니다.',
      table: _SalesAreaTable(
        rows: rows,
        onRowDoubleTap: (row) {
          context.pushNamed(
            AppRouteNames.salesAreaRegister,
            pathParameters: {'rowId': '${row.id}'},
          );
        },
      ),
    );
  }

  List<ActiveFilterChip> _activeChips(SalesAreaFilter f, SalesAreaNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.salesAreaName.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '영업지역명: ${f.salesAreaName}',
          onClear: () {
            setState(() {
              _areaNameCtrl.clear();
              n.setSalesAreaName('');
            });
          },
        ),
      );
    }
    if (f.propertyName.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '물건명: ${f.propertyName}',
          onClear: () {
            setState(() {
              _propertyNameCtrl.clear();
              n.setPropertyName('');
            });
          },
        ),
      );
    }
    if (f.brand != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '브랜드: ${f.brand}',
          onClear: () => n.setBrand('전체'),
        ),
      );
    }
    if (f.region != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '지역: ${f.region}',
          onClear: () => n.setRegion('전체'),
        ),
      );
    }
    if (f.strategicOpeningOnly) {
      chips.add(
        ActiveFilterChip(
          label: '전략출점지역만',
          onClear: () => n.setStrategicOpeningOnly(false),
        ),
      );
    }
    if (f.includeNonFranchise) {
      chips.add(
        ActiveFilterChip(
          label: '비가맹 물건 포함',
          onClear: () => n.setIncludeNonFranchise(false),
        ),
      );
    }
    if (f.includeUnsetArea) {
      chips.add(
        ActiveFilterChip(
          label: '영업지역 미설정 포함',
          onClear: () => n.setIncludeUnsetArea(false),
        ),
      );
    }
    return chips;
  }
}

/// 본문 상단에 고정: 전략출점 / 비가맹 / 미설정 — 검색조건 시트에 넣지 않는다.
class _SalesAreaQuickToggles extends StatelessWidget {
  const _SalesAreaQuickToggles({required this.filter, required this.notifier});

  final SalesAreaFilter filter;
  final SalesAreaNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _toggleCell(
            label: '전략출점지역 보기',
            value: filter.strategicOpeningOnly,
            onChanged: notifier.setStrategicOpeningOnly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _toggleCell(
            label: '비가맹 물건 포함',
            value: filter.includeNonFranchise,
            onChanged: notifier.setIncludeNonFranchise,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _toggleCell(
            label: '영업지역 미설정 포함',
            value: filter.includeUnsetArea,
            onChanged: notifier.setIncludeUnsetArea,
          ),
        ),
      ],
    );
  }

  Widget _toggleCell({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: value,
                activeColor: AppTheme.accentRed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 현재 조회 조건에 대한 집계 — **버튼 아님**(표시 전용).
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
              const SizedBox(height: 8),
              _summaryTile(label: '설정가맹점', count: configured),
              const SizedBox(height: 8),
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

  static const _purpleBg = Color.fromARGB(255, 252, 160, 160);

  Widget _summaryTile({required String label, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
  const _SalesAreaTable({required this.rows, required this.onRowDoubleTap});

  final List<SalesAreaRow> rows;
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
                _cell(ErpTableBodyCell(e.propertyName), onDoubleTap: open),
                _cell(
                  ErpTableBodyCell(e.region, center: true),
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
                _cell(ErpTableBodyCell(formatPhoneNumber(e.salesAreaName)), onDoubleTap: open),
              ],
            );
          }),
        ],
      ),
    );
  }
}
