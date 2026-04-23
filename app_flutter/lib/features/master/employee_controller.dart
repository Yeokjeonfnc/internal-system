// 사원관리 — 필터·목(mock) Repository.

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
  List<Employee> all() => _kMockEmployees;

  @override
  List<String> departmentOptions() {
    final s = <String>{};
    for (final e in _kMockEmployees) {
      s.add(e.department);
    }
    final list = s.toList()..sort();
    return ['전체', ...list];
  }
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

final employeeProvider =
    NotifierProvider<EmployeeNotifier, EmployeeFilter>(EmployeeNotifier.new);

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

const List<Employee> _kMockEmployees = [
  Employee(
    no: 1,
    name: '김민수',
    department: '영업팀',
    jobTitle: '과장',
    mobilePhone: '010-1234-5678',
    email: 'minsu.kim@example.com',
    hireDateYmd: '2019-03-18',
    tagEnabled: true,
  ),
  Employee(
    no: 2,
    name: '이서연',
    department: '개발팀',
    jobTitle: '대리',
    mobilePhone: '010-2345-6789',
    email: 'seoyeon.lee@example.com',
    hireDateYmd: '2021-07-05',
    tagEnabled: false,
  ),
  Employee(
    no: 3,
    name: '박준호',
    department: '경영지원',
    jobTitle: '부장',
    mobilePhone: '010-3456-7890',
    email: 'junho.park@example.com',
    hireDateYmd: '2015-11-02',
    tagEnabled: true,
  ),
  Employee(
    no: 4,
    name: '최유진',
    department: '영업팀',
    jobTitle: '사원',
    mobilePhone: '010-4567-8901',
    email: 'yujin.choi@example.com',
    hireDateYmd: '2023-01-16',
    tagEnabled: false,
  ),
  Employee(
    no: 5,
    name: '정다은',
    department: '인사총무',
    jobTitle: '차장',
    mobilePhone: '010-5678-9012',
    email: 'daeun.jung@example.com',
    hireDateYmd: '2018-09-10',
    tagEnabled: true,
  ),
  Employee(
    no: 6,
    name: '한동욱',
    department: '개발팀',
    jobTitle: '팀장',
    mobilePhone: '010-6789-0123',
    email: 'dongwook.han@example.com',
    hireDateYmd: '2014-05-20',
    tagEnabled: true,
  ),
];
