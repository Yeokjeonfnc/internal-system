// 물건 목록 화면(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
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
import 'package:app_flutter/features/properties/property_controller.dart';
import 'package:app_flutter/features/properties/property_model.dart';

/// 물건 목록에서 켤 수 있는 공통 검색 항목.
const Set<CommonSearchFieldId> kPropertyListSupportedSearchFields = {
  CommonSearchFieldId.propertyName,
  CommonSearchFieldId.propertyStatus,
  CommonSearchFieldId.propertyOwnership,
  CommonSearchFieldId.regionCd,
  CommonSearchFieldId.propertyAddress,
};

/// 물건 목록.
class PropertyListView extends ConsumerStatefulWidget {
  const PropertyListView({super.key});

  @override
  ConsumerState<PropertyListView> createState() => _PropertyListViewState();
}

class _PropertyListViewState extends ConsumerState<PropertyListView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addrCtrl;

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  @override
  void initState() {
    super.initState();
    final s = ref.read(propertyProvider);
    _nameCtrl = TextEditingController(text: s.name);
    _addrCtrl = TextEditingController(text: s.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearPropertyFilterField(CommonSearchFieldId id, PropertyNotifier n) {
    switch (id) {
      case CommonSearchFieldId.propertyName:
        _nameCtrl.clear();
        n.setName('');
        return;
      case CommonSearchFieldId.propertyAddress:
        _addrCtrl.clear();
        n.setAddress('');
        return;
      case CommonSearchFieldId.propertyOwnership:
        n.setOwnership(null);
        return;
      case CommonSearchFieldId.propertyStatus:
        n.setStatus(null);
        return;
      case CommonSearchFieldId.regionCd:
        n.setRegion('전체');
        return;
      case CommonSearchFieldId.storeNm:
      case CommonSearchFieldId.storeCd:
      case CommonSearchFieldId.brandCd:
      case CommonSearchFieldId.storeStatus:
      case CommonSearchFieldId.supervisorCd:
      case CommonSearchFieldId.storeType:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
      case CommonSearchFieldId.mobilePhone:
      case CommonSearchFieldId.registrationDate:
      case CommonSearchFieldId.partnerName:
      case CommonSearchFieldId.founderEvaluation:
      case CommonSearchFieldId.partnerStatus:
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
    PropertyNotifier n,
  ) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearPropertyFilterField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    PropertyFilter filter,
    List<CodeOption> regionOptions,
    PropertyNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.propertyName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '물건명을 입력하세요.',
              controller: _nameCtrl,
              onChanged: n.setName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.propertyOwnership:
          items.add(
            FilterDropdownSlot<PropertyOwnership>(
              label: def.label,
              value: filter.ownership,
              items: const [
                DropdownMenuItem<PropertyOwnership?>(
                  value: null,
                  child: Text('전체'),
                ),
                DropdownMenuItem<PropertyOwnership?>(
                  value: PropertyOwnership.owned,
                  child: Text('자가'),
                ),
                DropdownMenuItem<PropertyOwnership?>(
                  value: PropertyOwnership.leased,
                  child: Text('임대차'),
                ),
              ],
              onChanged: n.setOwnership,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.propertyStatus:
          items.add(
            FilterDropdownSlot<PropertyStatus>(
              label: def.label,
              value: filter.status,
              items: const [
                DropdownMenuItem<PropertyStatus?>(
                  value: null,
                  child: Text('전체'),
                ),
                DropdownMenuItem<PropertyStatus?>(
                  value: PropertyStatus.contracted,
                  child: Text('체결물건'),
                ),
                DropdownMenuItem<PropertyStatus?>(
                  value: PropertyStatus.pending,
                  child: Text('보류물건'),
                ),
                DropdownMenuItem<PropertyStatus?>(
                  value: PropertyStatus.unsuitable,
                  child: Text('부적합물건'),
                ),
              ],
              onChanged: n.setStatus,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.regionCd:
          items.add(
            FilterDropdownSlot<String>(
              label: def.label,
              value: filter.region,
              items: [
                const DropdownMenuItem<String>(value: '전체', child: Text('전체')),
                for (final option in regionOptions)
                  DropdownMenuItem<String>(
                    value: option.codeCd,
                    child: Text(option.codeNm),
                  ),
              ],
              onChanged: (v) => n.setRegion(v ?? '전체'),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.propertyAddress:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '주소를 입력하세요.',
              controller: _addrCtrl,
              onChanged: n.setAddress,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeNm:
        case CommonSearchFieldId.storeCd:
        case CommonSearchFieldId.brandCd:
        case CommonSearchFieldId.storeStatus:
        case CommonSearchFieldId.supervisorCd:
        case CommonSearchFieldId.storeType:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
        case CommonSearchFieldId.mobilePhone:
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.partnerName:
        case CommonSearchFieldId.founderEvaluation:
        case CommonSearchFieldId.partnerStatus:
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

  Widget _filterPickerSheet(VoidCallback refreshSheet, PropertyNotifier n) {
    return CommonSearchFieldPicker(
      supported: kPropertyListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible, n);
        refreshSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertyDataProvider);
    final filter = ref.watch(propertyProvider);
    final n = ref.read(propertyProvider.notifier);
    final rows = n.getFilteredList();
    final regionOptions =
        ref.watch(propertyCodeOptionsProvider(20)).value ??
        const <CodeOption>[];

    final filterSheet = StatefulBuilder(
      builder: (context, setModalState) {
        void refreshSheet() => setModalState(() {});
        return _filterPickerSheet(refreshSheet, n);
      },
    );

    final mainFields = _anyMainFilter
        ? SearchFilterStackedItems(
            items: _mainFilterItems(filter, regionOptions, n),
          )
        : null;

    return ListPageTemplate(
      activeFilters: _activeFilterChips(filter, n),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: propertiesAsync.isLoading
          ? '조회 중입니다.'
          : '총 ${rows.length}건이 조회되었습니다.',
      onRegister: () => context.goNamed(AppRouteNames.propertyRegister),
      onRefresh: () {
        n.refresh();
        setState(() {});
      },
      table: _PropertyTable(rows: rows),
    );
  }

  List<ActiveFilterChip> _activeFilterChips(
    PropertyFilter f,
    PropertyNotifier n,
  ) {
    final chips = <ActiveFilterChip>[];
    if (f.name.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '물건명: ${f.name}',
          onClear: () {
            setState(() {
              _nameCtrl.clear();
              n.setName('');
            });
          },
        ),
      );
    }
    if (f.address.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '주소: ${f.address}',
          onClear: () {
            setState(() {
              _addrCtrl.clear();
              n.setAddress('');
            });
          },
        ),
      );
    }
    if (f.ownership != null) {
      chips.add(
        ActiveFilterChip(
          label: '종류: ${_ownershipLabel(f.ownership!)}',
          onClear: () => n.setOwnership(null),
        ),
      );
    }
    if (f.status != null) {
      chips.add(
        ActiveFilterChip(
          label: '구분: ${_statusLabel(f.status!)}',
          onClear: () => n.setStatus(null),
        ),
      );
    }
    if (f.region != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '지역: ${_regionLabel(f.region)}',
          onClear: () => n.setRegion('전체'),
        ),
      );
    }
    return chips;
  }

  String _regionLabel(String code) {
    final options = ref.read(propertyCodeOptionsProvider(20)).value;
    if (options == null) return code;
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }
}

class _PropertyTable extends ConsumerWidget {
  const _PropertyTable({required this.rows});

  final List<Property> rows;

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Property property,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('물건 삭제'),
        content: Text('${property.name} 데이터를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(propertyApiServiceProvider)
        .deleteProperty(property.propIdx);
    if (!context.mounted) return;

    if (deleted) {
      await ref.refresh(propertyDataProvider.future).then<void>((_) {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErpDataTable(
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(110),
          1: FlexColumnWidth(1.5),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(110),
          4: FixedColumnWidth(100),
          5: FlexColumnWidth(1),
          6: FlexColumnWidth(1),
          7: FlexColumnWidth(1),
          // 8: FixedColumnWidth(90),
          9: FlexColumnWidth(1),
          10: FixedColumnWidth(120),
          11: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.accentRed),
            children: const [
              ErpTableHeaderCell('조사일자'),
              ErpTableHeaderCell('물건명'),
              ErpTableHeaderCell('지역'),
              ErpTableHeaderCell('구분'),
              ErpTableHeaderCell('면적(계약㎡)'),
              ErpTableHeaderCell('권리금'),
              ErpTableHeaderCell('보증금'),
              ErpTableHeaderCell('임차료'),
              // ErpTableHeaderCell('가맹여부'),
              ErpTableHeaderCell('주소'),
              ErpTableHeaderCell('상세보기'),
              ErpTableHeaderCell('삭제'),
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
                ErpTableBodyCell(entry.value.surveyDate, center: true),
                ErpTableBodyCell(entry.value.name, center: true),
                ErpTableBodyCell(entry.value.region, center: true),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _PropertyStatusChip(status: entry.value.status),
                  ),
                ),
                ErpTableBodyCell(
                  _formatArea(entry.value.areaSqm),
                  center: true,
                ),
                ErpTableBodyCell(
                  _formatMoney(entry.value.keyMoney),
                  alignRight: true,
                ),
                ErpTableBodyCell(
                  _formatMoney(entry.value.deposit),
                  alignRight: true,
                ),
                ErpTableBodyCell(
                  _formatMoney(entry.value.rent),
                  alignRight: true,
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8),
                //   child: Center(
                //     child: _FranchiseFlagChip(flag: entry.value.franchiseFlag),
                //   ),
                // ),
                ErpTableBodyCell(entry.value.address),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.propertyDetail,
                        pathParameters: {
                          'propertyNo': '${entry.value.propIdx}',
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _PropertyDeleteButton(
                      onPressed: () =>
                          _confirmAndDelete(context, ref, entry.value),
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

class _PropertyDeleteButton extends StatelessWidget {
  const _PropertyDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text('삭제'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        foregroundColor: AppTheme.accentRed,
        side: const BorderSide(color: AppTheme.accentRed),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PropertyStatusChip extends StatelessWidget {
  const _PropertyStatusChip({required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      PropertyStatus.contracted => (
        foreground: const Color(0xFF065F46),
        background: const Color(0xFFD1FAE5),
        border: const Color(0xFF6EE7B7),
      ),
      PropertyStatus.pending => (
        foreground: const Color(0xFF6D28D9),
        background: const Color(0xFFEDE9FE),
        border: const Color(0xFFC4B5FD),
      ),
      PropertyStatus.unsuitable => (
        foreground: const Color(0xFF991B1B),
        background: const Color(0xFFFEE2E2),
        border: const Color(0xFFFCA5A5),
      ),
    };
    return _PropertyPill(
      text: _statusLabel(status),
      foreground: colors.foreground,
      background: colors.background,
      border: colors.border,
    );
  }
}

class _PropertyPill extends StatelessWidget {
  const _PropertyPill({
    required this.text,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String text;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}

String _ownershipLabel(PropertyOwnership v) {
  switch (v) {
    case PropertyOwnership.owned:
      return '자가';
    case PropertyOwnership.leased:
      return '임대차';
  }
}

String _statusLabel(PropertyStatus v) {
  switch (v) {
    case PropertyStatus.contracted:
      return '체결물건';
    case PropertyStatus.pending:
      return '보류물건';
    case PropertyStatus.unsuitable:
      return '부적합물건';
  }
}

String _formatArea(double area) {
  if (area == 0) return '0';
  if (area == area.truncateToDouble()) {
    return '${area.toStringAsFixed(0)}㎡';
  }
  return '${area.toStringAsFixed(2)}㎡';
}

String _formatMoney(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final tail = text.length - i;
    buffer.write(text[i]);
    if (tail > 1 && tail % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
