// 부서관리 화면 — 좌 트리 + 우 상세 패널(CHANGES_턴7 §1 / #7a).
//
// 데이터·정렬(드래그)·API 로직은 기존 그대로, 뷰 구성만 2단 레이아웃으로 교체.
// 우측 소속 사원은 기존 사원 API(Mst001ApiService.getUsers(deptIdx:))를 재사용한다.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/perf/session_list_cache.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_repo.dart';

class DepartmentView extends StatefulWidget {
  const DepartmentView({super.key});

  @override
  State<DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<DepartmentView> {
  final _repo = DepartmentRepository();
  final _userApi = Mst001ApiService();
  final _searchCtrl = TextEditingController();
  final Set<String> _expandedIds = {};
  final Map<String, Future<List<User>>> _memberFutures = {};
  List<Department> _departments = const [];
  String? _selectedId;
  bool _isLoading = true;
  bool _isSorting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    // 세션 캐시가 있으면 스피너 없이 즉시 그리고, 서버 데이터로 배경 교체한다.
    final cached = SessionListCache.get<Department>('mst002:all');
    if (cached != null && _departments.isEmpty) {
      setState(() {
        _departments = cached;
        _expandedIds
          ..clear()
          ..addAll(cached.map((e) => e.id));
        _selectedId ??= cached.isNotEmpty ? cached.first.id : null;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }
    final rows = await _repo.all();
    if (!mounted) return;
    SessionListCache.put<Department>('mst002:all', rows);
    setState(() {
      _departments = rows;
      _expandedIds
        ..clear()
        ..addAll(rows.map((e) => e.id));
      _memberFutures.clear();
      if (_selectedId == null ||
          _findDepartmentById(_selectedId!, rows) == null) {
        _selectedId = rows.isNotEmpty ? rows.first.id : null;
      }
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
    if (!context.menuCanUpdate(kMenuMst002)) return;
    final visibleRows = _visibleRows(_departments);
    if (oldIndex < 0 || oldIndex >= visibleRows.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= visibleRows.length) return;

    final moved = visibleRows[oldIndex].department;
    // 놓인 행을 그대로 target 으로 쓰면, 상위 부서를 펼쳐 둔 상태에서는 형제 사이에
    // 끼어 있는 '자식 행' 이 잡혀 부모가 다르다고 반려된다(같은 레벨끼리 끌었는데도
    // 경고만 뜨는 원인). 자식 행이면 같은 형제 그룹에 속한 조상으로 바꿔 잡는다.
    final target = _siblingLevelNodeOf(
      visibleRows[newIndex].department,
      moved.parentId,
    );
    if (target == null) {
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

  /// [node] 자신 또는 그 조상 중 [siblingParentId] 를 상위로 갖는 노드.
  /// 다른 가지로 끌어다 놓은 경우엔 null 을 돌려 기존 반려 문구를 유지한다.
  Department? _siblingLevelNodeOf(Department node, String? siblingParentId) {
    var current = node;
    // 상위 부서에 순환이 들어가 있어도 여기서 무한 루프가 되면 안 된다(부서 수만큼만 순회).
    final maxDepth = _getTotalCount();
    for (var guard = 0; guard <= maxDepth; guard++) {
      if (current.parentId == siblingParentId) return current;
      final upperId = current.parentId;
      if (upperId == null) return null;
      final upper = _findDepartmentById(upperId, _departments);
      if (upper == null) return null;
      current = upper;
    }
    return null;
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

  /// 검색 중에는 접힘 상태와 무관하게 전체를 평탄화해 이름으로 거른다.
  List<_VisibleDepartment> _searchRows(String query) {
    final rows = <_VisibleDepartment>[];
    void addRows(List<Department> nodes, int level) {
      for (final dept in nodes) {
        if (dept.name.contains(query)) {
          rows.add(_VisibleDepartment(dept, level));
        }
        addRows(dept.children, level + 1);
      }
    }

    addRows(_departments, 0);
    return rows;
  }

  /// 선택 부서의 상위 경로(루트 → 부모) — breadcrumb 표기용.
  List<Department> _ancestorsOf(String id) {
    final path = <Department>[];
    bool walk(List<Department> nodes) {
      for (final dept in nodes) {
        if (dept.id == id) return true;
        path.add(dept);
        if (walk(dept.children)) return true;
        path.removeLast();
      }
      return false;
    }

    walk(_departments);
    return path;
  }

  Future<List<User>> _membersOf(Department dept) {
    return _memberFutures.putIfAbsent(dept.id, () {
      final idx = int.tryParse(dept.id);
      if (idx == null) return Future.value(const <User>[]);
      return _userApi.getUsers(deptIdx: idx);
    });
  }

  void _selectDepartment(Department dept, {required bool narrow}) {
    setState(() => _selectedId = dept.id);
    if (narrow) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.94,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: _DepartmentDetailPanel(
              dept: dept,
              ancestors: _ancestorsOf(dept.id),
              membersFuture: _membersOf(dept),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReorder = context.menuCanUpdate(kMenuMst002);
    final query = _searchCtrl.text.trim();
    final searching = query.isNotEmpty;
    final rows = searching ? _searchRows(query) : _visibleRows(_departments);
    final selected = _selectedId == null
        ? null
        : _findDepartmentById(_selectedId!, _departments);

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 880;

                final tree = _DepartmentTreePane(
                  rows: rows,
                  totalCount: _getTotalCount(),
                  isLoading: _isLoading,
                  isSorting: _isSorting,
                  searching: searching,
                  searchCtrl: _searchCtrl,
                  canReorder: canReorder && !searching,
                  expandedIds: _expandedIds,
                  selectedId: _selectedId,
                  onQueryChanged: (_) => setState(() {}),
                  onRefresh: _loadDepartments,
                  onToggleExpanded: _toggleExpanded,
                  onReorder: _reorderDepartments,
                  onSelect: (d) => _selectDepartment(d, narrow: narrow),
                );

                final shell = DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                    border: Border.all(color: AppTheme.hairline),
                  ),
                  child: narrow
                      ? tree
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 320, child: tree),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _isLoading
                                  ? const SizedBox.shrink()
                                  : selected == null
                                  ? const _DetailEmptyPlaceholder()
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(
                                        26,
                                        22,
                                        26,
                                        28,
                                      ),
                                      child: _DepartmentDetailPanel(
                                        dept: selected,
                                        ancestors: _ancestorsOf(selected.id),
                                        membersFuture: _membersOf(selected),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  child: shell,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 좌측 트리 패널 — 검색 + 부서 트리(들여쓰기·caret·폴더 아이콘·인원 pill).
class _DepartmentTreePane extends StatelessWidget {
  const _DepartmentTreePane({
    required this.rows,
    required this.totalCount,
    required this.isLoading,
    required this.isSorting,
    required this.searching,
    required this.searchCtrl,
    required this.canReorder,
    required this.expandedIds,
    required this.selectedId,
    required this.onQueryChanged,
    required this.onRefresh,
    required this.onToggleExpanded,
    required this.onReorder,
    required this.onSelect,
  });

  final List<_VisibleDepartment> rows;
  final int totalCount;
  final bool isLoading;
  final bool isSorting;
  final bool searching;
  final TextEditingController searchCtrl;
  final bool canReorder;
  final Set<String> expandedIds;
  final String? selectedId;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onRefresh;
  final ValueChanged<String> onToggleExpanded;
  final ReorderCallback onReorder;
  final ValueChanged<Department> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget rowFor(BuildContext context, int index) {
      final row = rows[index];
      final dept = row.department;
      return _DepartmentTreeRow(
        key: ValueKey(dept.id),
        index: index,
        dept: dept,
        level: searching ? 0 : row.level,
        canReorder: canReorder,
        isExpanded: expandedIds.contains(dept.id),
        isSelected: dept.id == selectedId,
        onToggle: dept.hasChildren && !searching
            ? () => onToggleExpanded(dept.id)
            : null,
        onSelect: () => onSelect(dept),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            children: [
              const Text(
                '부서',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isLoading ? '' : '$totalCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const Spacer(),
              if (isSorting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                color: AppTheme.textMuted,
                tooltip: '새로고침',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: SearchFilterTextField(
            controller: searchCtrl,
            hint: '부서 검색',
            borderRadius: 9,
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppTheme.textPlaceholder,
            ),
            onChanged: onQueryChanged,
          ),
        ),
        if (canReorder)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Text(
              '드래그로 같은 상위 부서 내 순서 변경',
              style: TextStyle(
                fontSize: 10.5,
                color: AppTheme.textPlaceholder,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
              ? const Center(
                  child: Text(
                    '조회된 부서가 없습니다.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                )
              : canReorder
              ? ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: rows.length,
                  onReorder: onReorder,
                  itemBuilder: rowFor,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: rows.length,
                  itemBuilder: rowFor,
                ),
        ),
      ],
    );
  }
}

/// 트리 한 행 — 선택 시 레드 틴트, caret 은 확장 전용, 행 탭은 선택.
class _DepartmentTreeRow extends StatelessWidget {
  const _DepartmentTreeRow({
    super.key,
    required this.index,
    required this.dept,
    required this.level,
    required this.canReorder,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
  });

  final int index;
  final Department dept;
  final int level;
  final bool canReorder;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? AppTheme.accentRed : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppTheme.tableRowSelectedTint : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(9),
          hoverColor: AppTheme.chipNeutralBackground,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSelected ? const Color(0xFFF3DEDE) : Colors.transparent,
              ),
            ),
            padding: EdgeInsets.fromLTRB(6.0 + level * 16.0, 7, 8, 7),
            child: Row(
              children: [
                if (canReorder)
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 15,
                      color: AppTheme.textPlaceholder.withValues(alpha: 0.8),
                    ),
                  ),
                SizedBox(
                  width: 20,
                  child: onToggle != null
                      ? InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: onToggle,
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            size: 17,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Icon(
                  isExpanded && dept.hasChildren
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 15,
                  color: isSelected ? AppTheme.accentRed : AppTheme.textMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    dept.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected || level == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: labelColor,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 이 숫자는 하위 부서까지 합산한 인원이다 — 상세의 '소속 사원'(직속만)과
                // 다를 수밖에 없으므로 무엇을 세는 값인지 알려 준다.
                Tooltip(
                  message: '하위 부서 포함 인원',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentRed.withValues(alpha: 0.08)
                          : AppTheme.chipNeutralBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${dept.userCount}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.accentRed
                            : AppTheme.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailEmptyPlaceholder extends StatelessWidget {
  const _DetailEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 34, color: Color(0xFFB5B5B1)),
          SizedBox(height: 10),
          Text(
            '좌측에서 부서를 선택하세요.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

/// 우측 상세 패널 — 헤더(breadcrumb) + 스탯 3카드 + 소속 사원 리스트.
class _DepartmentDetailPanel extends StatelessWidget {
  const _DepartmentDetailPanel({
    required this.dept,
    required this.ancestors,
    required this.membersFuture,
  });

  final Department dept;
  final List<Department> ancestors;
  final Future<List<User>> membersFuture;

  @override
  Widget build(BuildContext context) {
    final path = [for (final a in ancestors) a.name];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dept.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppTheme.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path.isEmpty ? '최상위 부서' : path.join(' / '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DeptStatCard(
                label: '부서장',
                value: dept.manager.trim().isEmpty ? '-' : dept.manager,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              // 서버가 재귀 CTE 로 하위 부서까지 합산한 값이다(DeptMstMapper.selectDeptUserCounts).
              // 아래 '소속 사원' 목록은 직속 사원만이라 라벨을 구분하지 않으면
              // "21명이라면서 목록은 비어 있다"로 읽혀 데이터가 깨진 줄 안다.
              child: _DeptStatCard(
                label: '소속 인원(하위 포함)',
                value: '${dept.userCount}명',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DeptStatCard(
                label: '하위 부서',
                value: '${dept.children.length}개',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          '소속 사원',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '이 부서에 직접 배정된 사원만 표시됩니다. 하위 부서 인원은 해당 부서를 선택해 확인하세요.',
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: AppTheme.textMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<User>>(
          future: membersFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final users = snap.data ?? const <User>[];
            if (users.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.hairline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    // 하위 부서가 있으면 위 '소속 인원(하위 포함)' 과 어긋나 보이는 게
                    // 정상이라는 것까지 알려 줘야 "데이터가 깨졌다"로 읽히지 않는다.
                    dept.hasChildren
                        ? '이 부서에 직접 배정된 사원이 없습니다.\n하위 부서 인원은 하위 부서를 선택해 확인하세요.'
                        : '소속 사원이 없습니다.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              );
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < users.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _DeptMemberTile(
                      user: users[i],
                      isManager:
                          dept.manager.trim().isNotEmpty &&
                          users[i].name.trim() == dept.manager.trim(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DeptStatCard extends StatelessWidget {
  const _DeptStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptMemberTile extends StatelessWidget {
  const _DeptMemberTile({required this.user, required this.isManager});

  final User user;
  final bool isManager;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty ? '?' : user.name.trim()[0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.chipNeutralBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (user.positionNm.trim().isNotEmpty) user.positionNm,
                    if (user.userId.trim().isNotEmpty) user.userId,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ],
            ),
          ),
          if (isManager) ...[
            const SizedBox(width: 6),
            const StatusBadge('부서장', showDot: false, color: AppTheme.accentRed),
          ],
          if (user.svYn == SvYn.yes) ...[
            const SizedBox(width: 6),
            const StatusBadge(
              'SV',
              showDot: false,
              color: AppTheme.statusRenewal,
            ),
          ],
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
