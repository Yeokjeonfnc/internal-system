// 물건 목록 필터와 목 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/data/mock_data_hub.dart';
import 'package:app_flutter/core/data/mock_options.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/properties/property_model.dart';

abstract class PropertyRepository {
  List<Property> all();
  Property? find(int no);
  List<String> regions();
}

class InMemoryPropertyRepository implements PropertyRepository {
  const InMemoryPropertyRepository();

  @override
  List<Property> all() => kMockProperties;

  @override
  Property? find(int no) =>
      kMockProperties.where((row) => row.no == no).firstOrNull;

  @override
  List<String> regions() => kMockRegionOptions;
}

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => const InMemoryPropertyRepository(),
);

class PropertyFilter {
  const PropertyFilter({
    this.name = '',
    this.address = '',
    this.region = '전체',
    this.ownership,
  });

  final String name;
  final String address;
  final String region;
  final PropertyOwnership? ownership;

  PropertyFilter copy({
    String? name,
    String? address,
    String? region,
    PropertyOwnership? ownership,
    bool clearOwnership = false,
  }) {
    return PropertyFilter(
      name: name ?? this.name,
      address: address ?? this.address,
      region: region ?? this.region,
      ownership: clearOwnership ? null : ownership ?? this.ownership,
    );
  }
}

final propertyProvider =
    NotifierProvider<PropertyNotifier, PropertyFilter>(PropertyNotifier.new);

class PropertyNotifier extends RuleListNotifier<PropertyFilter, Property> {
  @override
  PropertyFilter build() => const PropertyFilter();

  @override
  List<Property> get source => ref.read(propertyRepositoryProvider).all();

  @override
  List<ListFilterRule<PropertyFilter, Property>> get rules => [
        (s, r) => s.ownership == null || r.ownership == s.ownership,
        (s, r) => s.region == '전체' || r.region == s.region,
        (s, r) {
          final q = s.name.trim();
          return q.isEmpty || r.name.contains(q);
        },
        (s, r) {
          final q = s.address.trim();
          return q.isEmpty || r.address.contains(q);
        },
      ];

  void setName(String v) => state = state.copy(name: v);
  void setAddress(String v) => state = state.copy(address: v);
  void setRegion(String v) => state = state.copy(region: v);
  void setOwnership(PropertyOwnership? v) => state = v == null
      ? state.copy(clearOwnership: true)
      : state.copy(ownership: v);
}
