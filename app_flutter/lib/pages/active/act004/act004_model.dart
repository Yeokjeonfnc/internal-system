import 'package:flutter/material.dart';

import 'package:app_flutter/core/activity_plan/activity_plan_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

const List<Color> kAct004MemberPalette = [
  Color(0xFFFFB74D),
  Color(0xFFF48FB1),
  Color(0xFF81C784),
  Color(0xFF64B5F6),
  Color(0xFFCE93D8),
  Color(0xFF4DB6AC),
  Color(0xFFA1887F),
  Color(0xFF9575CD),
];

Color act004ColorForIndex(int index) =>
    kAct004MemberPalette[index % kAct004MemberPalette.length];

Color act004ColorForUserIdx(int userIdx) =>
    act004ColorForIndex(userIdx % kAct004MemberPalette.length);

Color act004DarkenColor(Color color, [double amount = 0.38]) {
  return Color.lerp(color, const Color(0xFF1E293B), amount) ?? color;
}

/// 방문 완료 칩 — 담당자 고유색을 더 진하게.
Color act004CompletedChipBg(Color memberColor) =>
    Color.alphaBlend(memberColor.withValues(alpha: 0.52), Colors.white);

Color act004CompletedChipBorder(Color memberColor) =>
    act004DarkenColor(memberColor, 0.22);

const Color kAct004CompletedTextColor = Color(0xFF111827);

class Act004Member {
  const Act004Member({
    required this.userIdx,
    required this.name,
    required this.color,
    this.deptNm = '',
    this.isSelf = false,
    this.visible = true,
  });

  final int userIdx;
  final String name;
  final Color color;
  final String deptNm;
  final bool isSelf;
  final bool visible;

  String get id => userIdx.toString();

  Act004Member copyWith({bool? visible}) {
    return Act004Member(
      userIdx: userIdx,
      name: name,
      color: color,
      deptNm: deptNm,
      isSelf: isSelf,
      visible: visible ?? this.visible,
    );
  }

  factory Act004Member.fromCalendarMemberJson(
    Map<String, dynamic> map,
    int paletteIndex,
  ) {
    return Act004Member(
      userIdx: map.jsonInt(ActivityPlanApiJsonKeys.userIdx),
      name: map.jsonString(ActivityPlanApiJsonKeys.userName),
      deptNm: map.jsonString(ActivityPlanApiJsonKeys.deptNm),
      isSelf: map[ActivityPlanApiJsonKeys.selfUser] == true,
      color: act004ColorForIndex(paletteIndex),
    );
  }
}

class Act004CalendarTeam {
  const Act004CalendarTeam({
    required this.deptIdx,
    required this.deptNm,
    this.granted = false,
  });

  final int deptIdx;
  final String deptNm;
  final bool granted;

  factory Act004CalendarTeam.fromJson(Map<String, dynamic> map) {
    return Act004CalendarTeam(
      deptIdx: map.jsonInt(ActivityPlanApiJsonKeys.deptIdx),
      deptNm: map.jsonString(ActivityPlanApiJsonKeys.deptNm),
      granted: map[ActivityPlanApiJsonKeys.granted] == true,
    );
  }
}

class Act004CalendarContext {
  const Act004CalendarContext({
    required this.viewerUserIdx,
    required this.viewerUserName,
    this.viewerDeptIdx,
    this.viewerDeptNm = '',
    this.teams = const [],
    this.members = const [],
  });

  final int viewerUserIdx;
  final String viewerUserName;
  final int? viewerDeptIdx;
  final String viewerDeptNm;
  final List<Act004CalendarTeam> teams;
  final List<Act004Member> members;

