// 물건 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/dev002/dev002_api.dart';
import 'package:app_flutter/pages/dev002/dev002_filter.dart';
import 'package:app_flutter/pages/dev002/dev002_model.dart';
import 'package:app_flutter/pages/dev002/dev002_provider.dart';

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

final propertyProvider = NotifierProvider<PropertyNotifier, PropertyFilter>(
  PropertyNotifier.new,
);

class PropertyNotifier extends BaseListNotifier<PropertyFilter, Property> {
  @override
  PropertyFilter build() => const PropertyFilter();

  @override
  AsyncValue<List<Property>> get listAsync => ref.watch(propertyDataProvider);

  @override
  List<ListFilterRule<PropertyFilter, Property>> get ruleList =>
      kDev002ListRules;

  void setPropertyKeyword(String v) => state = state.copy(propertyKeyword: v);
  void setRegion(String v) => state = state.copy(region: v);
  void setOwnership(PropertyOwnership? v) => state = v == null
      ? state.copy(clearOwnership: true)
      : state.copy(ownership: v);
  void setStatus(PropertyStatus? v) =>
      state = v == null ? state.copy(clearStatus: true) : state.copy(status: v);

  void refresh() {
    ref.invalidate(propertyDataProvider);
    ref.invalidate(propertyCodeOptionsProvider(20));
  }
}
