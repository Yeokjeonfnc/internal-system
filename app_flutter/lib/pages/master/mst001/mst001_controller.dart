// 사원관리(mst001) — 필터·Repository.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/pages/master/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst001/mst001_provider.dart';

abstract class UserRepository {
  Future<List<User>> all();

  /// 부서 필터용 (맨 앞에 `전체`).
  List<String> departmentOptions();

  /// 직급 필터용 (맨 앞에 `전체`).
  List<String> positionOptions();
}

class ApiUserRepository implements UserRepository {
  final Mst001ApiService _apiService = Mst001ApiService();

  @override
  Future<List<User>> all() async {
    try {
      return await _apiService.getUsers();
    } catch (e) {
      debugPrint('사원 목록 조회 실패: $e');
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

class InMemoryUserRepository implements UserRepository {
  const InMemoryUserRepository();

  @override
  Future<List<User>> all() async => const <User>[];

  @override
  List<String> departmentOptions() => const <String>['전체'];

  @override
  List<String> positionOptions() => const <String>['전체'];
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => ApiUserRepository(),
);

final userDataProvider = FutureProvider<List<User>>((ref) async {
  return ref.watch(userRepositoryProvider).all();
});

/// 사원 상세 API (`GET /users/:userIdx`).
final mst001ApiServiceProvider = Provider<Mst001ApiService>(
  (ref) => Mst001ApiService(),
);

final userDetailProvider = FutureProvider.family<User?, int>((
  ref,
  userIdx,
) async {
  if (userIdx <= 0) return null;
  try {
    return await ref.watch(mst001ApiServiceProvider).getUser(userIdx);
  } catch (_) {
    return null;
  }
});

final userProvider = NotifierProvider<UserNotifier, UserFilter>(
  UserNotifier.new,
);

class UserNotifier extends BaseListNotifier<UserFilter, User> {
  @override
  UserFilter build() => const UserFilter();

  @override
  AsyncValue<List<User>> get listAsync => ref.watch(userDataProvider);

  @override
  List<ListFilterRule<UserFilter, User>> get ruleList =>
      kMst001ListRules;

  void setUserKeyword(String v) =>
      state = state.copyWith(userKeyword: v);

  void setDepartment(String v) => state = state.copyWith(department: v);

  void setPosition(String v) => state = state.copyWith(position: v);

  void refresh() {
    ref.invalidate(userDataProvider);
  }
}
