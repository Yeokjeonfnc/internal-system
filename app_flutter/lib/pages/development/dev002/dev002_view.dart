// 물건 목록 화면(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/common_detail_button.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/pages/development/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/development/dev002/dev002_filter.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_multi_select.dart';

/// 물건 목록 본문에 항상 노출하는 검색 항목(통합 텍스트 검색은 상단 필드).
const Set<CommonSearchFieldId> kPropertyListSupportedSearchFields = {
  CommonSearchFieldId.propertyStatus,
  CommonSearchFieldId.propertyOwnership,
  CommonSearchFieldId.regionCd,
};

/// 물건 목록.
class PropertyListView extends ConsumerStatefulWidget {
  const PropertyListView({super.key});

  @override
  ConsumerState<PropertyListView> createState() => _PropertyListViewState();
}

class _PropertyListViewState extends ConsumerState<PropertyListView> {
  late final TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(propertyProvider);
    _keywordCtrl = TextEditingController(text: s.propertyKeyword);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  List<SearchFilterItemData> _mainFilterItems(
    PropertyFilter filter,
    BuildContext context,
    List<String> regions,
    PropertyNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    final regionOpts = regions.where((e) => e != '전체').toList();
    for (final def in commonSearchDefsOrdered(
      kPropertyListSupportedSearchFields,
    )) {
      switch (def.id) {
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyAddress:
          break;
        case CommonSearchFieldId.propertyOwnership:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.ownership,
              options: _ownershipOptions,
              onSelected: n.setOwnership,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.propertyStatus:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.propStatus,
              options: _propStatusOptiohs,
              onSelected: n.setPropStatus,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.regionCd:
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
                    selected: ref.watch(propertyProvider).regionNms,
                    onToggle: ref.read(propertyProvider.notifier).toggleRegion,
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
        case CommonSearchFieldId.salesAreaStrategicOnly:
        case CommonSearchFieldId.salesAreaIncludeNonFranchise:
        case CommonSearchFieldId.salesAreaIncludeUnset:
        case CommonSearchFieldId.salesAreaSettingDateRange:
        case CommonSearchFieldId.userName:
        case CommonSearchFieldId.userDepartment:
        case CommonSearchFieldId.userPosition:
        case CommonSearchFieldId.userEmail:
        case CommonSearchFieldId.userPhone:
          break;
      }
    }
    return items;
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

    final mainFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchFilterTextField(
          controller: _keywordCtrl,
          hint: '물건명, 주소 검색',
          borderRadius: 8,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 22,
          ),
          onChanged: n.setPropertyKeyword,
        ),
        const SizedBox(height: 8),
        SearchFilterStackedItems(
          items: _mainFilterItems(
            filter,
            context,
            regionOptions.map((e) => e.codeNm).toList(),
            n,
          ),
        ),
      ],
    );

    return ListPageTemplate(
      activeFilters: _activeFilterChips(filter, n),
      mainSearchFields: mainFields,
      countText: propertiesAsync.isLoading
          ? '조회 중입니다.'
          : '총 ${rows.length}건이 조회되었습니다.',
      registerMenuCd: kMenuDev002,
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
    if (f.propertyKeyword.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '통합 검색: ${f.propertyKeyword}',
          onClear: () {
            setState(() {
              _keywordCtrl.clear();
              n.setPropertyKeyword('');
            });
          },
        ),
      );
    }
    if (f.ownership != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '종류: ${f.ownership}',
          onClear: () => n.setOwnership('전체'),
        ),
      );
    }
    if (f.propStatus != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '구분: ${f.propStatus}',
          onClear: () => n.setPropStatus('전체'),
        ),
      );
    }
    if (f.regionNms.isNotEmpty) {
      final sorted = f.regionNms.toList()..sort();
      final label = sorted.length <= 3
          ? sorted.join(', ')
          : '${sorted.take(3).join(', ')} 외 ${sorted.length - 3}건';
      chips.add(
        ActiveFilterChip(label: '지역: $label', onClear: () => n.clearRegions()),
      );
    }
    return chips;
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
      await showAlertDialog(context, '삭제되었습니다.');
    } else {
      await showAlertDialog(context, '삭제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDelete = context.menuCanDelete(kMenuDev002);
    final regionOptions =
        ref.watch(propertyCodeOptionsProvider(20)).value ??
        const <CodeOption>[];

    return ErpDataTable(
      minWidth: 2200,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(110),
          1: FlexColumnWidth(1.35),
          2: FixedColumnWidth(92),
          3: FixedColumnWidth(110),
          4: FixedColumnWidth(100),
          5: FlexColumnWidth(0.8),
          6: FlexColumnWidth(0.8),
          7: FlexColumnWidth(0.8),
          8: FlexColumnWidth(1.5), // 주소
          9: FixedColumnWidth(140),
          10: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.accentRed),
            children: [
              const ErpTableHeaderCell('조사일자'),
              const ErpTableHeaderCell('물건명'),
              const ErpTableHeaderCell('지역'),
              const ErpTableHeaderCell('구분'),
              const ErpTableHeaderCell('면적(계약㎡)'),
              const ErpTableHeaderCell('권리금'),
              const ErpTableHeaderCell('보증금'),
              const ErpTableHeaderCell('임차료'),
              const ErpTableHeaderCell('주소'),
              const ErpTableHeaderCell('상세보기'),
              if (showDelete) const ErpTableHeaderCell('삭제'),
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
                ErpTableBodyCell(
                  _propertyRegionLabel(entry.value.region, regionOptions),
                  center: true,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _PropertyStatusChip(status: entry.value.propStatus),
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
                if (showDelete)
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

  final PropStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      PropStatus.contracted => (
        foreground: const Color(0xFF065F46),
        background: const Color(0xFFD1FAE5),
        border: const Color(0xFF6EE7B7),
      ),
      PropStatus.pending => (
        foreground: const Color(0xFF6D28D9),
        background: const Color(0xFFEDE9FE),
        border: const Color(0xFFC4B5FD),
      ),
      PropStatus.unsuitable => (
        foreground: const Color(0xFF991B1B),
        background: const Color(0xFFFEE2E2),
        border: const Color(0xFFFCA5A5),
      ),
    };
    return _PropertyPill(
      text: propStatusLabelKo(status),
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

/// 목록 테이블 지역 열 — [Property.region]이 코드면 공통코드 명칭으로 표시.
String _propertyRegionLabel(String code, List<CodeOption> options) {
  if (code.isEmpty) return '-';
  for (final o in options) {
    if (o.codeCd == code) return o.codeNm;
  }
  return code;
}

const List<String> _ownershipOptions = ['전체', '자가', '임대차'];

const List<String> _propStatusOptiohs = ['전체', '체결물건', '보류물건', '부적합물건'];

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
