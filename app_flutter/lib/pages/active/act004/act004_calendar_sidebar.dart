import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';

class Act004CalendarSidebar extends StatelessWidget {
  const Act004CalendarSidebar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.members,
    required this.teams,
    required this.onDaySelected,
    required this.onMemberVisibilityChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    this.sheetMode = false,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<Act004Member> members;
  final List<Act004CalendarTeam> teams;
  final ValueChanged<DateTime> onDaySelected;
  final void Function(String memberId, bool visible) onMemberVisibilityChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  /// 모바일 필터 시트 — 고정 폭·우측 구분선 없이 전체 폭 사용.
  final bool sheetMode;

  @override
  Widget build(BuildContext context) {
    final filtered = members.where((m) {
      final q = searchQuery.trim();
      if (q.isEmpty) return true;
      return m.name.contains(q);
    }).toList();

    final memberList = _memberListChildren(filtered);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: _MiniMonthCalendar(
            focusedMonth: focusedMonth,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '담당자 검색',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        if (sheetMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: memberList,
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: memberList,
            ),
          ),
      ],
    );

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        border: sheetMode
            ? null
            : const Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: body,
    );

    if (sheetMode) return panel;
    return SizedBox(width: 248, child: panel);
  }

  List<Widget> _memberListChildren(List<Act004Member> filtered) {
    return [
      const _SidebarSectionTitle('내 캘린더'),
      ...filtered.where((m) => m.isSelf).map(
        (m) => _MemberToggleRow(
          member: m,
          checked: m.visible,
          onChanged: (v) => onMemberVisibilityChanged(m.id, v),
        ),
      ),
      if (teams.isNotEmpty) ...[
        const SizedBox(height: 8),
        const _SidebarSectionTitle('열람 가능 팀'),
        ...teams.map(
          (t) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '• ${t.deptNm}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),
      const _SidebarSectionTitle('팀 캘린더'),
      ...filtered.where((m) => !m.isSelf).map(
        (m) => _MemberToggleRow(
          member: m,
          checked: m.visible,
          onChanged: (v) => onMemberVisibilityChanged(m.id, v),
        ),
      ),
    ];
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  const _SidebarSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _MemberToggleRow extends StatelessWidget {
  const _MemberToggleRow({
    required this.member,
    required this.checked,
    required this.onChanged,
  });

  final Act004Member member;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: checked,
                  activeColor: member.color,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = first.weekday;
    final today = DateTime.now();
    final cells = <Widget>[];

    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final isSelected = date.year == selectedDay.year &&
          date.month == selectedDay.month &&
          date.day == selectedDay.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(date),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentRed
                  : isToday
                  ? const Color(0xFFFFE8E9)
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? AppTheme.accentRed
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          act004MonthTitle(focusedMonth),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _WeekdayLabel('월'),
            _WeekdayLabel('화'),
            _WeekdayLabel('수'),
            _WeekdayLabel('목'),
            _WeekdayLabel('금'),
            _WeekdayLabel('토'),
            _WeekdayLabel('일'),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1.15,
          children: cells,
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
