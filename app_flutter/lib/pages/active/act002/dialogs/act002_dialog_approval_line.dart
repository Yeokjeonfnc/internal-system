// 결재라인 선택 — 등록·상신 화면용 모달(조직도·사원 그리드·선택 띠, [FormStylePalette] / [ErpDataTable] 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_search_field.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_repo.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';

/// 격자형 직급/결재 열 수(기안·스크린샷 기준 7).
const int kActivityApprovalLineSlotCount = 7;

class ActivityApprovalLineResult {
  const ActivityApprovalLineResult({
    required this.titles,
    required this.names,
    required this.userIds,
  });

  final List<String> titles;
  final List<String> names;

  /// 각 슬롯의 user_mst.user_id (빈 슬롯은 '')
  final List<String> userIds;
}

/// [결재라인] — 직급+이름 슬롯을 채운다.
Future<ActivityApprovalLineResult?> showActivityApprovalLineDialog(
  BuildContext context, {
  List<String> initialNames = const [],
  List<String> initialTitles = const [],
  List<String> initialUserIds = const [],
  Set<String> blockedKeys = const {},
  String blockedMessage = '이미 다른 결재라인에 지정된 사람은 선택할 수 없습니다.',
  bool requestFocus = true,
}) {
  return showDialog<ActivityApprovalLineResult?>(
    context: context,
    barrierColor: const Color(0x66000000),
    requestFocus: requestFocus,
    builder: (ctx) {
      final compact = useCompactErpLayout(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(compact ? 12 : 20),
        child: _ApprovalLineDialog(
          initialNames: _padToSlots(initialNames),
          initialTitles: _padToSlots(initialTitles),
          initialUserIds: _padToSlots(initialUserIds),
          blockedKeys: {
            for (final k in blockedKeys)
              if (k.trim().isNotEmpty) k.trim().toUpperCase(),
          },
          blockedMessage: blockedMessage,
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
    required this.initialUserIds,
    required this.blockedKeys,
    required this.blockedMessage,
  });

  final List<String> initialNames;
  final List<String> initialTitles;
  final List<String> initialUserIds;
  final Set<String> blockedKeys;
  final String blockedMessage;

  @override
  State<_ApprovalLineDialog> createState() => _ApprovalLineDialogState();
}

class _ApprovalLineDialogState extends State<_ApprovalLineDialog> {
  final TextEditingController _searchController = TextEditingController();
  final DepartmentRepository _deptRepo = DepartmentRepository();
  final Mst001ApiService _userApi = Mst001ApiService();

  String? _selectedDeptId;
  final Set<int> _rowChecked = {};
  late List<String> _lineNames;
  late List<String> _lineTitles;
  late List<String> _lineUserIds;

  List<Department> _departments = [];
  List<User> _allUsers = [];
  List<User> _displayedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lineNames = List<String>.from(widget.initialNames);
    _lineTitles = List<String>.from(widget.initialTitles);
    _lineUserIds = List<String>.from(widget.initialUserIds);
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
      final users = await _userApi.getUsers();
      if (!mounted) return;
      setState(() {
        _departments = depts;
        _allUsers = users;
        _displayedUsers = users;
        _selectedDeptId ??= 'root';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('결재라인 데이터 로딩 실패: $e');
      if (!mounted) return;
      setState(() {
        _departments = const [];
        _allUsers = const [];
        _displayedUsers = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사원 목록을 불러오지 못했습니다. ($e)')));
    }
  }

  Future<void> _loadUsersByDept(String deptId) async {
    try {
      final deptIdx = int.tryParse(deptId);
      if (deptIdx == null) {
        setState(() => _displayedUsers = _allUsers);
        return;
      }
      final users = await _userApi.getUsers(deptIdx: deptIdx);
      setState(() => _displayedUsers = users);
    } catch (e) {
      debugPrint('부서별 사원 조회 실패: $e');
      setState(() => _displayedUsers = []);
    }
  }

  List<User> get _visibleUsers {
    var list = _displayedUsers;
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.name.contains(q) ||
                e.department.contains(q) ||
                e.positionNm.contains(q),
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
      setState(() => _displayedUsers = _allUsers);
    } else {
      _loadUsersByDept(deptId);
    }
  }

  User? _userByIdx(int userIdx) {
    for (final list in [_visibleUsers, _displayedUsers, _allUsers]) {
      for (final u in list) {
        if (u.userIdx == userIdx) return u;
      }
    }
    return null;
  }

  bool _isBlockedUser(User u) {
    if (widget.blockedKeys.isEmpty) return false;
    final id = u.userId.trim().toUpperCase();
    final name = u.name.trim().toUpperCase();
    return (id.isNotEmpty && widget.blockedKeys.contains(id)) ||
        (name.isNotEmpty && widget.blockedKeys.contains(name));
  }

  void _toggleRowCheck(int userIdx, bool checked) {
    setState(() {
      if (checked) {
        _rowChecked.add(userIdx);
      } else {
        _rowChecked.remove(userIdx);
      }
    });
  }

  void _onAddApprovers() {
    if (_rowChecked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추가할 사원을 체크하거나 행을 눌러 선택하세요.'),
        ),
      );
      return;
    }

    final ids = _rowChecked.toList()..sort();
    final toAdd = <User>[];
    for (final id in ids) {
      final picked = _userByIdx(id);
      if (picked != null) toAdd.add(picked);
    }
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 사원 정보를 찾지 못했습니다.')),
      );
      return;
    }

    var added = 0;
    var skippedDuplicate = 0;
    var skippedBlocked = 0;
    var skippedFull = false;
    setState(() {
      for (final u in toAdd) {
        if (_isBlockedUser(u)) {
          skippedBlocked++;
          continue;
        }
        if (_lineNames.contains(u.name)) {
          skippedDuplicate++;
          continue;
        }
        final i = _lineNames.indexWhere((e) => e.isEmpty);
        if (i < 0) {
          skippedFull = true;
          break;
        }
        _lineNames[i] = u.name;
        _lineTitles[i] = u.positionNm;
        final loginId = u.userId.trim();
        _lineUserIds[i] = loginId.isNotEmpty ? loginId : u.name.trim();
        added++;
      }
      _rowChecked.clear();
    });

    if (added == 0) {
      final msg = skippedBlocked > 0
          ? widget.blockedMessage
          : skippedFull
          ? '결재 슬롯이 모두 찼습니다. 초기화 후 다시 추가하세요.'
          : skippedDuplicate > 0
          ? '이미 결재라인에 있는 사원입니다.'
          : '결재자를 추가하지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else if (skippedBlocked > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.blockedMessage)));
    }
  }

  void _onReset() {
    setState(() {
      // 0번 슬롯은 기안(본인) — 결재자만 비우고 본인은 유지한다.
      final writerName = _lineNames.isNotEmpty
          ? _lineNames[0]
          : widget.initialNames[0];
      final writerTitle = _lineTitles.isNotEmpty
          ? _lineTitles[0]
          : widget.initialTitles[0];
      final writerId = _lineUserIds.isNotEmpty
          ? _lineUserIds[0]
          : widget.initialUserIds[0];

      _lineNames = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _lineTitles = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _lineUserIds = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _lineNames[0] = writerName;
      _lineTitles[0] = writerTitle;
      _lineUserIds[0] = writerId;
      _rowChecked.clear();
    });
  }

  void _onApply() {
    Navigator.of(context).pop(
      ActivityApprovalLineResult(
        names: _padToSlots(_lineNames),
        titles: _padToSlots(_lineTitles),
        userIds: _padToSlots(_lineUserIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final h = MediaQuery.sizeOf(context).height * (compact ? 0.92 : 0.86);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? double.infinity : 1000,
        maxHeight: h.clamp(compact ? 360.0 : 420.0, compact ? 820.0 : 760.0),
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
              child: LabeledSearchFieldRow(
                label: '사원 검색',
                controller: _searchController,
                hintText: '이름, 부서, 직급 검색',
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentRed,
                    ),
                  ),
                ),
              )
            else if (_allUsers.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _departments.isEmpty
                        ? '조직·사원 데이터를 불러오지 못했습니다.\n백엔드 로그의 /users 오류를 확인하세요.'
                        : '사원 목록이 비어 있습니다.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: FormStylePalette.textSecondary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: compact
                      ? _UserTablePanel(
                          compact: true,
                          users: _visibleUsers,
                          checked: _rowChecked,
                          onToggle: _toggleRowCheck,
                        )
                      : Row(
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
                              child: _UserTablePanel(
                                users: _visibleUsers,
                                checked: _rowChecked,
                                onToggle: _toggleRowCheck,
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
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _onApply,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('결재라인 설정'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _onReset,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('결재라인 초기화'),
                        ),
                      ],
                    )
                  : Row(
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
                for (final dept in departments) _buildDeptTree(dept, 0),
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
        for (final child in dept.children) _buildDeptTree(child, depth + 1),
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

class _UserTablePanel extends StatelessWidget {
  const _UserTablePanel({
    required this.users,
    required this.checked,
    required this.onToggle,
    this.compact = false,
  });

  final List<User> users;
  final Set<int> checked;
  final void Function(int id, bool isChecked) onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          '표시할 사원이 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: FormStylePalette.textSecondary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }

    return ErpVirtualDataTable(
      minWidth: compact ? 300 : 480,
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: FlexColumnWidth(1.05),
        2: FlexColumnWidth(0.78),
        3: FlexColumnWidth(1.05),
      },
      headerRow: const TableRow(
        decoration: kErpTableHeaderRowDecoration,
        children: [
          ErpTableHeaderCell(' '),
          ErpTableHeaderCell('부서명'),
          ErpTableHeaderCell('직급(직책)'),
          ErpTableHeaderCell('사원명'),
        ],
      ),
      rowCount: users.length,
      rowBuilder: (context, i) {
        final user = users[i];
        final isChecked = checked.contains(user.userIdx);
        return TableRow(
          decoration: BoxDecoration(
            color: isChecked
                ? const Color(0xFFE8F4FC)
                : i.isEven
                ? AppTheme.tableRowOdd
                : AppTheme.tableRowEven,
          ),
          children: [
            _CheckboxTableCell(
              isChecked: isChecked,
              onChanged: (v) => onToggle(user.userIdx, v ?? false),
            ),
            _TappableBodyCell(
              label: user.department,
              onTap: () => onToggle(user.userIdx, !isChecked),
            ),
            _TappableBodyCell(
              label: user.positionNm,
              center: true,
              onTap: () => onToggle(user.userIdx, !isChecked),
            ),
            _TappableBodyCell(
              label: user.name,
              center: true,
              onTap: () => onToggle(user.userIdx, !isChecked),
            ),
          ],
        );
      },
    );
  }
}

class _TappableBodyCell extends StatelessWidget {
  const _TappableBodyCell({
    required this.label,
    required this.onTap,
    this.center = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ErpTableBodyCell(label, center: center),
      ),
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
