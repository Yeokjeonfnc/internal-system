// 물건 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/properties/property_api_service.dart';
import 'package:app_flutter/features/properties/property_model.dart';

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

class PropertyFilter {
  const PropertyFilter({
    this.propertyKeyword = '',
    this.region = '전체',
    this.ownership,
    this.status,
  });

  /// 물건명·주소 통합 검색(부분 일치, OR).
  final String propertyKeyword;
  final String region;
  final PropertyOwnership? ownership;
  final PropertyStatus? status;

  PropertyFilter copy({
    String? propertyKeyword,
    String? region,
    PropertyOwnership? ownership,
    PropertyStatus? status,
    bool clearOwnership = false,
    bool clearStatus = false,
  }) {
    return PropertyFilter(
      propertyKeyword: propertyKeyword ?? this.propertyKeyword,
      region: region ?? this.region,
      ownership: clearOwnership ? null : ownership ?? this.ownership,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}

final propertyProvider = NotifierProvider<PropertyNotifier, PropertyFilter>(
  PropertyNotifier.new,
);

class PropertyNotifier extends RuleListNotifier<PropertyFilter, Property> {
  @override
  PropertyFilter build() => const PropertyFilter();

  @override
  List<Property> get source {
    final propertiesAsync = ref.watch(propertyDataProvider);
    return propertiesAsync.maybeWhen(data: (rows) => rows, orElse: () => []);
  }

  @override
  List<ListFilterRule<PropertyFilter, Property>> get rules => [
    (s, r) => s.ownership == null || r.ownership == s.ownership,
    (s, r) => s.status == null || r.status == s.status,
    (s, r) => s.region == '전체' || r.region == s.region,
    (s, r) {
      final q = s.propertyKeyword.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q);
    },
  ];

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
