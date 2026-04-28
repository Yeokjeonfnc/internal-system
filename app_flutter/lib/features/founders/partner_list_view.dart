// 예비창업자 목록 화면(필터·테이블).

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
import 'package:app_flutter/features/founders/partner_controller.dart';
import 'package:app_flutter/features/founders/partner_model.dart';

const List<String> _partnerStatusOptions = ['전체', '예비창업자', '가맹점사업자'];

/// 예비창업자 목록에서 켤 수 있는 공통 검색 항목.
const Set<CommonSearchFieldId> kPartnerListSupportedSearchFields = {
  CommonSearchFieldId.partnerName,
  CommonSearchFieldId.partnerStatus,
  CommonSearchFieldId.mobilePhone,
  CommonSearchFieldId.regionCd,
};

/// 예비창업자 목록.
class PartnerListView extends ConsumerStatefulWidget {
  const PartnerListView({super.key});

  @override
  ConsumerState<PartnerListView> createState() => _PartnerListViewState();
}

class _PartnerListViewState extends ConsumerState<PartnerListView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  @override
  void initState() {
    super.initState();
    final s = ref.read(partnerProvider);
    _nameCtrl = TextEditingController(text: s.partnerNm);
    _phoneCtrl = TextEditingController(text: s.partnerTel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearPartnerFilterField(CommonSearchFieldId id, PartnerNotifier n) {
    switch (id) {
      case CommonSearchFieldId.partnerName:
        _nameCtrl.clear();
        n.setName('');
        return;
      case CommonSearchFieldId.mobilePhone:
        _phoneCtrl.clear();
        n.setPhone('');
        return;
      case CommonSearchFieldId.regionCd:
        n.setRegion('전체');
        return;
      case CommonSearchFieldId.founderEvaluation:
        n.setEvaluation(null);
        return;
      case CommonSearchFieldId.partnerStatus:
        n.setPartnerStatus('전체');
        return;
      case CommonSearchFieldId.storeNm:
      case CommonSearchFieldId.storeCd:
      case CommonSearchFieldId.brandCd:
      case CommonSearchFieldId.storeStatus:
      case CommonSearchFieldId.supervisorCd:
      case CommonSearchFieldId.storeType:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
      case CommonSearchFieldId.registrationDate:
      case CommonSearchFieldId.propertyName:
      case CommonSearchFieldId.propertyOwnership:
      case CommonSearchFieldId.propertyStatus:
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
    PartnerNotifier n,
  ) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearPartnerFilterField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    PartnerFilter filter,
    List<CodeOption> regionOptions,
    PartnerNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.partnerName:
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
        case CommonSearchFieldId.regionCd:
          items.add(
            FilterDropdownSlot<String>(
              label: def.label,
              value: filter.pRegion,
              items: [
                const DropdownMenuItem<String?>(value: '전체', child: Text('전체')),
                for (final region in regionOptions)
                  DropdownMenuItem<String?>(
                    value: region.codeCd,
                    child: Text(region.codeNm),
                  ),
              ],
              onChanged: (v) => n.setRegion(v ?? '전체'),
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.partnerStatus:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.partnerStatus,
              options: _partnerStatusOptions,
              onSelected: n.setPartnerStatus,
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
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyStatus:
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

  Widget _filterPickerSheet(VoidCallback refreshSheet, PartnerNotifier n) {
    return CommonSearchFieldPicker(
      supported: kPartnerListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, nowVisible) {
        _onMainSearchFieldToggle(id, nowVisible, n);
        refreshSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnerDataProvider);
    final filter = ref.watch(partnerProvider);
    final n = ref.read(partnerProvider.notifier);
    final rows = n.getFilteredList();
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];

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
      activeFilters: _activeFilterChips(filter, n, regionOptions),
      filterSheetBody: filterSheet,
      mainSearchFields: mainFields,
      countText: partnersAsync.isLoading
          ? '조회 중입니다.'
          : '총 ${rows.length}명이 조회되었습니다.',
      onRegister: () => context.goNamed(AppRouteNames.founderRegister),
      onRefresh: () {
        n.refresh();
        setState(() {});
      },
      table: _PartnerTable(rows: rows),
    );
  }

  List<ActiveFilterChip> _activeFilterChips(
    PartnerFilter f,
    PartnerNotifier n,
    List<CodeOption> regionOptions,
  ) {
    final chips = <ActiveFilterChip>[];
    if (f.partnerNm.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '이름: ${f.partnerNm}',
          onClear: () {
            setState(() {
              _nameCtrl.clear();
              n.setName('');
            });
          },
        ),
      );
    }
    if (f.partnerTel.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '휴대전화: ${f.partnerTel}',
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
          label: '평가상태: ${_partnerEvaluationLabel(f.evaluation!)}',
          onClear: () => n.setEvaluation(null),
        ),
      );
    }
    if (f.pRegion != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '지역: ${_regionLabel(f.pRegion, regionOptions)}',
          onClear: () => n.setRegion('전체'),
        ),
      );
    }
    if (f.partnerStatus != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '상태: ${f.partnerStatus}',
          onClear: () => n.setPartnerStatus('전체'),
        ),
      );
    }
    return chips;
  }

  String _regionLabel(String code, List<CodeOption> options) {
    if (code.isEmpty || code == '전체') return '전체';
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }
}

