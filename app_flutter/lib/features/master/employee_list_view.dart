// 마스터 — 사원관리 목록(필터·테이블).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_field_picker.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/features/master/employee_controller.dart';
import 'package:app_flutter/features/master/employee_model.dart';

/// 사원관리에서 켤 수 있는 검색 항목.
const Set<CommonSearchFieldId> kEmployeeListSupportedSearchFields = {
  CommonSearchFieldId.employeeName,
  CommonSearchFieldId.employeeDepartment,
  CommonSearchFieldId.employeePosition,
  CommonSearchFieldId.employeeEmail,
  CommonSearchFieldId.employeePhone,
};

/// 사원관리 목록.
class EmployeeListView extends ConsumerStatefulWidget {
  const EmployeeListView({super.key});

  @override
  ConsumerState<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends ConsumerState<EmployeeListView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  final Set<CommonSearchFieldId> _visibleMainSearchFields = {};

  List<Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(employeeProvider);
    _nameCtrl = TextEditingController(text: s.name);
    _emailCtrl = TextEditingController(text: s.email);
    _phoneCtrl = TextEditingController(text: s.phone);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await ref.read(employeeRepositoryProvider).all();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('사원 목록 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _anyMainFilter => _visibleMainSearchFields.isNotEmpty;

  void _clearField(CommonSearchFieldId id, EmployeeNotifier n) {
    switch (id) {
      case CommonSearchFieldId.employeeName:
        _nameCtrl.clear();
        n.setName('');
        return;
      case CommonSearchFieldId.employeeDepartment:
        n.setDepartment('전체');
        return;
      case CommonSearchFieldId.employeePosition:
        n.setPosition('전체');
        return;
      case CommonSearchFieldId.employeeEmail:
        _emailCtrl.clear();
        n.setEmail('');
        return;
      case CommonSearchFieldId.employeePhone:
        _phoneCtrl.clear();
        n.setPhone('');
        return;
      case CommonSearchFieldId.storeNm:
      case CommonSearchFieldId.storeCd:
      case CommonSearchFieldId.brandCd:
      case CommonSearchFieldId.storeStatus:
      case CommonSearchFieldId.supervisorCd:
      case CommonSearchFieldId.storeType:
      case CommonSearchFieldId.prospectName:
      case CommonSearchFieldId.entrepreneurStatus:
      case CommonSearchFieldId.regionCd:
      case CommonSearchFieldId.mobilePhone:
      case CommonSearchFieldId.registrationDate:
      case CommonSearchFieldId.propertyName:
      case CommonSearchFieldId.propertyOwnership:
      case CommonSearchFieldId.propertyStatus:
      case CommonSearchFieldId.propertyAddress:
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
        return;
    }
  }

  void _onToggle(CommonSearchFieldId id, bool nowVisible, EmployeeNotifier n) {
    setState(() {
      if (nowVisible) {
        _visibleMainSearchFields.add(id);
      } else {
        _visibleMainSearchFields.remove(id);
        _clearField(id, n);
      }
    });
  }

  List<SearchFilterItemData> _mainFilterItems(
    EmployeeFilter filter,
    List<String> departments,
    List<String> positions,
    EmployeeNotifier n,
  ) {
    final items = <SearchFilterItemData>[];
    for (final def in commonSearchDefsOrdered(_visibleMainSearchFields)) {
      switch (def.id) {
        case CommonSearchFieldId.employeeName:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '사원명을 입력하세요.',
              controller: _nameCtrl,
              onChanged: n.setName,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.employeeDepartment:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.department,
              options: departments,
              onSelected: n.setDepartment,
              forceDropdown: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.employeePosition:
          items.add(
            FilterStringOptionsSlot(
              label: def.label,
              value: filter.position,
              options: positions,
              onSelected: n.setPosition,
              forceDropdown: true,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.employeeEmail:
          items.add(
            FilterTextSlot(
              label: def.label,
              hint: '이메일을 입력하세요.',
              controller: _emailCtrl,
              onChanged: n.setEmail,
            ).toItem(),
          );
          break;
        case CommonSearchFieldId.employeePhone:
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
        case CommonSearchFieldId.storeNm:
        case CommonSearchFieldId.storeCd:
        case CommonSearchFieldId.brandCd:
        case CommonSearchFieldId.storeStatus:
        case CommonSearchFieldId.supervisorCd:
        case CommonSearchFieldId.storeType:
        case CommonSearchFieldId.prospectName:
        case CommonSearchFieldId.entrepreneurStatus:
        case CommonSearchFieldId.regionCd:
        case CommonSearchFieldId.mobilePhone:
        case CommonSearchFieldId.registrationDate:
        case CommonSearchFieldId.propertyName:
        case CommonSearchFieldId.propertyOwnership:
        case CommonSearchFieldId.propertyStatus:
        case CommonSearchFieldId.propertyAddress:
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
          break;
      }
    }
    return items;
  }

  Widget _filterSheet(void Function() refresh, EmployeeNotifier n) {
    return CommonSearchFieldPicker(
      supported: kEmployeeListSupportedSearchFields,
      visible: _visibleMainSearchFields,
      onToggle: (id, v) {
        _onToggle(id, v, n);
        refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filter = ref.watch(employeeProvider);
    final n = ref.read(employeeProvider.notifier);
    final rows = _filterEmployees(_employees, filter);
    final repository = ref.watch(employeeRepositoryProvider);
    final departments = repository.departmentOptions();
    final positions = repository.positionOptions();

    final filterSheet = StatefulBuilder(
      builder: (context, setModal) {
        void refresh() => setModal(() {});
        return _filterSheet(refresh, n);
      },
    );

    final mainBlock = _anyMainFilter
        ? SearchFilterStackedItems(
            items: _mainFilterItems(filter, departments, positions, n),
          )
        : null;

    return ListPageTemplate(
      activeFilters: _chips(filter, n),
      filterSheetBody: filterSheet,
      mainSearchFields: mainBlock,
      countText: '총 ${rows.length}명이 조회되었습니다.',
      onRefresh: _loadEmployees,
      table: _EmployeeTable(rows: rows),
      onRegister: () => context.push('/master/employees/new'),
    );
  }

  List<Employee> _filterEmployees(
    List<Employee> employees,
    EmployeeFilter filter,
  ) {
    return employees.where((emp) {
      // 이름 필터
      if (filter.name.trim().isNotEmpty &&
          !emp.name.contains(filter.name.trim())) {
        return false;
      }
      // 부서 필터
      if (filter.department != '전체' && emp.department != filter.department) {
        return false;
      }
      // 직급 필터
      if (filter.position != '전체' && emp.jobTitle != filter.position) {
        return false;
      }
      // 이메일 필터
      if (filter.email.trim().isNotEmpty &&
          !emp.email.contains(filter.email.trim())) {
        return false;
      }
      // 휴대전화 필터
      if (filter.phone.trim().isNotEmpty &&
          !emp.mobilePhone.contains(filter.phone.trim())) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ActiveFilterChip> _chips(EmployeeFilter f, EmployeeNotifier n) {
    final chips = <ActiveFilterChip>[];
    if (f.name.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '사원명: ${f.name}',
          onClear: () {
            setState(() {
              _nameCtrl.clear();
              n.setName('');
            });
          },
        ),
      );
    }
    if (f.department != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '부서: ${f.department}',
          onClear: () => n.setDepartment('전체'),
        ),
      );
    }
    if (f.position != '전체') {
      chips.add(
        ActiveFilterChip(
          label: '직급: ${f.position}',
          onClear: () => n.setPosition('전체'),
        ),
      );
    }
    if (f.email.trim().isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '이메일: ${f.email}',
          onClear: () {
            setState(() {
              _emailCtrl.clear();
              n.setEmail('');
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
    return chips;
  }
}

class _EmployeeTable extends StatelessWidget {
  const _EmployeeTable({required this.rows});

  final List<Employee> rows;

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthDefault,
      tableBuilder: (context, _) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FixedColumnWidth(200), // 이름
          1: FlexColumnWidth(1), // 부서
          2: FixedColumnWidth(150), // 직급
          3: FixedColumnWidth(230), // 휴대전화
          4: FlexColumnWidth(1.4), // 이메일 주소
          // 5: FixedColumnWidth(120),
          6: FixedColumnWidth(100), // 태그사용여부
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('이름'),
              ErpTableHeaderCell('부서'),
              ErpTableHeaderCell('직급'),
              ErpTableHeaderCell('휴대전화'),
              ErpTableHeaderCell('이메일 주소'),
              // ErpTableHeaderCell('입사년월일'),
              ErpTableHeaderCell('태그사용여부'),
            ],
          ),
          ...rows.asMap().entries.map(
            (e) => TableRow(
              decoration: BoxDecoration(
                color: e.key.isEven
                    ? AppTheme.tableRowOdd
                    : AppTheme.tableRowEven,
              ),
              children: [
                ErpTableBodyCell(e.value.name, center: true),
                ErpTableBodyCell(e.value.department, center: true),
                ErpTableBodyCell(e.value.jobTitle, center: true),
                ErpTableBodyCell(e.value.mobilePhone, center: true),
                ErpTableBodyCell(e.value.email, center: true),
                // ErpTableBodyCell(e.value.hireDateYmd, center: true),
                ErpTableBodyCell(
                  e.value.tagEnabled ? '사용' : '미사용',
                  center: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
