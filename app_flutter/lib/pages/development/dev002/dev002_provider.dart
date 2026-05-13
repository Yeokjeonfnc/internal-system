// 메뉴 dev002 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/api/code_option.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev002/dev002_filter.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';

/// 공통코드(지역 grp=20)로 [Property.region] 코드를 화면 지역명과 맞춘다.
String dev002PropertyRegionLabel(String region, List<CodeOption> options) {
  if (region.isEmpty) return '';
  for (final o in options) {
    if (o.codeCd == region) return o.codeNm;
  }
  return region;
}

/// [regionCodeOptions] — `propertyCodeOptionsProvider(20)` 값(로딩 전엔 빈 리스트).
List<ListFilterRule<PropertyFilter, Property>> dev002ListRules(
  List<CodeOption> regionCodeOptions,
) {
  return <ListFilterRule<PropertyFilter, Property>>[
    (s, r) => s.region == '전체' || r.region == s.region,
    (s, r) {
      final q = s.propertyKeyword.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q);
    },
    (s, r) {
      if (s.ownership == '전체') return true;
      return ownershipLabelKo(r.ownership) == s.ownership;
    },
    (s, r) {
      if (s.propStatus == '전체') return true;
      return propStatusLabelKo(r.propStatus) == s.propStatus;
    },
  ];
}
