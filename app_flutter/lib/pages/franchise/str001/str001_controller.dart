// 가맹점 목록 필터 상태·목록 소스·문서 탭용 목 데이터를 한곳에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/franchise/str001/str001_api.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';
import 'package:app_flutter/pages/franchise/str001/str001_provider.dart';

// --- Repository (API 연동) ---

abstract class StoreRepository {
  Future<List<Store>> all();
  Future<Store?> find(int storeIdx);
}

class ApiStoreRepository implements StoreRepository {
  ApiStoreRepository(this._apiService);

  final StoreApiService _apiService;

  @override
  Future<List<Store>> all() async {
    // 목록 화면은 실패를 '0건'으로 보여주면 안 된다 — 던져서 에러 화면(다시 시도)까지 가게 한다.
    return await _apiService.getAllStoresOrThrow();
  }

  @override
  Future<Store?> find(int storeIdx) async {
    return await _apiService.getStoreByIndex(storeIdx);
  }
}

final storeApiServiceProvider = Provider<StoreApiService>(
  (ref) => StoreApiService(),
);

final commonCodeApiServiceProvider = Provider<CommonCodeApiService>(
  (ref) => CommonCodeApiService(),
);

final codeOptionsProvider = FutureProvider.family<List<CodeOption>, int>((
  ref,
  grpCd,
) async {
  return ref.watch(commonCodeApiServiceProvider).getCodes(grpCd);
});

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => ApiStoreRepository(ref.watch(storeApiServiceProvider)),
);

/// 지역명 목록 로드 (드롭다운용)
final regionNamesProvider = FutureProvider<List<String>>((ref) async {
  final codes = await ref.watch(commonCodeApiServiceProvider).getCodes(20);
  return ['전체', ...codes.map((e) => e.codeNm)];
});

/// 브랜드명 목록 로드 (드롭다운용)
final brandNamesProvider = FutureProvider<List<String>>((ref) async {
  final codes = await ref.watch(commonCodeApiServiceProvider).getCodes(40);
  return ['전체', ...codes.map((e) => e.codeNm)];
});

/// 특정 가맹점 로드 Provider
final storeDetailProvider = FutureProvider.family<Store?, int>((
  ref,
  storeIdx,
) async {
  if (storeIdx <= 0) return null;
  return await ref.watch(storeRepositoryProvider).find(storeIdx);
});

final storeHistoriesProvider = FutureProvider.autoDispose
    .family<List<HistoryEntry>, int>((ref, storeIdx) async {
      if (storeIdx <= 0) return const <HistoryEntry>[];
      return ref.read(storeApiServiceProvider).getStoreHistories(storeIdx);
    });

final storeDocumentsProvider = FutureProvider.autoDispose
    .family<List<Document>, int>((ref, storeIdx) async {
      if (storeIdx <= 0) return const <Document>[];
      return ref.read(storeApiServiceProvider).getStoreDocuments(storeIdx);
    });

// --- 목록 필터 (Riverpod) ---

final storeProvider = NotifierProvider<StoreNotifier, StoreFilter>(
  StoreNotifier.new,
);

/// 가맹점 데이터 로더 (비동기)
final storeDataProvider = FutureProvider<List<Store>>((ref) async {
  return await ref.watch(storeRepositoryProvider).all();
});

class StoreNotifier extends BaseListNotifier<StoreFilter, Store> {
  @override
  StoreFilter build() {
    return const StoreFilter();
  }

  @override
  AsyncValue<List<Store>> get listAsync => ref.watch(storeDataProvider);

  @override
  List<ListFilterRule<StoreFilter, Store>> get ruleList => kStr001ListRules;

  /// 데이터 새로고침.
  ///
  /// [includeCodes]가 true(새로고침 버튼)면 공통코드·지역·브랜드까지 갱신하고,
  /// 화면 진입 시(배경 갱신)에는 목록만 갱신해 불필요한 왕복 6회를 줄인다.
  void refresh({bool includeCodes = true}) {
    ref.invalidate(storeDataProvider);
    if (!includeCodes) return;
    ref.invalidate(regionNamesProvider);
    ref.invalidate(brandNamesProvider);
    ref.invalidate(codeOptionsProvider(10));
    ref.invalidate(codeOptionsProvider(20));
    ref.invalidate(codeOptionsProvider(30));
    ref.invalidate(codeOptionsProvider(40));
  }

  // Legacy controls are retained for compatibility while the old UI is removed.
  void setStoreKeyword(String value) => state = state.copy(storeKeyword: value);
  void setBrand(String value) => state = state.copy(brandCd: value);
  void toggleRegion(String name) {
    final next = Set<String>.from(state.regionNms);
    next.contains(name) ? next.remove(name) : next.add(name);
    state = state.copy(regionNms: next);
  }

  void clearRegions() => state = state.copy(clearRegions: true);
  void toggleContractStatus(String value) {
    final next = Set<String>.from(state.storeStatus);
    next.contains(value) ? next.remove(value) : next.add(value);
    state = state.copy(storeStatus: next);
  }

  void clearContractStatuses() => state = state.copy(clearStatuses: true);

  void addCondition() {
    state = state.copy(
      conditions: <StoreFilterCondition>[
        ...state.conditions,
        const StoreFilterCondition(
          field: StoreFilterField.storeName,
          value: '',
        ),
      ],
    );
  }

  void updateCondition(int index, StoreFilterCondition value) {
    if (index < 0 || index >= state.conditions.length) return;
    final next = List<StoreFilterCondition>.from(state.conditions);
    next[index] = value;
    state = state.copy(conditions: next);
  }

  void removeCondition(int index) {
    if (index < 0 || index >= state.conditions.length) return;
    final next = List<StoreFilterCondition>.from(state.conditions)
      ..removeAt(index);
    state = state.copy(conditions: next);
  }

  void replaceFilter(StoreFilter value) => state = value;
}
