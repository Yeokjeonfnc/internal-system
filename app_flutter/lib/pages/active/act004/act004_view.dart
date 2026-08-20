import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/pages/active/act004/act004_api.dart';
import 'package:app_flutter/pages/active/act004/act004_calendar_sidebar.dart';
import 'package:app_flutter/pages/active/act004/act004_day_dialog.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';
import 'package:app_flutter/pages/active/act004/act004_month_grid.dart';

class Act004View extends StatefulWidget {
  const Act004View({super.key});

  @override
  State<Act004View> createState() => _Act004ViewState();
}

class _Act004ViewState extends State<Act004View> {
  final _api = Act004Api();
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  List<Act004Member> _members = [];
  List<Act004CalendarTeam> _teams = [];
  Act004MonthResponse _monthData = const Act004MonthResponse();
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  int? get _viewerUserIdx =>
      provider.Provider.of<AuthProvider>(context, listen: false).profile?.userIdx;

  String get _userId =>
      provider.Provider.of<AuthProvider>(context, listen: false).userId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  bool _memberVisible(int userIdx) {
    for (final m in _members) {
      if (m.userIdx == userIdx) return m.visible;
    }
    return true;
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
    _reload();
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    setState(() => _focusedMonth = next);
    _reload();
  }

  void _onMemberVisibility(String id, bool visible) {
    setState(() {
      _members = _members
          .map((m) => m.id == id ? m.copyWith(visible: visible) : m)
          .toList();
    });
    _reload();
  }

