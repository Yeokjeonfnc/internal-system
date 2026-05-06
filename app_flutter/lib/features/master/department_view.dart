// 부서관리 화면 — API 기반 트리 구조 목록.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_register_button.dart';
import 'package:app_flutter/features/master/department_model.dart';
import 'package:app_flutter/features/master/department_repository.dart';

class DepartmentView extends StatefulWidget {
  const DepartmentView({super.key});

  @override
  State<DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<DepartmentView> {
  final _repo = DepartmentRepository();
  final Set<String> _expandedIds = {};
  List<Department> _departments = const [];
  bool _isLoading = true;
  bool _isSorting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    final rows = await _repo.all();
    if (!mounted) return;
    setState(() {
      _departments = rows;
      _expandedIds
        ..clear()
        ..addAll(rows.map((e) => e.id));
      _isLoading = false;
    });
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
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

  Future<void> _reorderDepartments(int oldIndex, int newIndex) async {
    final visibleRows = _visibleRows(_departments);
    if (oldIndex < 0 || oldIndex >= visibleRows.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= visibleRows.length) return;

    final moved = visibleRows[oldIndex].department;
    final target = visibleRows[newIndex].department;
    if (moved.parentId != target.parentId) {
      _showSnackBar('같은 상위 부서 안에서만 순서를 변경할 수 있습니다.');
      return;
    }

    final parentId = moved.parentId;
    final siblings = _childrenForParent(parentId);
    final siblingIds = siblings.map((e) => e.id).toList();
    final from = siblingIds.indexOf(moved.id);
    final to = siblingIds.indexOf(target.id);
    if (from < 0 || to < 0 || from == to) return;

    final reorderedIds = [...siblingIds];
    final movedId = reorderedIds.removeAt(from);
    reorderedIds.insert(to, movedId);
    final nextDepartments = _rebuildWithSiblingOrder(
      _departments,
      parentId,
      reorderedIds,
    );

    setState(() {
      _departments = nextDepartments;
      _isSorting = true;
    });

    final parentIdx = parentId == null ? null : int.tryParse(parentId);
    final payload = <DepartmentSortOrder>[
      for (int i = 0; i < reorderedIds.length; i++)
        DepartmentSortOrder(
          deptIdx: int.parse(reorderedIds[i]),
          upperDeptIdx: parentIdx,
          sortOrder: i + 1,
        ),
    ];
    final ok = await _repo.updateSortOrders(payload);
    if (!mounted) return;
    setState(() => _isSorting = false);
    if (!ok) {
      _showSnackBar('순서 저장에 실패했습니다. 다시 조회합니다.');
      await _loadDepartments();
    }
  }

  List<Department> _childrenForParent(String? parentId) {
    if (parentId == null) return _departments;
    final parent = _findDepartmentById(parentId, _departments);
    return parent?.children ?? const [];
  }

  Department? _findDepartmentById(String id, List<Department> departments) {
    for (final dept in departments) {
      if (dept.id == id) return dept;
      final found = _findDepartmentById(id, dept.children);
      if (found != null) return found;
    }
    return null;
  }

  List<Department> _rebuildWithSiblingOrder(
    List<Department> nodes,
    String? parentId,
    List<String> orderedIds,
  ) {
    if (parentId == null) {
      return _orderSiblings(nodes, orderedIds);
    }
    return [
      for (final node in nodes)
        node.id == parentId
            ? node.copyWith(children: _orderSiblings(node.children, orderedIds))
            : node.copyWith(
                children: _rebuildWithSiblingOrder(
                  node.children,
                  parentId,
                  orderedIds,
                ),
              ),
    ];
  }

  List<Department> _orderSiblings(List<Department> nodes, List<String> ids) {
    final byId = {for (final node in nodes) node.id: node};
    return [
      for (int i = 0; i < ids.length; i++)
        if (byId[ids[i]] != null) byId[ids[i]]!.copyWith(sortOrder: i + 1),
    ];
  }

  List<_VisibleDepartment> _visibleRows(List<Department> departments) {
    final rows = <_VisibleDepartment>[];
    void addRows(List<Department> nodes, int level) {
      for (final dept in nodes) {
        rows.add(_VisibleDepartment(dept, level));
        if (_expandedIds.contains(dept.id) && dept.hasChildren) {
          addRows(dept.children, level + 1);
        }
      }
    }

    addRows(departments, 0);
    return rows;
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
                            _isLoading
                                ? '부서 목록을 불러오는 중입니다.'
                                : '총 ${_getTotalCount()}개 부서',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        if (_isSorting) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                        ],
                        TextButton.icon(
                          onPressed: _loadDepartments,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('새로고침'),
                        ),
                        const SizedBox(width: 8),
                        RegisterButton(
                          onPressed: () {
                            _showSnackBar('부서 등록 화면은 추후 연동 예정입니다.');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: const Text(
                          '* 드래그 하여 같은 상위 부서 내 순서 변경이 가능합니다.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1000,
                                ),
                                child: _DepartmentTable(
                                  rows: _visibleRows(_departments),
                                  expandedIds: _expandedIds,
                                  onToggleExpanded: _toggleExpanded,
                                  onReorder: _reorderDepartments,
                                ),
                              ),
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
    required this.rows,
    required this.expandedIds,
    required this.onToggleExpanded,
    required this.onReorder,
  });