String _partnerEvaluationLabel(EvaluationStatus s) => switch (s) {
  EvaluationStatus.pending => '평가전',
  EvaluationStatus.completed => '평가완료',
};

class _PartnerTable extends ConsumerWidget {
  const _PartnerTable({required this.rows});

  final List<Partner> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];
    return ErpDataTable(
      minWidth: 1080,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FixedColumnWidth(130),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(150),
          4: FlexColumnWidth(1),
          5: FixedColumnWidth(300),
          6: FlexColumnWidth(0.5),
          7: FixedColumnWidth(100),
          8: FixedColumnWidth(150),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('No'), // 0
              ErpTableHeaderCell('등록일자'), // 1
              ErpTableHeaderCell('이름'), // 2
              ErpTableHeaderCell('상태'), // 3
              ErpTableHeaderCell('휴대전화'), // 4
              ErpTableHeaderCell('이메일'), // 5
              ErpTableHeaderCell('지역'), // 6
              ErpTableHeaderCell('성별'), // 7
              ErpTableHeaderCell('상세보기'), //8
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
                ErpTableBodyCell('${entry.value.partnerIdx}', center: true),
                ErpTableBodyCell(entry.value.createDt, center: true),
                ErpTableBodyCell(entry.value.partnerNm, center: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      partnerStatusLabelKorean(entry.value.partnerStatus),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _partnerStatusColor(entry.value.partnerStatus),
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
                ErpTableBodyCell(entry.value.partnerTel, center: true),
                ErpTableBodyCell(entry.value.partnerEmail, center: true),
                ErpTableBodyCell(
                  _regionLabel(entry.value.pRegion, regionOptions),
                  center: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      entry.value.gender == Gender.male ? '남성' : '여성',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _genderColor(entry.value.gender),
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: DetailButton(
                      onPressed: () => context.goNamed(
                        AppRouteNames.founderDetail,
                        pathParameters: {
                          'partnerIdx': '${entry.value.partnerIdx}',
                        },
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

  String _regionLabel(String code, List<CodeOption> options) {
    if (code.isEmpty) return '-';
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }

  Color _genderColor(Gender gender) {
    return gender == Gender.female
        ? const Color(0xFFE91E63)
        : const Color(0xFF1E3A8A);
  }

  Color _partnerStatusColor(PartnerStatus status) {
    return status == PartnerStatus.prospect
        ? const Color(0xFFC2185B)
        : const Color(0xFF7B1FA2);
  }
}
