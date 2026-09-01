// 사이드바 조직도 팝오버 — 검색·펼침 트리는 이미 받은 부서·사원만 걸른다.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/org001/org001_provider.dart';
import 'package:provider/provider.dart' as provider;

const _kCompanyKey = 'company';
const _kUnassignedKey = 'unassigned';

const _kPanelBg = Color(0xFF2F2F2F);
const _kSearchBg = Color(0xFF3C3C3C);
const _kText = Color(0xFFF3F3F3);
const _kMuted = Color(0xFFA8A8A8);
const _kHint = Color(0xFF8A8A8A);
const _kHover = Color(0xFF3A3A3A);

Future<void> showOrgChartPopover(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final compact = size.width < AppDimensions.shellCompactMaxWidth;
  final leftPad = compact ? 16.0 : 258.0;
  final panelH = math.min(720.0, size.height - 72);

  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (ctx) {
      return Dialog(
        alignment: Alignment.centerLeft,
        insetPadding: EdgeInsets.fromLTRB(leftPad, 36, 24, 36),
        backgroundColor: _kPanelBg,
        elevation: 16,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData(
            brightness: Brightness.dark,
            fontFamily: AppTheme.brandFontFamily,
            colorScheme: const ColorScheme.dark(
              primary: Colors.white70,
              surface: _kPanelBg,
            ),
          ),
          child: SizedBox(
            width: 360,
            height: panelH,
            child: const _OrgChartPopover(),
          ),
        ),
      );
    },
  );
}

class _OrgChartPopover extends ConsumerStatefulWidget {
  const _OrgChartPopover();

  @override
  ConsumerState<_OrgChartPopover> createState() => _OrgChartPopoverState();
}

