// 조직도 — 부서 트리 + 사원 목록을 한 번만 읽는다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_repo.dart';

const kOrgChartCompanyName = '역전에프앤씨';

class OrgChartSnapshot {
  const OrgChartSnapshot({
    required this.departments,
    required this.usersByDept,
    required this.unassigned,
    required this.totalUsers,
  });

  final List<Department> departments;
  final Map<int, List<User>> usersByDept;
  final List<User> unassigned;
  final int totalUsers;

  List<User> usersIn(Department dept) {
    final idx = int.tryParse(dept.id);
    if (idx == null) return const [];
    return usersByDept[idx] ?? const [];
  }
}

final orgChartDataProvider = FutureProvider<OrgChartSnapshot>((ref) async {
  final depts = await DepartmentRepository().all();
  final raw = await ref.watch(userRepositoryProvider).all();
  final users = raw.where((u) => u.ownerYn != OwnerYn.yes).toList();

  final knownIds = <int>{};
  void collect(Department d) {
    final id = int.tryParse(d.id);
    if (id != null) knownIds.add(id);
    for (final child in d.children) {
      collect(child);
    }
  }

  for (final d in depts) {
    collect(d);
  }

  final byDept = <int, List<User>>{};
  final unassigned = <User>[];
  for (final user in users) {
    final idx = user.deptIdx;
    if (idx != null && knownIds.contains(idx)) {
      byDept.putIfAbsent(idx, () => <User>[]).add(user);
    } else {
      unassigned.add(user);
    }
  }
  for (final list in byDept.values) {
    list.sort((a, b) => a.name.compareTo(b.name));
  }
  unassigned.sort((a, b) => a.name.compareTo(b.name));

  return OrgChartSnapshot(
    departments: depts,
    usersByDept: byDept,
    unassigned: unassigned,
    totalUsers: users.length,
  );
});
