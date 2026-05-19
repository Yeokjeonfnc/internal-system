// 마스터 mst003 — 메뉴권한 관리.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst003/mst003_api.dart';

/// 메뉴권한 관리
class MenuPermissionManagementView extends StatefulWidget {
  const MenuPermissionManagementView({super.key});

  @override
  State<MenuPermissionManagementView> createState() =>
      _MenuPermissionManagementViewState();
}

class _MenuPermissionManagementViewState
    extends State<MenuPermissionManagementView> {
  final _userApi = Mst001ApiService();
  final _permApi = Mst003ApiService();
  final _userSearchCtrl = TextEditingController();

  List<User> _users = [];
  int? _selectedUserIdx;
  List<MenuPermission> _rows = [];
  bool _loadingUsers = true;
  bool _loadingPerms = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    super.dispose();
  }

  User? get _selectedUser {
    final idx = _selectedUserIdx;
    if (idx == null) return null;
    for (final u in _users) {
      if (u.userIdx == idx) return u;
    }
    return null;
  }

  List<User> get _filteredUsers {
    final q = _userSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.department.toLowerCase().contains(q) ||
              e.positionNm.toLowerCase().contains(q) ||
              e.mobilePhone.toLowerCase().contains(q) ||
              e.userId.toLowerCase().contains(q),
        )
        .toList();
  }

  void _selectUser(User user) {
    setState(() => _selectedUserIdx = user.userIdx);
    _loadPermissions(user.userIdx);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _error = null;
    });
    try {
      final users = await _userApi.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingUsers = false;
        _error = '사원 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _loadPermissions(int userIdx) async {
    setState(() {
      _loadingPerms = true;
      _error = null;
    });
    try {
      final rows = await _permApi.fetchUserPermissions(userIdx);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loadingPerms = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPerms = false;
        _error = '메뉴 권한을 불러오지 못했습니다. DB 스크립트 적용 여부를 확인하세요.';
      });
    }
  }

  Future<void> _save() async {
    final userIdx = _selectedUserIdx;
    if (userIdx == null) return;
    setState(() => _saving = true);
    try {
      await _permApi.saveUserPermissions(
        userIdx,
        UserMenuPermissionSaveRequest(
          items: _rows
              .where((r) => r.isLeaf && r.hasAnyPermission)
              .map(
                (r) => UserMenuPermissionSaveItem(
                  menuCd: r.menuCd,
                  canView: r.canView,
                  canCreate: r.canCreate,
                  canUpdate: r.canUpdate,
                  canDelete: r.canDelete,
                ),
              )
              .toList(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메뉴 권한이 저장되었습니다.')));
      await _loadPermissions(userIdx);
      if (!mounted) return;
      // 본인 권한이 변경된 경우, 로컬 AuthProvider 캐시도 즉시 갱신해
      // 다른 화면(예: dev001 삭제 버튼 노출)이 새 권한을 따르도록 한다.
      await provider.Provider.of<AuthProvider>(context, listen: false)
          .applyMenuPermissionsForUser(userIdx, _rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setAllPermissions(bool on) {
    setState(() {
      _rows = _rows.map((r) {
        if (!r.isLeaf) return r;
        return r.copyWith(
          canView: on,
          canCreate: on,
          canUpdate: on,
          canDelete: on,
        );
      }).toList();
    });
  }

  void _setFlag(MenuPermission row, _PermCol col, bool? value) {
    if (!row.isLeaf) return;
    final on = value ?? false;
    setState(() {
      _rows = _rows.map((r) {
        if (r.menuCd != row.menuCd) return r;
        var next = r;
        switch (col) {
          case _PermCol.view:
            next = r.copyWith(canView: on);
            if (!on) {
              next = next.copyWith(
                canCreate: false,
                canUpdate: false,
                canDelete: false,
              );
            }
          case _PermCol.create:
            next = r.copyWith(canCreate: on, canView: on || r.canView);
          case _PermCol.update:
            next = r.copyWith(canUpdate: on, canView: on || r.canView);
          case _PermCol.delete:
            next = r.copyWith(canDelete: on, canView: on || r.canView);
        }
        return next;
      }).toList();
    });
  }

  Widget _buildMainPanels(BuildContext context) {
    final compact = useCompactErpLayout(context);
    if (!compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 280, child: _buildUserPicker()),
          const SizedBox(width: 16),
          Expanded(child: _buildPermissionMatrix(compact: false)),
        ],
      );
    }
    if (_selectedUserIdx == null) {
      return _buildUserPicker();
    }
    return _buildPermissionMatrix(compact: true);
  }

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.contentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.listScreenHPadding,
              16,
              AppDimensions.listScreenHPadding,
              AppDimensions.listScreenBottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '메뉴권한 관리',
                  style: TextStyle(
                    fontSize: compact ? 20 : 25,
                    fontWeight: FontWeight.w900,
                    color: FormStylePalette.textPrimary,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: FormStylePalette.textPrimary.withValues(alpha: 0.6),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Expanded(child: _buildMainPanels(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPicker() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: const Color(0xFFE2E5EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '사원 선택',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingUsers)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              SearchFilterTextField(
                controller: _userSearchCtrl,
                hint: '성명, 부서, 직급, 아이디 검색',
                borderRadius: 8,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_selectedUser != null) ...[
                const SizedBox(height: 8),
                _SelectedUserChip(
                  user: _selectedUser!,
                  onClear: () {
                    setState(() {
                      _selectedUserIdx = null;
                      _rows = [];
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
              Expanded(child: _buildUserSearchResults()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResults() {
    final users = _filteredUsers;
    if (users.isEmpty) {
      return Center(
        child: Text(
          _userSearchCtrl.text.trim().isEmpty
              ? '등록된 사원이 없습니다.'
              : '조회된 사원이 없습니다.',
          style: TextStyle(
            fontSize: 13,
            color: FormStylePalette.textPrimary.withValues(alpha: 0.55),
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final user = users[index];
        final selected = user.userIdx == _selectedUserIdx;
        return Material(
          color: erpPopupListRowBackgroundSelectable(index, selected: selected),
          child: InkWell(
            onTap: () => _selectUser(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jua(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppTheme.accentRed
                          : FormStylePalette.textPrimary,
                    ).copyWith(fontFamilyFallback: AppTheme.koreanFontFallback),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (user.department.isNotEmpty) user.department,
                      if (user.positionNm.isNotEmpty) user.positionNm,
                      if (user.userId.isNotEmpty) user.userId,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: FormStylePalette.textPrimary.withValues(
                        alpha: 0.6,
                      ),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bulkPermButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: accentOutlineButtonStyle(iconOnly: false),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }

  Widget _buildPermissionMatrix({required bool compact}) {
    final bulkActions = <Widget>[
      if (_selectedUserIdx != null && !_loadingPerms) ...[
        _bulkPermButton(
          label: '모두 선택',
          enabled: !_saving,
          onPressed: () => _setAllPermissions(true),
        ),
        _bulkPermButton(
          label: '모두 취소',
          enabled: !_saving,
          onPressed: () => _setAllPermissions(false),
        ),
      ],
      FilledButton(
        onPressed: _selectedUserIdx == null || _saving || _loadingPerms
            ? null
            : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('저장'),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: const Color(0xFFE2E5EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '사원 다시 선택',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _selectedUserIdx = null;
                        _rows = [];
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                  Expanded(
                    child: _selectedUser == null
                        ? const SizedBox.shrink()
                        : _SelectedUserChip(
                            user: _selectedUser!,
                            onClear: () {
                              setState(() {
                                _selectedUserIdx = null;
                                _rows = [];
                              });
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '메뉴별 권한',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 16 : 20,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: bulkActions,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '메뉴별 권한',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                      if (_selectedUserIdx != null && !_loadingPerms) ...[
                        _bulkPermButton(
                          label: '모두 선택',
                          enabled: !_saving,
                          onPressed: () => _setAllPermissions(true),
                        ),
                        const SizedBox(width: 8),
                        _bulkPermButton(
                          label: '모두 취소',
                          enabled: !_saving,
                          onPressed: () => _setAllPermissions(false),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton(
                        onPressed:
                            _selectedUserIdx == null || _saving || _loadingPerms
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('저장'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          if (_selectedUserIdx == null)
            Expanded(
              child: Center(
                child: Text(
                  compact
                      ? '사원을 검색해 선택하세요.'
                      : '왼쪽에서 사원을 검색해 선택하세요.',
                ),
              ),
            )
          else if (_loadingPerms)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ErpDataTable(
                  minWidth: compact ? 520 : 720,
                  tableBuilder: (context, width) => _PermissionTable(
                    rows: _rows,
                    onChanged: _setFlag,
                    width: width,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedUserChip extends StatelessWidget {
  const _SelectedUserChip({required this.user, required this.onClear});

  final User user;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (user.department.isNotEmpty) user.department,
      if (user.userId.isNotEmpty) user.userId,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jua(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentRed,
                  ).copyWith(fontFamilyFallback: AppTheme.koreanFontFallback),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: FormStylePalette.textPrimary.withValues(
                        alpha: 0.6,
                      ),
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: '선택 해제',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

enum _PermCol { view, create, update, delete }

class _PermissionTable extends StatelessWidget {
  const _PermissionTable({
    required this.rows,
    required this.onChanged,
    required this.width,
  });

  final List<MenuPermission> rows;
  final void Function(MenuPermission row, _PermCol col, bool? value) onChanged;
  final double width;

  static const double _permColMin = 96;

  @override
  Widget build(BuildContext context) {
    final permW = ((width - 360) / 4).clamp(_permColMin, 140.0);
    final menuW = width - permW * 4;

    return SizedBox(
      width: width,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: {
          0: FixedColumnWidth(menuW),
          1: FixedColumnWidth(permW),
          2: FixedColumnWidth(permW),
          3: FixedColumnWidth(permW),
          4: FixedColumnWidth(permW),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('메뉴'),
              ErpTableHeaderCell('조회'),
              ErpTableHeaderCell('등록'),
              ErpTableHeaderCell('수정'),
              ErpTableHeaderCell('삭제'),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final depth = row.parentMenuCd == null ? 0 : 1;
            final bg = entry.key.isEven
                ? AppTheme.tableRowOdd
                : AppTheme.tableRowEven;
            return TableRow(
              decoration: BoxDecoration(color: bg),
              children: [
                ErpTableBodyCell('${'  ' * depth}${row.menuNm}', center: true),
                _permCell(row, _PermCol.view),
                _permCell(row, _PermCol.create),
                _permCell(row, _PermCol.update),
                _permCell(row, _PermCol.delete),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _permCell(MenuPermission row, _PermCol col) {
    if (!row.isLeaf) {
      return const ErpTableBodyCell('', center: true);
    }
    final value = switch (col) {
      _PermCol.view => row.canView,
      _PermCol.create => row.canCreate,
      _PermCol.update => row.canUpdate,
      _PermCol.delete => row.canDelete,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Checkbox(
          value: value,
          onChanged: (v) => onChanged(row, col, v),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
