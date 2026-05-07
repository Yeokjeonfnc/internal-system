// 메뉴 dev002 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/dev002/dev002_filter.dart';
import 'package:app_flutter/pages/dev002/dev002_model.dart';

final List<ListFilterRule<PropertyFilter, Property>> kDev002ListRules =
    <ListFilterRule<PropertyFilter, Property>>[
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
