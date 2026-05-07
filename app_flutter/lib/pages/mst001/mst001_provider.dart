// 메뉴 mst001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/mst001/mst001_model.dart';

final List<ListFilterRule<EmployeeFilter, Employee>> kMst001ListRules =
    <ListFilterRule<EmployeeFilter, Employee>>[
      (s, emp) {
        final q = s.employeeKeyword.trim().toLowerCase();
        if (q.isEmpty) return true;
        return emp.name.toLowerCase().contains(q) ||
            emp.email.toLowerCase().contains(q) ||
            emp.mobilePhone.toLowerCase().contains(q);
      },
      (s, emp) =>
          s.department == '전체' || emp.department == s.department,
      (s, emp) => s.position == '전체' || emp.jobTitle == s.position,
    ];