class _OrgChartPopoverState extends ConsumerState<_OrgChartPopover> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Set<String> _expanded = {_kCompanyKey};
  String _query = '';
  bool _didSeedExpand = false;
  bool _didAutoScroll = false;

  int? get _myDeptIdx =>
      provider.Provider.of<AuthProvider>(context, listen: false).profile?.deptIdx;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    final q = raw.trim();
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _didSeedExpand = false;
        final data = ref.read(orgChartDataProvider).asData?.value;
        if (data != null) {
          _seedDefaultExpand(data);
        } else {
          _expanded
            ..clear()
            ..add(_kCompanyKey);
        }
      }
    });
  }

  void _toggle(String key) {
    setState(() {
      if (_expanded.contains(key)) {
        _expanded.remove(key);
      } else {
        _expanded.add(key);
      }
    });
  }

  void _seedDefaultExpand(OrgChartSnapshot data) {
    if (_didSeedExpand || _query.isNotEmpty) return;
    _didSeedExpand = true;
    _expanded
      ..clear()
      ..addAll(_pathKeysToMyTeam(data, _myDeptIdx));
    _didAutoScroll = false;
  }

  void _scrollToMyTeam(List<_OrgRow> rows) {
    if (_didAutoScroll || _query.isNotEmpty) return;
    final deptIdx = _myDeptIdx;
    if (deptIdx == null) return;
    final target = _deptKey('$deptIdx');
    final index = rows.indexWhere((r) => r.key == target);
    if (index < 0) return;
    _didAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      const rowH = 38.0;
      final max = _scrollCtrl.position.maxScrollExtent;
      final offset = (index * rowH - 48).clamp(0.0, max);
      _scrollCtrl.jumpTo(offset);
    });
  }

  void _openUser(User user) {
    if (!context.menuCanView(kMenuMst001)) return;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go('${AppRoutes.masterUsers}/${user.userIdx}');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<OrgChartSnapshot>>(orgChartDataProvider, (_, next) {
      final data = next.asData?.value;
      if (data == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _seedDefaultExpand(data));
      });
    });
    final async = ref.watch(orgChartDataProvider);
    final searching = _query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
          child: Row(
            children: [
              const Text(
                '조직도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: _kMuted,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              style: const TextStyle(
                fontSize: 13,
                color: _kText,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
              cursorColor: _kText,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _kSearchBg,
                hintText: '이름, 직위, 직책, 직급, 부서, 전화, 아이디',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: _kHint,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _kHint,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
            error: (_, _) => const Center(
              child: Text(
                '조직도를 불러오지 못했습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: _kMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
            data: (data) {
              final rows = _flatten(data, _query, _expanded);
              _scrollToMyTeam(rows);
              if (rows.isEmpty) {
                return const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                );
              }
              final canOpenUser = context.menuCanView(kMenuMst001);
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  return _OrgTreeRow(
                    row: row,
                    isExpanded: searching
                        ? row.expandable
                        : _expanded.contains(row.key),
                    onToggle: searching || !row.expandable
                        ? null
                        : () => _toggle(row.key),
                    onUserTap: row.user != null && canOpenUser
                        ? () => _openUser(row.user!)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _OrgKind { company, dept, user, unassigned }

class _OrgRow {
  const _OrgRow({
    required this.key,
    required this.kind,
    required this.level,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.expandable,
    this.user,
  });

  final String key;
  final _OrgKind kind;
  final int level;
  final String label;
  final String subtitle;
  final int count;
  final bool expandable;
  final User? user;
}

String _deptKey(String id) => 'dept:$id';

/// 회사 → 내 부서까지 경로만 펼친다. 부서가 없으면 미배정을 연다.
Set<String> _pathKeysToMyTeam(OrgChartSnapshot data, int? myDeptIdx) {
  final keys = <String>{_kCompanyKey};
  if (myDeptIdx == null) {
    if (data.unassigned.isNotEmpty) keys.add(_kUnassignedKey);
    return keys;
  }
  final target = '$myDeptIdx';
  List<String>? walk(Department dept, List<String> acc) {
    final path = [...acc, dept.id];
    if (dept.id == target) return path;
    for (final child in dept.children) {
      final hit = walk(child, path);
      if (hit != null) return hit;
    }
    return null;
  }

  List<String>? path;
  for (final root in data.departments) {
    path = walk(root, const []);
    if (path != null) break;
  }
  if (path == null) {
    if (data.unassigned.isNotEmpty) keys.add(_kUnassignedKey);
    return keys;
  }
  for (final id in path) {
    keys.add(_deptKey(id));
  }
  return keys;
}

String _norm(String raw) => raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');

String _digits(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

bool _userMatches(User user, String q) {
  final n = _norm(q);
  if (n.isEmpty) return true;
  final hay = _norm(
    '${user.name} ${user.positionNm} ${user.department} '
    '${user.mobilePhone} ${user.userId} ${user.email}',
  );
  if (hay.contains(n)) return true;
  final d = _digits(q);
  return d.isNotEmpty && _digits(user.mobilePhone).contains(d);
}

bool _deptNameMatches(Department dept, String q) {
  final n = _norm(q);
  return n.isNotEmpty && _norm(dept.name).contains(n);
}

int _subtreeUserCount(Department dept, OrgChartSnapshot data) {
  var n = data.usersIn(dept).length;
  for (final child in dept.children) {
    n += _subtreeUserCount(child, data);
  }
  return n;
}

bool _subtreeHasMatch(Department dept, OrgChartSnapshot data, String q) {
  if (q.isEmpty) return true;
  if (_deptNameMatches(dept, q)) return true;
  if (data.usersIn(dept).any((u) => _userMatches(u, q))) return true;
  return dept.children.any((c) => _subtreeHasMatch(c, data, q));
}

List<_OrgRow> _flatten(
  OrgChartSnapshot data,
  String query,
  Set<String> expanded,
) {
  final q = query.trim();
  final rows = <_OrgRow>[];
  final companyOpen = q.isNotEmpty || expanded.contains(_kCompanyKey);

  rows.add(
    _OrgRow(
      key: _kCompanyKey,
      kind: _OrgKind.company,
      level: 0,
      label: kOrgChartCompanyName,
      subtitle: '',
      count: data.totalUsers,
      expandable: true,
    ),
  );
  if (!companyOpen) return rows;

  void walk(Department dept, int level, bool ancestorNameHit) {
    if (q.isNotEmpty && !ancestorNameHit && !_subtreeHasMatch(dept, data, q)) {
      return;
    }
    final nameHit = ancestorNameHit || _deptNameMatches(dept, q);
    final users = data.usersIn(dept);
    final visibleUsers = q.isEmpty || nameHit
        ? users
        : users.where((u) => _userMatches(u, q)).toList();
    final visibleChildren = dept.children
        .where((c) => q.isEmpty || nameHit || _subtreeHasMatch(c, data, q))
        .toList();
    final key = _deptKey(dept.id);
    final canExpand = visibleUsers.isNotEmpty || visibleChildren.isNotEmpty;
    final open = q.isNotEmpty || expanded.contains(key);
    rows.add(
      _OrgRow(
        key: key,
        kind: _OrgKind.dept,
        level: level,
        label: dept.name,
        subtitle: '',
        count: _subtreeUserCount(dept, data),
        expandable: canExpand,
      ),
    );
    if (!open) return;
    for (final child in visibleChildren) {
      walk(child, level + 1, nameHit);
    }
    for (final user in visibleUsers) {
      rows.add(
        _OrgRow(
          key: 'user:${user.userIdx}',
          kind: _OrgKind.user,
          level: level + 1,
          label: user.name,
          subtitle: user.positionNm,
          count: 0,
          expandable: false,
          user: user,
        ),
      );
    }
  }

  for (final dept in data.departments) {
    walk(dept, 1, false);
  }

  final unassigned = q.isEmpty
      ? data.unassigned
      : data.unassigned.where((u) => _userMatches(u, q)).toList();
  if (unassigned.isNotEmpty) {
    final openUnassigned = q.isNotEmpty || expanded.contains(_kUnassignedKey);
    rows.add(
      _OrgRow(
        key: _kUnassignedKey,
        kind: _OrgKind.unassigned,
        level: 1,
        label: '미배정',
        subtitle: '',
        count: unassigned.length,
        expandable: true,
      ),
    );
    if (openUnassigned) {
      for (final user in unassigned) {
        rows.add(
          _OrgRow(
            key: 'user:${user.userIdx}',
            kind: _OrgKind.user,
            level: 2,
            label: user.name,
            subtitle: user.positionNm,
            count: 0,
            expandable: false,
            user: user,
          ),
        );
      }
    }
  }
  return rows;
}

class _OrgTreeRow extends StatelessWidget {
  const _OrgTreeRow({
    required this.row,
    required this.isExpanded,
    required this.onToggle,
    required this.onUserTap,
  });

  final _OrgRow row;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onUserTap;

  @override
  Widget build(BuildContext context) {
    final isUser = row.kind == _OrgKind.user;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUser ? onUserTap : onToggle,
        hoverColor: _kHover,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.0 + row.level * 14.0, 6, 8, 6),
          child: isUser ? _buildUser() : _buildGroup(),
        ),
      ),
    );
  }

  Widget _buildGroup() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: row.expandable
              ? Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: _kMuted,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: row.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                if (row.count > 0)
                  TextSpan(
                    text: '  ${row.count}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kMuted,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUser() {
    final initial = row.label.isEmpty
        ? '?'
        : String.fromCharCode(row.label.runes.first);
    final title = row.subtitle.isEmpty
        ? row.label
        : '${row.label} ${row.subtitle}';
    return Row(
      children: [
        const SizedBox(width: 18),
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF4A4A4A),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kText,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  height: 1.2,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              if (row.subtitle.isNotEmpty)
                Text(
                  row.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: _kMuted,
                    height: 1.3,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
