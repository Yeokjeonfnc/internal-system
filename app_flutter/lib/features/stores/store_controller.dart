// 가맹점 목록 필터 상태·목록 소스·문서 탭용 목 데이터를 한곳에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/data/mock_options.dart';
import 'package:app_flutter/core/data/mock_data_hub.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/stores/store_model.dart';

// --- Repository (목 메모리) ---

abstract class StoreRepository {
  List<Store> all();
  Store? find(String code);
  List<String> brands();
  List<String> regions();
}

class InMemoryStoreRepository implements StoreRepository {
  const InMemoryStoreRepository();

  @override
  List<Store> all() => kMockStores;

  @override
  Store? find(String code) {
    for (final row in kMockStores) {
      if (row.storeCode == code) return row;
    }
    return null;
  }

  @override
  List<String> brands() => kStoreBrandFilterOptions;

  @override
  List<String> regions() => kMockRegionOptions;
}

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => const InMemoryStoreRepository(),
);

abstract class DocumentRepository {
  List<Document> docs(Store store);
}

class InMemoryDocumentRepository implements DocumentRepository {
  const InMemoryDocumentRepository();

  @override
  List<Document> docs(Store store) => kMockDocuments;
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => const InMemoryDocumentRepository(),
);

// --- 목록 필터 (Riverpod) ---

class StoreFilter {
  const StoreFilter({
    this.name = '',
    this.code = '',
    this.brand = '전체',
    this.region = '전체',
    this.statuses = const <StoreStatus>{},
  });

  final String name;
  final String code;
  final String brand;
  /// [Store.storeArea]와 매칭. `전체`면 조건 없음.
  final String region;
  /// 비어 있으면 계약상태 조건 없음(전체). 1개 이상이면 해당 상태들만 OR 매칭.
  final Set<StoreStatus> statuses;

  StoreFilter copy({
    String? name,
    String? code,
    String? brand,
    String? region,
    Set<StoreStatus>? statuses,
    bool clearStatuses = false,
  }) {
    return StoreFilter(
      name: name ?? this.name,
      code: code ?? this.code,
      brand: brand ?? this.brand,
      region: region ?? this.region,
      statuses: clearStatuses ? <StoreStatus>{} : statuses ?? this.statuses,
    );
  }
}

final storeProvider =
    NotifierProvider<StoreNotifier, StoreFilter>(StoreNotifier.new);

class StoreNotifier extends RuleListNotifier<StoreFilter, Store> {
  @override
  StoreFilter build() => const StoreFilter();

  @override
  List<Store> get source => ref.read(storeRepositoryProvider).all();

  @override
  List<ListFilterRule<StoreFilter, Store>> get rules => [
        (s, r) =>
            s.statuses.isEmpty || s.statuses.contains(r.contractStatus),
        (s, r) => s.brand == '전체' || r.brand == s.brand,
        (s, r) => s.region == '전체' || r.storeArea == s.region,
        (s, r) {
          final q = s.name.trim();
          return q.isEmpty || r.storeName.contains(q);
        },
        (s, r) {
          final q = s.code.trim().toLowerCase();
          return q.isEmpty || r.storeCode.toLowerCase().contains(q);
        },
      ];

  void setName(String v) => state = state.copy(name: v);
  void setCode(String v) => state = state.copy(code: v);
  void setBrand(String v) => state = state.copy(brand: v);
  void setRegion(String v) => state = state.copy(region: v);

  void toggleContractStatus(StoreStatus s) {
    final next = Set<StoreStatus>.from(state.statuses);
    if (next.contains(s)) {
      next.remove(s);
    } else {
      next.add(s);
    }
    state = state.copy(statuses: next);
  }

  void clearContractStatuses() {
    state = state.copy(clearStatuses: true);
  }
}