  final List<_VisibleDepartment> rows;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggleExpanded;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 247, 247, 247)),
          borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
        ),
        child: Column(
          children: [
            const _DepartmentHeaderRow(),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        '조회된 부서가 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: rows.length,
                      onReorder: onReorder,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final dept = row.department;
                        return _DepartmentDataRow(
                          key: ValueKey(dept.id),
                          index: index,
                          dept: dept,
                          level: row.level,
                          isExpanded: expandedIds.contains(dept.id),
                          onToggle: dept.hasChildren
                              ? () => onToggleExpanded(dept.id)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentHeaderRow extends StatelessWidget {
  const _DepartmentHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: AppTheme.accentRed,
      child: const Row(
        children: [
          SizedBox(width: 42),
          Expanded(flex: 5, child: _DepartmentHeaderCell('부서')),
          Expanded(flex: 2, child: _DepartmentHeaderCell('사용자 수')),
        ],
      ),
    );
  }
}

Color _departmentLevelColor(int level) {
  const colors = [
    Color.fromARGB(255, 197, 50, 50),
    Color(0xFF2F66B3),
    Color(0xFF198754),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
  ];
  return colors[level.clamp(0, colors.length - 1)];
}

Color _departmentRowColor(int level, int index) {
  const levelColors = [
    Color(0xFFFFF7F8),
    Color(0xFFF5F8FF),
    Color(0xFFF3FBF7),
    Color(0xFFFFFAEB),
    Color(0xFFF7F2FF),
  ];
  final base = levelColors[level.clamp(0, levelColors.length - 1)];
  if (index.isOdd) {
    return Color.alphaBlend(Colors.black.withValues(alpha: 0.025), base);
  }
  return base;
}

class _DepartmentHeaderCell extends StatelessWidget {
  const _DepartmentHeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _DepartmentDataRow extends StatelessWidget {
  const _DepartmentDataRow({
    super.key,
    required this.index,
    required this.dept,
    required this.level,
    required this.isExpanded,
    required this.onToggle,
  });

  final int index;
  final Department dept;
  final int level;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final levelColor = _departmentLevelColor(level);
    return Material(
      color: _departmentRowColor(level, index),
      child: InkWell(
        onTap: onToggle,
        child: Container(
          height: level == 0 ? 56 : 50,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E5EB))),
          ),
          child: Row(
            children: [
              Container(width: 5, color: levelColor),
              ReorderableDragStartListener(
                index: index,
                child: SizedBox(
                  width: 38,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: _DepartmentNameCell(
                  name: dept.name,
                  level: level,
                  hasChildren: dept.hasChildren,
                  isExpanded: isExpanded,
                  onToggle: onToggle,
                ),
              ),
              Expanded(
                flex: 2,
                child: _DepartmentBodyCell(
                  dept.userCount.toString(),
                  center: true,
                  accentColor: levelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentBodyCell extends StatelessWidget {
  const _DepartmentBodyCell(this.text, {this.center = false, this.accentColor});

  final String text;
  final bool center;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: accentColor ?? const Color(0xFF212529),
            fontWeight: accentColor != null ? FontWeight.w700 : FontWeight.w400,
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
    required this.onToggle,
  });

  final String name;
  final int level;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final levelColor = _departmentLevelColor(level);
    return Padding(
      padding: EdgeInsets.only(left: 10.0 + (level * 28.0), right: 8.0),
      child: Row(
        children: [
          if (hasChildren)
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: levelColor.withValues(alpha: 0.42)),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isExpanded ? Icons.remove : Icons.add,
                  size: 18,
                  color: levelColor,
                ),
              ),
            )
          else
            SizedBox(
              width: 24,
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.52),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 17,
                color: level == 0
                    ? const Color(0xFF111827)
                    : const Color(0xFF212529),
                fontWeight: level == 0 ? FontWeight.w800 : FontWeight.w400,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibleDepartment {
  const _VisibleDepartment(this.department, this.level);

  final Department department;
  final int level;
}
