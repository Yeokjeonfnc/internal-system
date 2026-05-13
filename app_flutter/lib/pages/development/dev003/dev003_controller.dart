// 영업지역 관리 — 목록 API·Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';

final dev003DataProvider = FutureProvider<List<SalesAreaRow>>((ref) async {
  return SalesAreaApiService().fetchList();
});

final salesAreaProvider = NotifierProvider<SalesAreaNotifier, SalesAreaFilter>(
  SalesAreaNotifier.new,
);

class SalesAreaNotifier extends Notifier<SalesAreaFilter> {
  @override
  SalesAreaFilter build() {
    final r = erpPresetDateRange('전체');
    return SalesAreaFilter(rangeStart: r.$1, rangeEnd: r.$2);
  }

  void setKeyword(String v) => state = state.copyWith(keyword: v);

  void setBrandCd(String v) => state = state.copyWith(brandCd: v);

  void setRegionCd(String v) => state = state.copyWith(regionCd: v);

  void setStrategicOpeningOnly(bool v) =>
      state = state.copyWith(strategicOpeningOnly: v);

  void setIncludeNonFranchise(bool v) =>
      state = state.copyWith(includeNonFranchise: v);

  void setIncludeUnsetArea(bool v) =>
      state = state.copyWith(includeUnsetArea: v);

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(rangeStart: start, rangeEnd: end);
  }

  void clearSettingDateRangeToDefault() {
    final r = erpPresetDateRange('전체');
    setDateRange(r.$1, r.$2);
  }
}
