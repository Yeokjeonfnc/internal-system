// 가맹점 목록 필터 상태·목록 소스·문서 탭용 목 데이터를 한곳에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/stores/store_model.dart';
import 'package:app_flutter/features/stores/store_api_service.dart';

// --- Repository (API 연동) ---

abstract class StoreRepository {
  Future<List<Store>> all();
  Future<Store?> find(String code);
}

class ApiStoreRepository implements StoreRepository {
  ApiStoreRepository(this._apiService);

  final StoreApiService _apiService;

  @override
  Future<List<Store>> all() async {
    return await _apiService.getAllStores();
  }

  @override
  Future<Store?> find(String code) async {
    return await _apiService.getStoreByCode(code);
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
final storeDetailProvider = FutureProvider.family<Store?, String>((
  ref,
  storeIdx,
) async {
  if (storeIdx.isEmpty) return null;
  return await ref.watch(storeRepositoryProvider).find(storeIdx);
});

final storeHistoriesProvider = FutureProvider.family<List<HistoryEntry>, int>((
  ref,
  storeIdx,
) async {
  if (storeIdx <= 0) return const <HistoryEntry>[];
  return await ref.watch(storeApiServiceProvider).getStoreHistories(storeIdx);
});

abstract class DocumentRepository {
  List<Document> docs(Store store);
}

class InMemoryDocumentRepository implements DocumentRepository {
  const InMemoryDocumentRepository();

  @override
  List<Document> docs(Store store) => const <Document>[];
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => const InMemoryDocumentRepository(),
);

// --- 목록 필터 (Riverpod) ---

class StoreFilter {
  const StoreFilter({
    this.storeNm = '',
    this.storeCd = '',
    this.brandCd = '전체',
    this.regionCd = '전체',
    this.storeStatus = const <String>{},
  });

  final String storeNm;
  final String storeCd;
  final String brandCd;

  /// [Store.storeArea]와 매칭. `전체`면 조건 없음.
  final String regionCd;

  /// 비어 있으면 계약상태 조건 없음(전체). 1개 이상이면 해당 상태들만 OR 매칭.
  final Set<String> storeStatus;

  StoreFilter copy({
    String? storeNm,
    String? storeCd,
    String? brandCd,
    String? regionCd,
    Set<String>? storeStatus,
    bool clearStatuses = false,
  }) {
    return StoreFilter(
      storeNm: storeNm ?? this.storeNm,
      storeCd: storeCd ?? this.storeCd,
      brandCd: brandCd ?? this.brandCd,
      regionCd: regionCd ?? this.regionCd,
      storeStatus: clearStatuses ? <String>{} : storeStatus ?? this.storeStatus,
    );
  }
}

final storeProvider = NotifierProvider<StoreNotifier, StoreFilter>(
  StoreNotifier.new,
);

/// 가맹점 데이터 로더 (비동기)
final storeDataProvider = FutureProvider<List<Store>>((ref) async {
  return await ref.watch(storeRepositoryProvider).all();
});

class StoreNotifier extends RuleListNotifier<StoreFilter, Store> {
  @override
  StoreFilter build() {
    return const StoreFilter();
  }

  @override
  List<Store> get source {
    // storeDataProvider의 데이터를 사용
    final storesAsync = ref.watch(storeDataProvider);
    return storesAsync.maybeWhen(data: (stores) => stores, orElse: () => []);
  }

  /// 데이터 새로고침
  void refresh() {
    ref.invalidate(storeDataProvider);
    ref.invalidate(regionNamesProvider);
    ref.invalidate(brandNamesProvider);
    ref.invalidate(codeOptionsProvider(10));
    ref.invalidate(codeOptionsProvider(20));
    ref.invalidate(codeOptionsProvider(30));
    ref.invalidate(codeOptionsProvider(40));
  }

  @override
  List<ListFilterRule<StoreFilter, Store>> get rules => [
    (s, r) => s.storeStatus.isEmpty || s.storeStatus.contains(r.storeStatusNm),
    (s, r) => s.brandCd == '전체' || r.brandNm == s.brandCd,
    (s, r) => s.regionCd == '전체' || r.region == s.regionCd,
    (s, r) {
      final q = s.storeNm.trim();
      return q.isEmpty || r.storeNm.contains(q);
    },
    (s, r) {
      final q = s.storeCd.trim().toLowerCase();
      return q.isEmpty || r.storeCd.toLowerCase().contains(q);
    },
  ];

  void setName(String v) => state = state.copy(storeNm: v);
  void setCode(String v) => state = state.copy(storeCd: v);
  void setBrand(String v) => state = state.copy(brandCd: v);
  void setRegion(String v) => state = state.copy(regionCd: v);

  void toggleContractStatus(String s) {
    final next = Set<String>.from(state.storeStatus);
    if (next.contains(s)) {
      next.remove(s);
    } else {
      next.add(s);
    }
    state = state.copy(storeStatus: next);
  }

  void clearContractStatuses() {
    state = state.copy(clearStatuses: true);
  }
}