  Future<void> _reload() async {
    final viewerIdx = _viewerUserIdx;
    if (viewerIdx == null) {
      setState(() {
        _loading = false;
        _error = '로그인 사용자 정보가 없습니다.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctx = await _api.fetchCalendarContext(viewerIdx);
      final members = (ctx?.members ?? [])
          .map((m) => m.copyWith(visible: _memberVisible(m.userIdx)))
          .toList();
      final visibleIdxs = members
          .where((m) => m.visible)
          .map((m) => m.userIdx)
          .toList();
      // 담당자를 전부 해제했는데 필터를 비워 보내면 서버가 '조건 없음'으로 읽어
      // 열람 가능한 전원 일정을 돌려준다 — 그럴 때는 조회하지 않고 비운다.
      // (담당자 목록 자체가 없는 경우는 걸 조건이 없으므로 기존대로 전체 조회)
      final month = members.isNotEmpty && visibleIdxs.isEmpty
          ? const Act004MonthResponse()
          : await _api.fetchMonthPlans(
              viewerUserIdx: viewerIdx,
              year: _focusedMonth.year,
              month: _focusedMonth.month,
              assigneeUserIdxs: visibleIdxs.isEmpty ? null : visibleIdxs,
            );
      if (!mounted) return;
      setState(() {
        _teams = ctx?.teams ?? [];
        _members = members;
        _monthData = month;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '활동 계획을 불러오지 못했습니다. DB 마이그레이션 적용 여부를 확인하세요.';
      });
    }
  }

  Future<void> _openDayDialog(DateTime date) async {
    final viewerIdx = _viewerUserIdx;
    if (viewerIdx == null) return;
    setState(() => _selectedDay = date);
    // 본인을 숨겨 두면 다이얼로그가 본인 섹션을 못 찾아 canEdit=false 가 되고
    // 자기 계획조차 저장할 수 없다 — 표시 여부와 무관하게 본인은 항상 넘긴다.
    final dialogMembers = _members
        .where((m) => m.visible || m.userIdx == viewerIdx)
        .toList();
    final saved = await showAct004DayDialog(
      context,
      viewerUserIdx: viewerIdx,
      createdBy: _userId,
      planDate: date,
      members: dialogMembers,
    );
    if (saved == true) await _reload();
  }

  Act004CalendarSidebar _buildSidebar({bool sheetMode = false}) {
    return Act004CalendarSidebar(
      sheetMode: sheetMode,
      focusedMonth: _focusedMonth,
      selectedDay: _selectedDay,
      members: _members,
      teams: _teams,
      searchQuery: _searchQuery,
      onSearchChanged: (v) => setState(() => _searchQuery = v),
      onDaySelected: (d) {
        setState(() {
          _selectedDay = d;
          if (d.month != _focusedMonth.month || d.year != _focusedMonth.year) {
            _focusedMonth = DateTime(d.year, d.month, 1);
            _reload();
          }
        });
      },
      onMemberVisibilityChanged: _onMemberVisibility,
    );
  }

  Future<void> _openSidebarSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) {
        final maxH = MediaQuery.sizeOf(sheetCtx).height * 0.88;
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '캘린더 · 담당자',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '닫기',
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                      child: Act004CalendarSidebar(
                        sheetMode: true,
                        focusedMonth: _focusedMonth,
                        selectedDay: _selectedDay,
                        members: _members,
                        teams: _teams,
                        searchQuery: _searchQuery,
                        onSearchChanged: (v) {
                          setState(() => _searchQuery = v);
                          sheetSetState(() {});
                        },
                        onDaySelected: (d) {
                          setState(() {
                            _selectedDay = d;
                            if (d.month != _focusedMonth.month ||
                                d.year != _focusedMonth.year) {
                              _focusedMonth = DateTime(d.year, d.month, 1);
                              _reload();
                            }
                          });
                          sheetSetState(() {});
                        },
                        onMemberVisibilityChanged: (id, visible) {
                          _onMemberVisibility(id, visible);
                          sheetSetState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthPane({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthToolbar(
          focusedMonth: _focusedMonth,
          compact: compact,
          onOpenSidebar: compact ? _openSidebarSheet : null,
          visibleMemberCount: _members.where((m) => m.visible).length,
          totalMemberCount: _members.length,
          onToday: _goToday,
          onPrev: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        Expanded(
          child: Act004MonthGrid(
            focusedMonth: _focusedMonth,
            monthData: _monthData,
            members: _members.where((m) => m.visible).toList(),
            viewerUserIdx: _viewerUserIdx ?? 0,
            colorDotsOnly: compact,
            onDayTap: compact ? _openDayDialog : null,
            onDayDoubleTap: _openDayDialog,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final bodyHeight = compact
        ? (MediaQuery.sizeOf(context).height - 120).clamp(400.0, 900.0)
        : (MediaQuery.sizeOf(context).height - 148).clamp(520.0, 900.0);
    final hPad = compact ? 8.0 : AppDimensions.listScreenHPadding;

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          hPad,
          compact ? 8 : 16,
          hPad,
          AppDimensions.listScreenBottomPadding,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppDimensions.contentMaxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                child: SizedBox(
                  height: bodyHeight,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : compact
                      ? _buildMonthPane(compact: true)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSidebar(),
                            Expanded(child: _buildMonthPane(compact: false)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({
    required this.focusedMonth,
    required this.onToday,
    required this.onPrev,
    required this.onNext,
    this.compact = false,
    this.onOpenSidebar,
    this.visibleMemberCount = 0,
    this.totalMemberCount = 0,
  });

  final DateTime focusedMonth;
  final VoidCallback onToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool compact;
  final VoidCallback? onOpenSidebar;
  final int visibleMemberCount;
  final int totalMemberCount;

  Widget _sidebarButton() {
    return SelectionContainer.disabled(
      child: OutlinedButton.icon(
        onPressed: onOpenSidebar,
        icon: const Icon(Icons.people_outline_rounded, size: 18),
        label: Text(
          totalMemberCount > 0
              ? '담당자 ($visibleMemberCount/$totalMemberCount)'
              : '담당자',
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentRed,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _monthNavRow() {
    return Row(
      children: [
        SelectionContainer.disabled(
          child: OutlinedButton(
            onPressed: onToday,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: 8,
              ),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('오늘', style: TextStyle(fontSize: 13)),
          ),
        ),
        IconButton(
          tooltip: '이전 달',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 22),
        ),
        IconButton(
          tooltip: '다음 달',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 22),
        ),
        Expanded(
          child: Text(
            act004MonthTitle(focusedMonth),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '월',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: compact && onOpenSidebar != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sidebarButton(),
                  const SizedBox(height: 6),
                  _monthNavRow(),
                ],
              )
            : Row(
                children: [
                  if (onOpenSidebar != null) ...[
                    _sidebarButton(),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: _monthNavRow()),
                ],
              ),
      ),
    ),
    );
  }
}
