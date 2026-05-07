// 사원관리(emp001) — 필터·Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/mst001/mst001_api.dart';
import 'package:app_flutter/pages/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/mst001/mst001_model.dart';
import 'package:app_flutter/pages/mst001/mst001_provider.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> all();

  /// 부서 필터용 (맨 앞에 `전체`).
  List<String> departmentOptions();

  /// 직급 필터용 (맨 앞에 `전체`).
  List<String> positionOptions();
}

class ApiEmployeeRepository implements EmployeeRepository {
  final Emp001ApiService _apiService = Emp001ApiService();

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
    return ['전체'];
  }

  @override
  List<String> positionOptions() {
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

final employeeDataProvider = FutureProvider<List<Employee>>((ref) async {
  return ref.watch(employeeRepositoryProvider).all();
});

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeFilter>(
  EmployeeNotifier.new,
);

class EmployeeNotifier extends BaseListNotifier<EmployeeFilter, Employee> {
  @override
  EmployeeFilter build() => const EmployeeFilter();

  @override
  AsyncValue<List<Employee>> get listAsync => ref.watch(employeeDataProvider);

  @override
  List<ListFilterRule<EmployeeFilter, Employee>> get ruleList => kMst001ListRules;

  void setEmployeeKeyword(String v) =>
      state = state.copyWith(employeeKeyword: v);

  void setDepartment(String v) => state = state.copyWith(department: v);

  void setPosition(String v) => state = state.copyWith(position: v);

  void refresh() {
    ref.invalidate(employeeDataProvider);
  }
}
