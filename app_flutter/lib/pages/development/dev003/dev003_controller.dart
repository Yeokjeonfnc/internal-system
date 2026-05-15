// 영업지역 관리 — 목록 API·Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/pages/development/dev003/dev003_api.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/pages/development/dev003/dev003_provider.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/core/api/common_code_api_service.dart';

final dev003DataProvider = FutureProvider<List<SalesAreaRow>>((ref) async {
  return SalesAreaApiService().fetchList();
});

final salesAreaProvider = NotifierProvider<SalesAreaNotifier, SalesAreaFilter>(
  SalesAreaNotifier.new,
);
final salesAreaCommonCodeApiServiceProvider = Provider<CommonCodeApiService>(
  (ref) => CommonCodeApiService(),
);
final salesAreaCodeOptionsProvider =
    FutureProvider.family<List<CodeOption>, int>(
      (ref, grpCd) =>
          ref.watch(salesAreaCommonCodeApiServiceProvider).getCodes(grpCd),
    );

class SalesAreaNotifier extends Notifier<SalesAreaFilter> {
  @override
  SalesAreaFilter build() {
    final r = erpPresetDateRange('전체');
    return SalesAreaFilter(rangeStart: r.$1, rangeEnd: r.$2);
  }

  List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> get ruleList {
    final regionOpts =
        ref.watch(salesAreaCodeOptionsProvider(20)).value ??
        const <CodeOption>[];
    return dev003ListRules(regionOpts);
  }

  void setKeyword(String v) => state = state.copy(keyword: v);

  void setBrandCd(String v) => state = state.copy(brandCd: v);

  void setRegionCd(String v) => state = state.copy(regionCd: v);

  void setStrategicOpeningOnly(bool v) =>
      state = state.copy(strategicOpeningOnly: v);

  void setIncludeNonFranchise(bool v) =>
      state = state.copy(includeNonFranchise: v);

  void setIncludeUnsetArea(bool v) => state = state.copy(includeUnsetArea: v);

  void setDateRange(DateTime start, DateTime end) {
    state = state.copy(rangeStart: start, rangeEnd: end);
  }

  void clearSettingDateRangeToDefault() {
    final r = erpPresetDateRange('전체');
    setDateRange(r.$1, r.$2);
  }

  void toggleRegion(String name) {
    final next = Set<String>.from(state.regionNms);
    if (next.contains(name)) {
      next.remove(name);
    } else {
      next.add(name);
    }
    state = state.copy(regionNms: next);
  }

  void clearRegions() => state = state.copy(regionNms: <String>{});
}
