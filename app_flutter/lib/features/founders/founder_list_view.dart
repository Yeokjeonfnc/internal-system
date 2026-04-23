// 예비창업자 목록 화면(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/data/mock_options.dart';
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
import 'package:app_flutter/features/founders/founder_controller.dart';
import 'package:app_flutter/features/founders/founder_model.dart';

/// 예비창업자 목록에서 켤 수 있는 공통 검색 항목.
const Set<CommonSearchFieldId> kFounderListSupportedSearchFields = {
  CommonSearchFieldId.founderName,
  CommonSearchFieldId.mobilePhone,
  CommonSearchFieldId.founderEvaluation,
  CommonSearchFieldId.founderStatus,
  CommonSearchFieldId.region,
};

/// 예비창업자 목록.
class FounderListView extends ConsumerStatefulWidget {
  const FounderListView({super.key});

  @override
  ConsumerState<FounderListView> createState() => _FounderListViewState();
}

class _FounderListViewState extends ConsumerState<FounderListView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  @override
  void initState() {
    super.initState();
    final s = ref.read(founderProvider);
    _nameCtrl = TextEditingController(text: s.name);
    _phoneCtrl = TextEditingController(text: s.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearFounderFilterField(CommonSearchFieldId id, FounderNotifier n) {
    switch (id) {
      case CommonSearchFieldId.founderName:
        _nameCtrl.clear();
        n.setName('');
        return;
      case CommonSearchFieldId.mobilePhone:
        _phoneCtrl.clear();
        n.setPhone('');
        return;
      case CommonSearchFieldId.founderEvaluation:
        n.setEvaluation(null);
        return;
      case CommonSearchFieldId.region:
        n.setRegion('전체');
        return;
      case CommonSearchFieldId.founderStatus:
        n.setFounderStatus('전체');
        return;
      case CommonSearchFieldId.storeName:
      case CommonSearchFieldId.storeCode:
      case CommonSearchFieldId.brand:
      case CommonSearchFieldId.contractStatus:
      case CommonSearchFieldId.supervisor:
      case CommonSearchFieldId.storeCategory:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
      case CommonSearchFieldId.registrationDate:
      case CommonSearchFieldId.propertyName:
      case CommonSearchFieldId.propertyOwnership:
      case CommonSearchFieldId.propertyAddress:
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
    FounderNotifier n,
  ) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearFounderFilterField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    FounderFilter filter,
    List<String> regions,
    FounderNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.founderName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '이름을 입력하세요.',
              controller: _nameCtrl,
              onChanged: n.setName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.mobilePhone:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '휴대전화 번호를 입력하세요.',
              controller: _phoneCtrl,
              onChanged: n.setPhone,
              isPhoneNumber: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.founderEvaluation:
          items.add(
            FilterDropdownSlot<EvaluationStatus>(
              label: def.label,
              value: filter.evaluation,
              items: const [
                DropdownMenuItem<EvaluationStatus?>(
                  value: null,
                  child: Text('전체'),
                ),
                DropdownMenuItem<EvaluationStatus?>(
                  value: EvaluationStatus.pending,
                  child: Text('평가전'),
                ),
                DropdownMenuItem<EvaluationStatus?>(
                  value: EvaluationStatus.completed,
                  child: Text('평가완료'),
                ),
              ],
              onChanged: n.setEvaluation,
            ).toItem(),
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
        case CommonSearchFieldId.founderStatus:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.founderStatus,
              options: kMockFounderStatusOptions,
              onSelected: n.setFounderStatus,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.storeName:
        case CommonSearchFieldId.storeCode:
        case CommonSearchFieldId.brand:
        case CommonSearchFieldId.contractStatus:
        case CommonSearchFieldId.supervisor:
        case CommonSearchFieldId.storeCategory:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyAddress:
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

  Widget _filterPickerSheet(VoidCallback refreshSheet, FounderNotifier n) {
    return CommonSearchFieldPicker(
      supported: kFounderListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible, n);
        refreshSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(founderProvider);
    final n = ref.read(founderProvider.notifier);
    final rows = n.getFilteredList();
    final regions = ref.watch(founderRepositoryProvider).regions();

    final filterSheet = StatefulBuilder(
      builder: (context, setModalState) {
        void refreshSheet() => setModalState(() {});
        return _filterPickerSheet(refreshSheet, n);
      },
    );

    final mainFields = _anyMainFilter
        ? SearchFilterStackedItems(items: _mainFilterItems(filter, regions, n))
        : null;

    return ListPageTemplate(
      activeFilters: _activeFilterChips(filter, n),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: '총 ${rows.length}명이 조회되었습니다.',
      onRegister: () => context.goNamed(AppRouteNames.founderRegister),
      table: _FounderTable(rows: rows),
    );
  }

  List<ActiveFilterChip> _activeFilterChips(
    FounderFilter f,
    FounderNotifier n,
  ) {
    final chips = <ActiveFilterChip>[];
    if (f.name.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '이름: ${f.name}',
          onClear: () {
            setState(() {
              _nameCtrl.clear();
              n.setName('');
            });
          },
        ),
      );
    }
    if (f.phone.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '휴대전화: ${f.phone}',
          onClear: () {
            setState(() {
              _phoneCtrl.clear();
              n.setPhone('');
            });
          },
        ),
      );
    }
    if (f.evaluation != null) {
      chips.add(
        ActiveFilterChip(
          label: '평가상태: ${_founderEvaluationLabel(f.evaluation!)}',
          onClear: () => n.setEvaluation(null),
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
    if (f.founderStatus != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '상태: ${f.founderStatus}',
          onClear: () => n.setFounderStatus('전체'),
        ),
      );
    }
    return chips;
  }
}

String _founderEvaluationLabel(EvaluationStatus s) => switch (s) {
  EvaluationStatus.pending => '평가전',
  EvaluationStatus.completed => '평가완료',
};

class _FounderTable extends StatelessWidget {
  const _FounderTable({required this.rows});

  final List<Founder> rows;

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: 1080,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FixedColumnWidth(130),
          2: FlexColumnWidth(1.1),
          3: FixedColumnWidth(110),
          4: FlexColumnWidth(1.3),
          5: FlexColumnWidth(1.1),
          6: FixedColumnWidth(100),
          7: FlexColumnWidth(0.9),
          8: FixedColumnWidth(120),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('No'),
              ErpTableHeaderCell('등록일자'),
              ErpTableHeaderCell('이름'),
              ErpTableHeaderCell('상태'),
              ErpTableHeaderCell('휴대전화'),
              ErpTableHeaderCell('평가상태'),
              ErpTableHeaderCell('평가점수'),
              ErpTableHeaderCell('지역'),
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
                ErpTableBodyCell(entry.value.registrationDate, center: true),
                ErpTableBodyCell(entry.value.name, center: true),
                ErpTableBodyCell(
                  founderStatusLabelKorean(entry.value.founderStatus),
                  center: true,
                ),
                ErpTableBodyCell(entry.value.phone, center: true),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _EvalChip(status: entry.value.evaluationStatus),
                  ),
                ),
                ErpTableBodyCell(
                  entry.value.evaluationScore?.toString() ?? '-',
                  center: true,
                ),
                ErpTableBodyCell(entry.value.region, center: true),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.founderDetail,
                        pathParameters: {'founderNo': '${entry.value.no}'},
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

class _EvalChip extends StatelessWidget {
  const _EvalChip({required this.status});

  final EvaluationStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case EvaluationStatus.pending:
        label = '평가전';
        color = const Color(0xFF9CA3AF);
      case EvaluationStatus.completed:
        label = '평가완료';
        color = AppTheme.statusOperating;
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