  factory Act004CalendarContext.fromJson(Map<String, dynamic> map) {
    final teamsRaw = map[ActivityPlanApiJsonKeys.teams];
    final membersRaw = map[ActivityPlanApiJsonKeys.members];
    final teams = teamsRaw is List
        ? teamsRaw
              .whereType<Map<String, dynamic>>()
              .map(Act004CalendarTeam.fromJson)
              .toList()
        : const <Act004CalendarTeam>[];
    final members = membersRaw is List
        ? membersRaw
              .whereType<Map<String, dynamic>>()
              .toList()
              .asMap()
              .entries
              .map((e) => Act004Member.fromCalendarMemberJson(e.value, e.key))
              .toList()
        : const <Act004Member>[];
    return Act004CalendarContext(
      viewerUserIdx: map.jsonInt(ActivityPlanApiJsonKeys.viewerUserIdx),
      viewerUserName: map.jsonString(ActivityPlanApiJsonKeys.viewerUserName),
      viewerDeptIdx: asJsonIntOpt(map[ActivityPlanApiJsonKeys.viewerDeptIdx]),
      viewerDeptNm: map.jsonString(ActivityPlanApiJsonKeys.viewerDeptNm),
      teams: teams,
      members: members,
    );
  }
}

class Act004StoreItem {
  const Act004StoreItem({
    required this.storeIdx,
    required this.storeLabel,
    required this.assigneeUserIdx,
    this.assigneeUserName = '',
    this.planned = false,
    this.completed = false,
  });

  final int storeIdx;
  final String storeLabel;
  final int assigneeUserIdx;
  final String assigneeUserName;
  final bool planned;
  final bool completed;

  factory Act004StoreItem.fromJson(Map<String, dynamic> map) {
    return Act004StoreItem(
      storeIdx: map.jsonInt(ActivityPlanApiJsonKeys.storeIdx),
      storeLabel: map.jsonString(ActivityPlanApiJsonKeys.storeLabel),
      assigneeUserIdx: map.jsonInt(ActivityPlanApiJsonKeys.assigneeUserIdx),
      assigneeUserName: map.jsonString(
        ActivityPlanApiJsonKeys.assigneeUserName,
      ),
      planned: map[ActivityPlanApiJsonKeys.planned] == true,
      completed: map[ActivityPlanApiJsonKeys.completed] == true,
    );
  }
}

class Act004MonthDay {
  const Act004MonthDay({required this.planDate, this.items = const []});

  final DateTime planDate;
  final List<Act004StoreItem> items;

  factory Act004MonthDay.fromJson(Map<String, dynamic> map) {
    final raw = map[ActivityPlanApiJsonKeys.items];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(Act004StoreItem.fromJson)
              .toList()
        : const <Act004StoreItem>[];
    return Act004MonthDay(
      planDate: _parseDate(map[ActivityPlanApiJsonKeys.planDate]),
      items: items,
    );
  }
}

class Act004MonthResponse {
  const Act004MonthResponse({this.days = const []});

  final List<Act004MonthDay> days;

  factory Act004MonthResponse.fromJson(Map<String, dynamic> map) {
    final raw = map[ActivityPlanApiJsonKeys.days];
    final days = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(Act004MonthDay.fromJson)
              .toList()
        : const <Act004MonthDay>[];
    return Act004MonthResponse(days: days);
  }

  List<Act004StoreItem> itemsOn(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final day in days) {
      final d = DateTime(
        day.planDate.year,
        day.planDate.month,
        day.planDate.day,
      );
      if (d == key) return day.items;
    }
    return const [];
  }
}

class Act004DayDetail {
  const Act004DayDetail({
    required this.planDate,
    required this.assigneeUserIdx,
    this.assigneeUserName = '',
    this.canEdit = false,
    this.plannedStores = const [],
    this.completedStores = const [],
  });

  final DateTime planDate;
  final int assigneeUserIdx;
  final String assigneeUserName;
  final bool canEdit;
  final List<Act004StoreItem> plannedStores;
  final List<Act004StoreItem> completedStores;

