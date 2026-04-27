// 사원관리 — 필터 Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/master/employee_model.dart';

abstract class EmployeeRepository {
  List<Employee> all();

  /// 부서 필터용 (맨 앞에 `전체`).
  List<String> departmentOptions();
}

class InMemoryEmployeeRepository implements EmployeeRepository {
  const InMemoryEmployeeRepository();

  @override
  List<Employee> all() => const <Employee>[];

  @override
  List<String> departmentOptions() => const <String>['전체'];
}

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => const InMemoryEmployeeRepository(),
);

class EmployeeFilter {
  const EmployeeFilter({
    this.name = '',
    this.department = '전체',
    this.email = '',
    this.phone = '',
  });

  final String name;
  final String department;
  final String email;
  final String phone;

  EmployeeFilter copyWith({
    String? name,
    String? department,
    String? email,
    String? phone,
  }) {
    return EmployeeFilter(
      name: name ?? this.name,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeFilter>(
  EmployeeNotifier.new,
);

class EmployeeNotifier extends RuleListNotifier<EmployeeFilter, Employee> {
  @override
  EmployeeFilter build() => const EmployeeFilter();

  @override
  List<Employee> get source => ref.read(employeeRepositoryProvider).all();

  @override
  List<ListFilterRule<EmployeeFilter, Employee>> get rules => [
    (s, r) {
      final q = s.name.trim();
      return q.isEmpty || r.name.contains(q);
    },
    (s, r) {
      if (s.department == '전체') return true;
      return r.department == s.department;
    },
    (s, r) {
      final q = s.email.trim();
      return q.isEmpty || r.email.contains(q);
    },
    (s, r) {
      final q = s.phone.trim();
      return q.isEmpty || r.mobilePhone.contains(q);
    },
  ];

  void setName(String v) => state = state.copyWith(name: v);
  void setDepartment(String v) => state = state.copyWith(department: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
}
