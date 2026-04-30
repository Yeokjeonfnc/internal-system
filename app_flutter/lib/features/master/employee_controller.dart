// 사원관리 — 필터 Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/features/master/employee_model.dart';
import 'package:app_flutter/features/master/user_api_service.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> all();

  /// 부서 필터용 (맨 앞에 `전체`).
  List<String> departmentOptions();

  /// 직급 필터용 (맨 앞에 `전체`).
  List<String> positionOptions();
}

class ApiEmployeeRepository implements EmployeeRepository {
  final UserApiService _apiService = UserApiService();

  @override
  Future<List<Employee>> all() async {
    try {
      return await _apiService.getUsers();
    } catch (e) {
      print('사원 목록 조회 실패: $e');
      return [];
    }
  }

  @override
  List<String> departmentOptions() {
    // TODO: API에서 부서 목록을 가져오도록 수정 필요
    return ['전체'];
  }

  @override
  List<String> positionOptions() {
    // TODO: API에서 직급 목록을 가져오도록 수정 필요 (grp_cd = 60)
    return ['전체'];
  }
}

class InMemoryEmployeeRepository implements EmployeeRepository {
  const InMemoryEmployeeRepository();

  @override
  Future<List<Employee>> all() async => const <Employee>[];

  @override
  List<String> departmentOptions() => const <String>['전체'];

  @override
  List<String> positionOptions() => const <String>['전체'];
}

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => ApiEmployeeRepository(),
);

class EmployeeFilter {
  const EmployeeFilter({
    this.name = '',
    this.department = '전체',
    this.position = '전체',
    this.email = '',
    this.phone = '',
  });

  final String name;
  final String department;
  final String position;
  final String email;
  final String phone;

  EmployeeFilter copyWith({
    String? name,
    String? department,
    String? position,
    String? email,
    String? phone,
  }) {
    return EmployeeFilter(
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeFilter>(
  EmployeeNotifier.new,
);

class EmployeeNotifier extends Notifier<EmployeeFilter> {
  @override
  EmployeeFilter build() => const EmployeeFilter();

  void setName(String v) => state = state.copyWith(name: v);
  void setDepartment(String v) => state = state.copyWith(department: v);
  void setPosition(String v) => state = state.copyWith(position: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
}
