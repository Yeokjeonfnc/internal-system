// 결재라인 선택 — 등록·상신 화면용 모달(조직도·사원 그리드·선택 띠, [FormStylePalette] / [ErpDataTable] 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/features/master/department_model.dart';
import 'package:app_flutter/features/master/department_repository.dart';
import 'package:app_flutter/features/master/employee_model.dart';
import 'package:app_flutter/features/master/user_api_service.dart';

/// 격자형 직급/결재 열 수(기안·스크린샷 기준 7).
const int kActivityApprovalLineSlotCount = 7;

class ActivityApprovalLineResult {
  const ActivityApprovalLineResult({required this.titles, required this.names});

  final List<String> titles;
  final List<String> names;
}

/// [결재라인] — 직급+이름 슬롯을 채운다.
Future<ActivityApprovalLineResult?> showActivityApprovalLineDialog(
  BuildContext context, {
  List<String> initialNames = const [],
  List<String> initialTitles = const [],
}) {
  return showDialog<ActivityApprovalLineResult?>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: _ApprovalLineDialog(
          initialNames: _padToSlots(initialNames),
          initialTitles: _padToSlots(initialTitles),
        ),
      );
    },
  );
}

List<String> _padToSlots(List<String> items) {
  return List<String>.generate(
    kActivityApprovalLineSlotCount,
    (i) => i < items.length ? items[i] : '',
  );
}

class _ApprovalLineDialog extends StatefulWidget {
  const _ApprovalLineDialog({
    required this.initialNames,
    required this.initialTitles,
  });

  final List<String> initialNames;
  final List<String> initialTitles;

  @override
  State<_ApprovalLineDialog> createState() => _ApprovalLineDialogState();
}

class _ApprovalLineDialogState extends State<_ApprovalLineDialog> {
  final TextEditingController _searchController = TextEditingController();
  final DepartmentRepository _deptRepo = DepartmentRepository();
  final UserApiService _userApi = UserApiService();

  String? _selectedDeptId;
  final Set<int> _rowChecked = {};
  late List<String> _lineNames;
  late List<String> _lineTitles;

  List<Department> _departments = [];
  List<Employee> _allEmployees = [];
  List<Employee> _displayedEmployees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lineNames = List<String>.from(widget.initialNames);
    _lineTitles = List<String>.from(widget.initialTitles);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final depts = await _deptRepo.all();
      final employees = await _userApi.getUsers();
      setState(() {
        _departments = depts;
        _allEmployees = employees;
        _displayedEmployees = employees;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('결재라인 데이터 로딩 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEmployeesByDept(String deptId) async {
    try {
      final deptIdx = int.tryParse(deptId);
      if (deptIdx == null) {
        setState(() => _displayedEmployees = _allEmployees);
        return;
      }
      final employees = await _userApi.getUsers(deptIdx: deptIdx);
      setState(() => _displayedEmployees = employees);
    } catch (e) {
      debugPrint('부서별 사원 조회 실패: $e');
      setState(() => _displayedEmployees = []);
    }
  }

  List<Employee> get _visibleEmployees {
    var list = _displayedEmployees;
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.name.contains(q) ||
                e.department.contains(q) ||
                e.jobTitle.contains(q),
          )
          .toList();
    }
    return list;
  }

  void _onDeptSelect(String? deptId) {
    setState(() {
      _selectedDeptId = deptId;
      _rowChecked.clear();
    });
    if (deptId == null || deptId == 'root') {
      setState(() => _displayedEmployees = _allEmployees);
    } else {
      _loadEmployeesByDept(deptId);
    }
  }

  void _onAddApprovers() {
    final ids = _rowChecked.toList()..sort();
    final toAdd = <Employee>[];
    for (final id in ids) {
      final emp = _allEmployees.firstWhere(
        (e) => e.no == id,
        orElse: () => _allEmployees.isNotEmpty
            ? _allEmployees.first
            : const Employee(
                no: 0,
                name: '',
                department: '',
                jobTitle: '',
                mobilePhone: '',
                email: '',
                hireDateYmd: '',
                tagEnabled: false,
              ),
      );
      if (emp.no == id) toAdd.add(emp);
    }
    setState(() {
      for (final emp in toAdd) {
        if (_lineNames.contains(emp.name)) continue;
        final i = _lineNames.indexWhere((e) => e.isEmpty);
        if (i >= 0) {
          _lineNames[i] = emp.name;
          _lineTitles[i] = emp.jobTitle;
        }
      }
      _rowChecked.clear();
    });
  }

  void _onReset() {
    setState(() {
      _lineNames = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _lineTitles = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _rowChecked.clear();
    });
  }

  void _onApply() {
    Navigator.of(context).pop(
      ActivityApprovalLineResult(
        names: _padToSlots(_lineNames),
        titles: _padToSlots(_lineTitles),
      ),
    );
  }

