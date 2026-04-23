// 영업지역 관리 — 필터·탭·목(memo) Repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/data/mock/mock_stores.dart'
    show kStoreBrandFilterOptions;
import 'package:app_flutter/core/data/mock_options.dart'
    show kMockRegionOptions;
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
  List<SalesAreaRow> all() => _kMockRows;

  @override
  SalesAreaRow? rowById(int id) {
    for (final r in _kMockRows) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  List<String> brandOptions() {
    return kStoreBrandFilterOptions;
  }

  @override
  List<String> regionOptions() {
    return kMockRegionOptions;
  }
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

const List<SalesAreaRow> _kMockRows = [
  SalesAreaRow(
    id: 1,
    settingDateYmd: '2026-04-20',
    propertyName: '할맥 서울은평구청입구점',
    region: '서울',
    franchiseLabel: '가맹',
    storeName: '할맥 서울은평구청입구점',
    brand: '역전할머니맥주',
    areaSettingLabel: '설정',
    salesAreaName: '할맥 서울은평구청입구점',
    isAreaConfigured: true,
    isStrategicOpening: true,
    isFranchise: true,
  ),
  SalesAreaRow(
    id: 2,
    settingDateYmd: '2026-04-18',
    propertyName: '할맥 청주복대',
    region: '충북',
    franchiseLabel: '가맹',
    storeName: '할맥 청주복대',
    brand: '역전할머니맥주',
    areaSettingLabel: '설정',
    salesAreaName: '할맥 청주복대',
    isAreaConfigured: true,
    isStrategicOpening: false,
    isFranchise: true,
  ),
  SalesAreaRow(
    id: 3,
    settingDateYmd: '2026-04-15',
    propertyName: '할맥 수원영통점',
    region: '경기',
    franchiseLabel: '가맹',
    storeName: '할맥 수원영통점',
    brand: '역전할머니맥주',
    areaSettingLabel: '설정',
    salesAreaName: '할맥 수원영통점',
    isAreaConfigured: true,
    isStrategicOpening: false,
    isFranchise: true,
  ),
  SalesAreaRow(
    id: 4,
    settingDateYmd: '2026-04-10',
    propertyName: '할맥 부천점',
    region: '경기',
    franchiseLabel: '가맹',
    storeName: '할맥 부천점',
    brand: '역전할머니맥주',
    areaSettingLabel: '미설정',
    salesAreaName: ' ',
    isAreaConfigured: false,
    isStrategicOpening: false,
    isFranchise: true,
  ),
  SalesAreaRow(
    id: 5,
    settingDateYmd: '2026-04-02',
    propertyName: '대전 둔산',
    region: '대전',
    franchiseLabel: '비가맹',
    storeName: '테스트 둔산점',
    brand: '역전할머니맥주',
    areaSettingLabel: '미설정',
    salesAreaName: '-',
    isAreaConfigured: false,
    isStrategicOpening: true,
    isFranchise: false,
  ),
  SalesAreaRow(
    id: 6,
    settingDateYmd: '2026-03-25',
    propertyName: '강남역2번',
    region: '서울',
    franchiseLabel: '가맹',
    storeName: '할맥 강남',
    brand: '역전할머니맥주',
    areaSettingLabel: '설정',
    salesAreaName: '강남 중앙',
    isAreaConfigured: true,
    isStrategicOpening: true,
    isFranchise: true,
  ),
];
