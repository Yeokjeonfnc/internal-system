// 가맹점 목록 화면: 필터·테이블·상세 이동을 담당한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_field_picker.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/features/stores/store_model.dart';
import 'package:app_flutter/features/stores/store_controller.dart';

/// 가맹점 목록에서 켤 수 있는 공통 검색 항목(다른 화면은 다른 [Set]을 두면 됨).
const Set<CommonSearchFieldId> kStoreListSupportedSearchFields = {
  CommonSearchFieldId.storeName,
  CommonSearchFieldId.storeCode,
  CommonSearchFieldId.brand,
  CommonSearchFieldId.contractStatus,
  CommonSearchFieldId.region,
};

/// 가맹점 목록.
class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({super.key});

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;

  /// 본문 카드에 노출할 공통 검색 항목(필터 시트에서 토글).
  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  @override
  void initState() {
    super.initState();
    final s = ref.read(storeProvider);
    _nameCtrl = TextEditingController(text: s.name);
    _codeCtrl = TextEditingController(text: s.code);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearStoreFilterField(CommonSearchFieldId id, StoreNotifier n) {
    switch (id) {
      case CommonSearchFieldId.storeName:
        _nameCtrl.clear();
        n.setName('');
        return;
      case CommonSearchFieldId.storeCode:
        _codeCtrl.clear();
        n.setCode('');
        return;
      case CommonSearchFieldId.brand:
        n.setBrand('전체');
        return;
      case CommonSearchFieldId.contractStatus:
        n.clearContractStatuses();
        return;
      case CommonSearchFieldId.region:
        n.setRegion('전체');
        return;
      case CommonSearchFieldId.supervisor:
      case CommonSearchFieldId.storeCategory:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
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
      case CommonSearchFieldId.salesAreaName:
      case CommonSearchFieldId.salesAreaPropertyName:
      case CommonSearchFieldId.salesAreaBrand:
      case CommonSearchFieldId.salesAreaRegion:
      case CommonSearchFieldId.salesAreaStrategicOnly:
      case CommonSearchFieldId.salesAreaIncludeNonFranchise:
      case CommonSearchFieldId.salesAreaIncludeUnset:
      case CommonSearchFieldId.salesAreaSettingDateRange:
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
    StoreNotifier n,
  ) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearStoreFilterField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    StoreFilter filter,
    List<String> brands,
    List<String> regions,
    StoreNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.storeName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점명을 입력하세요.',
              controller: _nameCtrl,
              onChanged: n.setName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeCode:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '가맹점코드 입력하세요.',
              controller: _codeCtrl,
              onChanged: n.setCode,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.brand:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.brand,
              options: brands,
              onSelected: n.setBrand,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.contractStatus:
          items.add(
            _StoreContractStatusMultiSlot(filter: filter, notifier: n).toItem(),
          );
          break;
        case CommonSearchFieldId.region:
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
        case CommonSearchFieldId.supervisor:
        case CommonSearchFieldId.storeCategory:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
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
        case CommonSearchFieldId.salesAreaName:
        case CommonSearchFieldId.salesAreaPropertyName:
        case CommonSearchFieldId.salesAreaBrand:
        case CommonSearchFieldId.salesAreaRegion:
        case CommonSearchFieldId.salesAreaStrategicOnly:
        case CommonSearchFieldId.salesAreaIncludeNonFranchise:
        case CommonSearchFieldId.salesAreaIncludeUnset:
        case CommonSearchFieldId.salesAreaSettingDateRange:
        case CommonSearchFieldId.employeeName:
        case CommonSearchFieldId.employeeDepartment:
        case CommonSearchFieldId.employeeEmail:
        case CommonSearchFieldId.employeePhone:
          break;
      }
    }
    return items;
  }

  Widget _filterPickerSheet(VoidCallback refreshSheet, StoreNotifier n) {
    return CommonSearchFieldPicker(
      supported: kStoreListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible, n);
        refreshSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(storeProvider);
    final n = ref.read(storeProvider.notifier);
    final rows = n.getFilteredList();
    final brands = ref.watch(storeRepositoryProvider).brands();
    final regions = ref.watch(storeRepositoryProvider).regions();

    final filterSheet = StatefulBuilder(
      builder: (context, setModalState) {
        void refreshSheet() => setModalState(() {});
        return _filterPickerSheet(refreshSheet, n);
      },
    );

    final mainFields = _anyMainFilter
        ? SearchFilterStackedItems(
            items: _mainFilterItems(filter, brands, regions, n),
          )
        : null;

    return ListPageTemplate(
      activeFilters: _activeFilterChips(filter, n),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: '총 ${rows.length}개의 가맹점이 조회되었습니다.',
      onRegister: () => context.goNamed(AppRouteNames.storeRegister),
      table: _StoreTable(rows: rows),
    );
  }

  List<ActiveFilterChip> _activeFilterChips(StoreFilter f, StoreNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.name.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '가맹점명: ${f.name}',
          onClear: () {
            setState(() {
              _nameCtrl.clear();
              n.setName('');
            });
          },
        ),
      );
    }
    if (f.code.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '가맹점코드: ${f.code}',
          onClear: () {
            setState(() {
              _codeCtrl.clear();
              n.setCode('');
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
    if (f.statuses.isNotEmpty) {
      final joined = f.statuses.map(_storeStatusLabel).join(', ');
      chips.add(
        ActiveFilterChip(
          label: '계약상태: $joined',
          onClear: () => n.clearContractStatuses(),
        ),
      );
    }
    return chips;
  }
}

String _storeStatusLabel(StoreStatus s) => switch (s) {
  StoreStatus.newContract => '신규계약',
  StoreStatus.renewal => '재계약',
  StoreStatus.transfer => '양수도',
};

/// 계약상태: [FilterChip] 으로 중복 선택.
class _StoreContractStatusMultiSlot implements FilterSlotConfig {
  _StoreContractStatusMultiSlot({required this.filter, required this.notifier});

  final StoreFilter filter;
  final StoreNotifier notifier;

  @override
  SearchFilterItemData toItem() {
    return SearchFilterItemData(
      label: '계약상태',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            showCheckmark: false,
            label: Text(
              '전체',
              style: TextStyle(
                fontSize: kSearchFilterFontSize,
                fontWeight: filter.statuses.isEmpty
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: filter.statuses.isEmpty
                    ? AppTheme.accentRed
                    : kSearchFilterTextColor,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            selected: filter.statuses.isEmpty,
            onSelected: (_) => notifier.clearContractStatuses(),
            selectedColor: const Color(0xFFFFF1F2),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: filter.statuses.isEmpty
                  ? AppTheme.accentRed
                  : const Color(0xFFE5E7EB),
              width: filter.statuses.isEmpty ? 1.4 : 1,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          ),
          for (final s in StoreStatus.values)
            FilterChip(
              showCheckmark: false,
              label: Text(
                _storeStatusLabel(s),
                style: TextStyle(
                  fontSize: kSearchFilterFontSize,
                  fontWeight: filter.statuses.contains(s)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: filter.statuses.contains(s)
                      ? AppTheme.accentRed
                      : kSearchFilterTextColor,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              selected: filter.statuses.contains(s),
              onSelected: (_) => notifier.toggleContractStatus(s),
              selectedColor: const Color(0xFFFFF1F2),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: filter.statuses.contains(s)
                    ? AppTheme.accentRed
                    : const Color(0xFFE5E7EB),
                width: filter.statuses.contains(s) ? 1.4 : 1,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
        ],
      ),
    );
  }
}

class _StoreTable extends StatelessWidget {
  const _StoreTable({required this.rows});

  final List<Store> rows;

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: 1300,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FlexColumnWidth(0.4),
          4: FlexColumnWidth(0.8),
          7: FlexColumnWidth(1.8),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('No'),
              ErpTableHeaderCell('브랜드'),
              ErpTableHeaderCell('가맹점명'),
              ErpTableHeaderCell('가맹점코드'),
              ErpTableHeaderCell('계약상태'),
              ErpTableHeaderCell('가맹점 소유자'),
              ErpTableHeaderCell('연락처'),
              ErpTableHeaderCell('주소'),
              ErpTableHeaderCell('개업일자'),
              ErpTableHeaderCell('계약 만료일자'),
              ErpTableHeaderCell('상세보기'),
            ],
          ),
          ...rows.asMap().entries.map(
            (entry) => TableRow(
              decoration: BoxDecoration(
                color: entry.key.isEven
                    ? AppTheme.tableRowOdd
                    : AppTheme.tableRowEven,
              ),
              children: [
                ErpTableBodyCell('${entry.value.no}', center: true),
                ErpTableBodyCell(entry.value.brand, center: true),
                ErpTableBodyCell(entry.value.storeName, center: true),
                ErpTableBodyCell(entry.value.storeCode, center: true),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _StatusChip(status: entry.value.contractStatus),
                  ),
                ),
                ErpTableBodyCell(entry.value.ownerName, center: true),
                ErpTableBodyCell(entry.value.contact, center: true),
                ErpTableBodyCell(entry.value.address),
                ErpTableBodyCell(entry.value.contractDate, center: true),
                ErpTableBodyCell(entry.value.openingDate, center: true),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.storeDetail,
                        pathParameters: {'storeCode': entry.value.storeCode},
                      ),
                    ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StoreStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case StoreStatus.newContract:
        label = '신규계약';
        color = AppTheme.statusOperating;
      case StoreStatus.renewal:
        label = '재계약';
        color = AppTheme.statusPreparing;
      case StoreStatus.transfer:
        label = '양수도';
        color = AppTheme.statusTerminated;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }
}
