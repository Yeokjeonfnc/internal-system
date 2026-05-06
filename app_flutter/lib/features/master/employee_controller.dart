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
    this.employeeKeyword = '',
    this.department = '전체',
    this.position = '전체',
  });

  /// 사원명·이메일·휴대전화 통합 검색(부분 일치, OR).
  final String employeeKeyword;
  final String department;
  final String position;

  EmployeeFilter copyWith({
    String? employeeKeyword,
    String? department,
    String? position,
  }) {
    return EmployeeFilter(
      employeeKeyword: employeeKeyword ?? this.employeeKeyword,
      department: department ?? this.department,
      position: position ?? this.position,
    );
  }
}

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeFilter>(
  EmployeeNotifier.new,
);

class EmployeeNotifier extends Notifier<EmployeeFilter> {
  @override
  EmployeeFilter build() => const EmployeeFilter();

  void setEmployeeKeyword(String v) => state = state.copyWith(employeeKeyword: v);
  void setDepartment(String v) => state = state.copyWith(department: v);
  void setPosition(String v) => state = state.copyWith(position: v);
}
