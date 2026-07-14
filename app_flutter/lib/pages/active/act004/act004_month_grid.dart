import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/act004/act004_model.dart';

class Act004MonthGrid extends StatelessWidget {
  const Act004MonthGrid({
    super.key,
    required this.focusedMonth,
    required this.monthData,
    required this.members,
    required this.viewerUserIdx,
    required this.onDayDoubleTap,
    this.onDayTap,
    this.colorDotsOnly = false,
  });

  final DateTime focusedMonth;
  final Act004MonthResponse monthData;
  final List<Act004Member> members;
  final int viewerUserIdx;
  final ValueChanged<DateTime> onDayDoubleTap;
  final ValueChanged<DateTime>? onDayTap;

  /// 모바일 등 좁은 화면 — 가맹점명 없이 담당자 색 점만 표시.
  final bool colorDotsOnly;

  bool get _showAssigneeOnChip {
    if (members.length > 1) return true;
    return members.any((m) => m.userIdx != viewerUserIdx);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final leading = first.weekday - 1;
    final today = DateTime.now();
    final memberColor = {for (final m in members) m.userIdx: m.color};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WeekdayHeaderRow(),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(colorDotsOnly ? 4 : 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: colorDotsOnly ? 4 : 6,
              crossAxisSpacing: colorDotsOnly ? 4 : 6,
              childAspectRatio: colorDotsOnly ? 1.0 : 0.82,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leading) {
                return const SizedBox.shrink();
              }
              final day = index - leading + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final items = monthData.itemsOn(date);
              return _DayCell(
                day: day,
                isToday: isToday,
                items: items,
                memberColor: memberColor,
                showAssignee: _showAssigneeOnChip,
                colorDotsOnly: colorDotsOnly,
                onTap: onDayTap != null ? () => onDayTap!(date) : null,
                onDoubleTap: () => onDayDoubleTap(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.items,
    required this.memberColor,
    required this.showAssignee,
    this.colorDotsOnly = false,
    this.onTap,
    required this.onDoubleTap,
  });

  final int day;
  final bool isToday;
  final List<Act004StoreItem> items;
  final Map<int, Color> memberColor;
  final bool showAssignee;
  final bool colorDotsOnly;
  final VoidCallback? onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday ? AppTheme.accentRed : const Color(0xFFE2E8F0),
            width: isToday ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            colorDotsOnly ? 4 : 6,
            colorDotsOnly ? 4 : 6,
            colorDotsOnly ? 4 : 6,
            colorDotsOnly ? 3 : 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: colorDotsOnly ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppTheme.accentRed : const Color(0xFF475569),
                ),
              ),
              if (colorDotsOnly)
                Expanded(
                  child: items.isEmpty
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 3,
                            runSpacing: 3,
                            children: [
                              for (final item in items)
                                _PlanColorDot(
                                  color:
                                      memberColor[item.assigneeUserIdx] ??
                                      act004ColorForUserIdx(
                                        item.assigneeUserIdx,
                                      ),
                                  completed: item.completed,
                                ),
                            ],
                          ),
                        ),
                )
              else ...[
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _StoreChip(
                            item: item,
                            showAssignee: showAssignee,
                            color:
                                memberColor[item.assigneeUserIdx] ??
                                act004ColorForUserIdx(item.assigneeUserIdx),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanColorDot extends StatelessWidget {
  const _PlanColorDot({required this.color, required this.completed});

  final Color color;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: completed ? act004CompletedChipBg(color) : color,
        shape: BoxShape.circle,
        border: completed
            ? Border.all(color: act004CompletedChipBorder(color), width: 1.2)
            : null,
      ),
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({
    required this.item,
    required this.color,
    required this.showAssignee,
  });

  final Act004StoreItem item;
  final Color color;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final visited = item.completed;
    final bg = visited
        ? act004CompletedChipBg(color)
        : color.withValues(alpha: 0.18);
    final fg = visited ? kAct004CompletedTextColor : const Color(0xFF1E3A5F);
    final chipText = act004CalendarChipText(item, showAssignee: showAssignee);
    return Tooltip(
      message: [
        if (visited) '방문 완료',
        if (item.assigneeUserName.isNotEmpty) item.assigneeUserName,
        item.storeLabel,
      ].join('\n'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: visited
              ? Border.all(color: act004CompletedChipBorder(color), width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            if (visited)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.check_circle,
                  size: 11,
                  color: kAct004CompletedTextColor,
                ),
              ),
            Expanded(
              child: Text(
                chipText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
