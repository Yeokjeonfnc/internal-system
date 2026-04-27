// 영업지역 관리 — 필터·탭·임시 Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'sales_area_model.dart';

class SalesAreaFilter {
  const SalesAreaFilter({
    this.salesAreaName = '',
    this.propertyName = '',
    this.brand = '전체',
    this.region = '전체',
    this.strategicOpeningOnly = false,
    this.includeNonFranchise = false,
    this.includeUnsetArea = false,
    this.rangeStart,
    this.rangeEnd,
  });

  final String salesAreaName;
  final String propertyName;
  final String brand;
  final String region;
  final bool strategicOpeningOnly;
  final bool includeNonFranchise;
  final bool includeUnsetArea;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  SalesAreaFilter copyWith({
    String? salesAreaName,
    String? propertyName,
    String? brand,
    String? region,
    bool? strategicOpeningOnly,
    bool? includeNonFranchise,
    bool? includeUnsetArea,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool clearRange = false,
  }) {
    return SalesAreaFilter(
      salesAreaName: salesAreaName ?? this.salesAreaName,
      propertyName: propertyName ?? this.propertyName,
      brand: brand ?? this.brand,
      region: region ?? this.region,
      strategicOpeningOnly: strategicOpeningOnly ?? this.strategicOpeningOnly,
      includeNonFranchise: includeNonFranchise ?? this.includeNonFranchise,
      includeUnsetArea: includeUnsetArea ?? this.includeUnsetArea,
      rangeStart: clearRange ? null : rangeStart ?? this.rangeStart,
      rangeEnd: clearRange ? null : rangeEnd ?? this.rangeEnd,
    );
  }
}

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

final salesAreaProvider = NotifierProvider<SalesAreaNotifier, SalesAreaFilter>(
  SalesAreaNotifier.new,
);

class SalesAreaNotifier
    extends RuleListNotifier<SalesAreaFilter, SalesAreaRow> {
  @override
  SalesAreaFilter build() {
    final n = DateTime.now();
    final end = DateTime(n.year, n.month, n.day);
    final start = end.subtract(const Duration(days: 30));
    return SalesAreaFilter(rangeStart: start, rangeEnd: end);
  }

  @override
  List<SalesAreaRow> get source => ref.read(salesAreaRepositoryProvider).all();

  @override
  List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> get rules => [
    (s, r) {
      if (s.strategicOpeningOnly) return r.isStrategicOpening;
      return true;
    },
    (s, r) {
      if (s.includeNonFranchise) return true;
      return r.isFranchise;
    },
    (s, r) {
      if (s.includeUnsetArea) return true;
      return r.isAreaConfigured;
    },
    (s, r) {
      if (s.region == '전체') return true;
      return r.region == s.region;
    },
    (s, r) {
      if (s.brand == '전체') return true;
      return r.brand == s.brand;
    },
    (s, r) {
      final q = s.salesAreaName.trim();
      if (q.isEmpty) return true;
      return r.salesAreaName.contains(q);
    },
    (s, r) {
      final q = s.propertyName.trim();
      if (q.isEmpty) return true;
      return r.propertyName.contains(q);
    },
    (s, r) {
      if (s.rangeStart == null || s.rangeEnd == null) return true;
      final p = _parseYmd(r.settingDateYmd);
      if (p == null) return true;
      final a = _dateOnly(s.rangeStart!);
      final b = _dateOnly(s.rangeEnd!);
      return !p.isBefore(a) && !p.isAfter(b);
    },
  ];

  /// 상단 집계 카드(조회·표시 전용) — [getFilteredList]과 동일 조건.
  ({int total, int configured, int unset}) get areaSummaryCounts {
    final rows = getFilteredList();
    return (
      total: rows.length,
      configured: rows.where((r) => r.isAreaConfigured).length,
      unset: rows.where((r) => !r.isAreaConfigured).length,
    );
  }

  void setSalesAreaName(String v) => state = state.copyWith(salesAreaName: v);

  void setPropertyName(String v) => state = state.copyWith(propertyName: v);

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

DateTime? _parseYmd(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
