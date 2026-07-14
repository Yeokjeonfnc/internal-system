// 물건 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev002/dev002_api.dart';
import 'package:app_flutter/pages/development/dev002/dev002_filter.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/pages/development/dev002/dev002_provider.dart';

abstract class PropertyRepository {
  Future<List<Property>> all();
  Future<Property?> find(int no);
  List<String> regions();
}

class ApiPropertyRepository implements PropertyRepository {
  const ApiPropertyRepository(this._apiService);

  final PropertyApiService _apiService;

  @override
  Future<List<Property>> all() => _apiService.getAllProperties();

  @override
  Future<Property?> find(int no) => _apiService.getProperty(no);

  @override
  List<String> regions() => const <String>['전체'];
}

final propertyApiServiceProvider = Provider<PropertyApiService>(
  (ref) => PropertyApiService(),
);

final propertyCommonCodeApiServiceProvider = Provider<CommonCodeApiService>(
  (ref) => CommonCodeApiService(),
);

final propertyCodeOptionsProvider =
    FutureProvider.family<List<CodeOption>, int>(
      (ref, grpCd) =>
          ref.watch(propertyCommonCodeApiServiceProvider).getCodes(grpCd),
    );

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => ApiPropertyRepository(ref.watch(propertyApiServiceProvider)),
);

final propertyDataProvider = FutureProvider<List<Property>>((ref) async {
  return ref.watch(propertyRepositoryProvider).all();
});

final propertyDetailProvider = FutureProvider.family<Property?, int>((
  ref,
  propIdx,
) async {
  if (propIdx <= 0) return null;
  return ref.watch(propertyRepositoryProvider).find(propIdx);
});

final propertyDocumentsProvider =
    FutureProvider.family<List<PropertyDocument>, int>((ref, propIdx) async {
      if (propIdx <= 0) return const [];
      return ref.watch(propertyApiServiceProvider).getPropertyDocuments(propIdx);
    });

final propertyProvider = NotifierProvider<PropertyNotifier, PropertyFilter>(
  PropertyNotifier.new,
);

class PropertyNotifier extends BaseListNotifier<PropertyFilter, Property> {
  @override
  PropertyFilter build() => const PropertyFilter();

  @override
  AsyncValue<List<Property>> get listAsync => ref.watch(propertyDataProvider);

  @override
  List<ListFilterRule<PropertyFilter, Property>> get ruleList {
    final regionOpts =
        ref.watch(propertyCodeOptionsProvider(20)).valueOrNull ??
        const <CodeOption>[];
    return dev002ListRules(regionOpts);
  }

  void setPropertyKeyword(String v) => state = state.copy(propertyKeyword: v);
  void setOwnership(String v) => state = state.copy(ownership: v);
  void setPropStatus(String v) => state = state.copy(propStatus: v);

  void refresh() {
    ref.invalidate(propertyDataProvider);
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

  void clearRegions() => state = state.copy(clearRegions: true);
}