  InputDecoration _searchDeco() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: FormStylePalette.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.86;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1000,
        maxHeight: h.clamp(420.0, 760.0),
      ),
      child: Material(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErpDialogHeader(
              title: '결재라인 선택',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text(
                      '사원 검색',
                      style: TextStyle(
                        fontSize: kSearchFilterFontSize,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: kSearchFilterFontSize,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                      decoration: _searchDeco().copyWith(
                        hintText: '이름, 부서, 직급 검색',
                        hintStyle: const TextStyle(
                          fontSize: kSearchFilterFontSize,
                          color: FormStylePalette.textMuted,
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: FormStylePalette.textSecondary,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentRed),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _OrgTreePanel(
                          selectedDeptId: _selectedDeptId,
                          onSelect: _onDeptSelect,
                          departments: _departments,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EmployeeTablePanel(
                          employees: _visibleEmployees,
                          checked: _rowChecked,
                          onToggle: (id, v) {
                            setState(() {
                              if (v) {
                                _rowChecked.add(id);
                              } else {
                                _rowChecked.remove(id);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton(
                onPressed: _onAddApprovers,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('결재자 추가'),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SelectedStrip(
                lineNames: _lineNames,
                lineTitles: _lineTitles,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('결재라인 설정'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _onReset,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('결재라인 초기화'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgTreePanel extends StatelessWidget {
  const _OrgTreePanel({
    required this.selectedDeptId,
    required this.onSelect,
    required this.departments,
  });

  final String? selectedDeptId;
  final void Function(String?) onSelect;
  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.inputBg,
        border: Border.all(color: FormStylePalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Text(
              '조직도',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FormStylePalette.textPrimary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const Divider(height: 1, color: FormStylePalette.panelBorder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              children: [
                _TreeTile(
                  label: '전체',
                  isSelected: selectedDeptId == 'root',
                  onTap: () => onSelect('root'),
                ),
                for (final dept in departments)
                  _buildDeptTree(dept, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptTree(Department dept, int depth) {
    return _TreeTile(
      label: '${dept.name} (${dept.userCount})',
      isSelected: selectedDeptId == dept.id,
      onTap: () => onSelect(dept.id),
      depth: depth,
      children: [
        for (final child in dept.children)
          _buildDeptTree(child, depth + 1),
      ],
    );
  }
}

class _TreeTile extends StatefulWidget {
  const _TreeTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.children = const [],
    this.depth = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Widget> children;
  final int depth;

  @override
  State<_TreeTile> createState() => _TreeTileState();
}

class _TreeTileState extends State<_TreeTile> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;
    const padL = 8.0;
    final left = widget.depth * 12.0 + padL;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasChildren) setState(() => _open = !_open);
              widget.onTap();
            },
            child: Container(
              padding: EdgeInsets.only(left: left, right: 8, top: 6, bottom: 6),
              color: widget.isSelected
                  ? const Color(0xFFFFE4E4)
                  : Colors.transparent,
              child: Row(
                children: [
                  if (hasChildren) ...[
                    Icon(
                      _open ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                      color: FormStylePalette.textSecondary,
                    ),
                    const SizedBox(width: 2),
                  ] else
                    const SizedBox(width: 22),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && _open) ...widget.children,
      ],
    );
  }
}

class _EmployeeTablePanel extends StatelessWidget {
  const _EmployeeTablePanel({
    required this.employees,
    required this.checked,
    required this.onToggle,
  });

  final List<Employee> employees;
  final Set<int> checked;
  final void Function(int id, bool isChecked) onToggle;

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: 480,
      tableBuilder: (context, width) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: kErpTableInnerGridBorder,
          columnWidths: {
            0: const FixedColumnWidth(48),
            1: const FlexColumnWidth(1.05),
            2: const FlexColumnWidth(0.78),
            3: const FlexColumnWidth(1.05),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppTheme.accentRed),
              children: [
                ErpTableHeaderCell(' '),
                ErpTableHeaderCell('부서명'),
                ErpTableHeaderCell('직급(직책)'),
                ErpTableHeaderCell('사원명'),
              ],
            ),
            for (var i = 0; i < employees.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i.isEven
                      ? AppTheme.tableRowOdd
                      : AppTheme.tableRowEven,
                ),
                children: [
                  _CheckboxTableCell(
                    isChecked: checked.contains(employees[i].no),
                    onChanged: (v) => onToggle(employees[i].no, v ?? false),
                  ),
                  ErpTableBodyCell(employees[i].department),
                  ErpTableBodyCell(employees[i].jobTitle, center: true),
                  ErpTableBodyCell(employees[i].name, center: true),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CheckboxTableCell extends StatelessWidget {
  const _CheckboxTableCell({required this.isChecked, required this.onChanged});

  final bool isChecked;
  final void Function(bool? v) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: SizedBox(
          width: 40,
          height: kMinInteractiveDimension,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: AppTheme.accentRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

class _SelectedStrip extends StatelessWidget {
  const _SelectedStrip({required this.lineNames, required this.lineTitles});

  final List<String> lineNames;
  final List<String> lineTitles;

  @override
  Widget build(BuildContext context) {
    final cells = <({String t, String n})>[];
    for (var i = 0; i < kActivityApprovalLineSlotCount; i++) {
      final n = i < lineNames.length ? lineNames[i] : '';
      if (n.isEmpty) continue;
      final t = i < lineTitles.length ? lineTitles[i] : '';
      cells.add((t: t, n: n));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.inputBg,
        border: Border.all(color: FormStylePalette.panelBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FormStylePalette.panelBg,
                          border: Border.all(
                            color: FormStylePalette.panelBorder,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cells[i].t.isNotEmpty
                              ? '${cells[i].t} / ${cells[i].n}'
                              : cells[i].n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FormStylePalette.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
