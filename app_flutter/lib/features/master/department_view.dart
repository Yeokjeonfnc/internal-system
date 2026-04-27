// 부서관리 화면 — 기존 목록 화면과 동일한 셸을 사용한다.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/common_register_button.dart';
import 'package:app_flutter/features/master/department_model.dart';
import 'package:app_flutter/features/master/department_repository.dart';

/// 부서관리 화면 — 트리 구조로 부서를 표시한다.
class DepartmentView extends StatefulWidget {
  const DepartmentView({super.key});

  @override
  State<DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<DepartmentView> {
  final _repo = DepartmentRepository();
  late final List<Department> _departments;
  final Set<String> _expandedIds = {'root', 'mgmt'};
  String? _selectedDeptId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _departments = _repo.all();
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _selectDepartment(String id) {
    setState(() {
      _selectedDeptId = id;
      _isEditing = false;
    });
  }

  void _enterEditMode() {
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _showSnackBar('취소되었습니다.');
  }

  void _saveEdit() {
    setState(() => _isEditing = false);
    _showSnackBar('저장되었습니다. (API 연동 예정)');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Department? _findDepartmentById(String id, List<Department> departments) {
    for (final dept in departments) {
      if (dept.id == id) return dept;
      final found = _findDepartmentById(id, dept.children);
      if (found != null) return found;
    }
    return null;
  }

  Department? get _selectedDepartment {
    if (_selectedDeptId == null) return null;
    return _findDepartmentById(_selectedDeptId!, _departments);
  }

  int _getTotalCount() {
    int count = 0;
    void countDept(Department dept) {
      count++;
      for (final child in dept.children) {
        countDept(child);
      }
    }

    for (final dept in _departments) {
      countDept(dept);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.listScreenHPadding,
          0,
          AppDimensions.listScreenHPadding,
          AppDimensions.listScreenBottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.contentMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: const Color(0xFFE2E5EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.listCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '총 ${_getTotalCount()}개 부서',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        if (_selectedDepartment != null) ...[
                          if (_isEditing) ...[
                            SaveActionButton(onPressed: _saveEdit),
                            const SizedBox(width: 8),
                            CancelActionButton(onPressed: _cancelEdit),
                            const SizedBox(width: 8),
                          ] else ...[
                            EditActionButton(onPressed: _enterEditMode),
                            const SizedBox(width: 8),
                          ],
                        ],
                        RegisterButton(
                          onPressed: () {
                            _showSnackBar('부서 등록 화면은 추후 연동 예정입니다.');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _DepartmentTable(
                        departments: _departments,
                        expandedIds: _expandedIds,
                        selectedDeptId: _selectedDeptId,
                        onToggleExpanded: _toggleExpanded,
                        onSelectDepartment: _selectDepartment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentTable extends StatelessWidget {
  const _DepartmentTable({
    required this.departments,
    required this.expandedIds,
    required this.selectedDeptId,
    required this.onToggleExpanded,
    required this.onSelectDepartment,
  });

  final List<Department> departments;
  final Set<String> expandedIds;
  final String? selectedDeptId;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<String> onSelectDepartment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: Color(0xFFE2E5EB)),
            right: BorderSide(color: Color(0xFFE2E5EB)),
            bottom: BorderSide(color: Color(0xFFE2E5EB)),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: constraints.maxWidth,
                child: _buildTable(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable() {
    final rows = <TableRow>[
      const TableRow(
        decoration: BoxDecoration(color: AppTheme.accentRed),
        children: [
          _DepartmentHeaderCell('부서'),
          _DepartmentHeaderCell('책임자'),
          _DepartmentHeaderCell('사용자 수'),
        ],
      ),
    ];

    for (final dept in departments) {
      _addDepartmentRows(rows, dept, 0);
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: Color(0xFFE2E5EB), width: 1),
        verticalInside: BorderSide(color: Color(0xFFE2E5EB), width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  void _addDepartmentRows(List<TableRow> rows, Department dept, int level) {
    final isExpanded = expandedIds.contains(dept.id);
    final hasChildren = dept.hasChildren;
    final isSelected = selectedDeptId == dept.id;

    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFE4E4)
              : (rows.length.isEven
                    ? AppTheme.tableRowEven
                    : AppTheme.tableRowOdd),
        ),
        children: [
          _DepartmentNameCell(
            name: dept.name,
            level: level,
            hasChildren: hasChildren,
            isExpanded: isExpanded,
            isSelected: isSelected,
            onToggle: hasChildren ? () => onToggleExpanded(dept.id) : null,
            onSelect: () => onSelectDepartment(dept.id),
          ),
          _DepartmentBodyCell(dept.manager.isEmpty ? '-' : dept.manager),
          _DepartmentBodyCell(dept.userCount.toString(), center: true),
        ],
      ),
    );

    if (isExpanded && hasChildren) {
      for (final child in dept.children) {
        _addDepartmentRows(rows, child, level + 1);
      }
    }
  }
}

class _DepartmentHeaderCell extends StatelessWidget {
  const _DepartmentHeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}

class _DepartmentBodyCell extends StatelessWidget {
  const _DepartmentBodyCell(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF212529),
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }
}

class _DepartmentNameCell extends StatelessWidget {
  const _DepartmentNameCell({
    required this.name,
    required this.level,
    required this.hasChildren,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
  });

  final String name;
  final int level;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSelect();
        if (hasChildren && onToggle != null) {
          onToggle!();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 8.0 + (level * 24.0),
          right: 8.0,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          children: [
            if (hasChildren)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isExpanded ? Icons.remove : Icons.add,
                  size: 16,
                  color: const Color(0xFF6B7280),
                ),
              )
            else
              const SizedBox(width: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF212529),
                  fontWeight: isSelected || level == 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
