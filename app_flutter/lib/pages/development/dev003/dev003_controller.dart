// 영업지역 관리 — 필터·탭·임시 Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/dev003_provider.dart';

abstract class SalesAreaRepository {
  List<SalesAreaRow> all();

  /// [id]에 해당하는 목록 행. 없으면 null.
  SalesAreaRow? rowById(int id);

  List<String> brandOptions();
  List<String> regionOptions();
}

class InMemorySalesAreaRepository implements SalesAreaRepository {
  const InMemorySalesAreaRepository();

  @override
  List<SalesAreaRow> all() => const <SalesAreaRow>[];

  @override
  SalesAreaRow? rowById(int id) => null;

  @override
  List<String> brandOptions() => const <String>['전체'];

  @override
  List<String> regionOptions() => const <String>['전체'];
}

final salesAreaRepositoryProvider = Provider<SalesAreaRepository>(
  (ref) => const InMemorySalesAreaRepository(),
);

final dev003DataProvider = FutureProvider<List<SalesAreaRow>>((ref) async {
  return ref.watch(salesAreaRepositoryProvider).all();
});

final salesAreaProvider = NotifierProvider<SalesAreaNotifier, SalesAreaFilter>(
  SalesAreaNotifier.new,
);

class SalesAreaNotifier extends BaseListNotifier<SalesAreaFilter, SalesAreaRow> {
  @override
  SalesAreaFilter build() {
    final n = DateTime.now();
    final end = DateTime(n.year, n.month, n.day);
    final start = end.subtract(const Duration(days: 30));
    return SalesAreaFilter(rangeStart: start, rangeEnd: end);
  }

  @override
  AsyncValue<List<SalesAreaRow>> get listAsync => ref.watch(dev003DataProvider);

  @override
  List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> get ruleList =>
      kDev003ListRules;

  /// 상단 집계 카드(조회·표시 전용) — [getFilteredList]과 동일 조건.
  ({int total, int configured, int unset}) get areaSummaryCounts {
    final rows = getFilteredList();
    return (
      total: rows.length,
      configured: rows.where((r) => r.isAreaConfigured).length,
      unset: rows.where((r) => !r.isAreaConfigured).length,
    );
  }

  void setSalesAreaKeyword(String v) =>
      state = state.copyWith(salesAreaKeyword: v);

  void setBrand(String v) => state = state.copyWith(brand: v);

  void setRegion(String v) => state = state.copyWith(region: v);

  void setStrategicOpeningOnly(bool v) =>
      state = state.copyWith(strategicOpeningOnly: v);

  void setIncludeNonFranchise(bool v) =>
      state = state.copyWith(includeNonFranchise: v);

  void setIncludeUnsetArea(bool v) =>
      state = state.copyWith(includeUnsetArea: v);

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(rangeStart: start, rangeEnd: end);
  }

  /// 필터에서 설정일자 항목을 끌 때 — 최근 1개월(활동 목록과 동일 기본).
  void clearSettingDateRangeToDefault() {
    final n = DateTime.now();
    final end = DateTime(n.year, n.month, n.day);
    setDateRange(end.subtract(const Duration(days: 30)), end);
  }
}