  factory Act004DayDetail.fromJson(Map<String, dynamic> map) {
    final plannedRaw = map[ActivityPlanApiJsonKeys.plannedStores];
    final completedRaw = map[ActivityPlanApiJsonKeys.completedStores];
    return Act004DayDetail(
      planDate: _parseDate(map[ActivityPlanApiJsonKeys.planDate]),
      assigneeUserIdx: map.jsonInt(ActivityPlanApiJsonKeys.assigneeUserIdx),
      assigneeUserName: map.jsonString(
        ActivityPlanApiJsonKeys.assigneeUserName,
      ),
      canEdit: map[ActivityPlanApiJsonKeys.canEdit] == true,
      plannedStores: plannedRaw is List
          ? plannedRaw
                .whereType<Map<String, dynamic>>()
                .map(Act004StoreItem.fromJson)
                .toList()
          : const [],
      completedStores: completedRaw is List
          ? completedRaw
                .whereType<Map<String, dynamic>>()
                .map(Act004StoreItem.fromJson)
                .toList()
          : const [],
    );
  }
}

class ActivityPlanDaySaveBody {
  const ActivityPlanDaySaveBody({
    required this.planDate,
    required this.storeIdxs,
  });

  final DateTime planDate;
  final List<int> storeIdxs;

  Map<String, dynamic> toJson() => {
    ActivityPlanApiJsonKeys.planDate: _formatDate(planDate),
    ActivityPlanApiJsonKeys.storeIdxs: storeIdxs,
  };
}

class TeamViewPermissionRow {
  const TeamViewPermissionRow({
    required this.targetDeptIdx,
    required this.targetDeptNm,
    this.canView = false,
  });

  final int targetDeptIdx;
  final String targetDeptNm;
  final bool canView;

  TeamViewPermissionRow copyWith({bool? canView}) {
    return TeamViewPermissionRow(
      targetDeptIdx: targetDeptIdx,
      targetDeptNm: targetDeptNm,
      canView: canView ?? this.canView,
    );
  }

  factory TeamViewPermissionRow.fromJson(Map<String, dynamic> map) {
    return TeamViewPermissionRow(
      targetDeptIdx: map.jsonInt(ActivityPlanApiJsonKeys.targetDeptIdx),
      targetDeptNm: map.jsonString(ActivityPlanApiJsonKeys.targetDeptNm),
      canView: map[ActivityPlanApiJsonKeys.canView] == true,
    );
  }
}

String act004StoreLabel(String brandNm, String storeNm) {
  final brand = brandNm.trim();
  final name = storeNm.trim();
  if (brand.isEmpty) return name;
  if (name.isEmpty) return brand;
  return '$brand · $name';
}

/// 캘린더 칩용 — 브랜드 접두어 제거 후 가맹점명만.
String act004StoreNameOnly(String storeLabel) {
  final idx = storeLabel.indexOf('·');
  if (idx >= 0) return storeLabel.substring(idx + 1).trim();
  return storeLabel.trim();
}

/// 캘린더 칩 한 줄 — 팀 캘린더·방문 완료일 때 담당자 이름을 앞에 붙임.
String act004CalendarChipText(
  Act004StoreItem item, {
  required bool showAssignee,
}) {
  final store = act004StoreNameOnly(item.storeLabel);
  final showName =
      item.completed || (showAssignee && item.assigneeUserName.isNotEmpty);
  if (!showName || item.assigneeUserName.isEmpty) return store;
  return store;
}

/// `store_mst.sv_id` 표시 — 이름(`sv_nm`)이 있으면 함께 표기.
String act004SvLabel({required String svId, String svNm = ''}) {
  final id = svId.trim();
  final nm = svNm.trim();
  if (id.isEmpty && nm.isEmpty) return '';
  if (nm.isEmpty) return id;
  if (id.isEmpty) return nm;
  return '$nm ($id)';
}

bool act004StoreMatchesKeyword({
  required String keyword,
  required String brandNm,
  required String storeNm,
  required String svId,
  String svNm = '',
}) {
  final q = keyword.trim().toLowerCase();
  if (q.isEmpty) return true;
  final haystack = [
    act004StoreLabel(brandNm, storeNm),
    svId,
    svNm,
  ].join(' ').toLowerCase();
  return haystack.contains(q);
}

String act004MonthTitle(DateTime month) => '${month.year}년 ${month.month}월';

String act004DayTitle(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일';

DateTime _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    final parsed = DateTime.parse(raw);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
  return DateTime.now();
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
