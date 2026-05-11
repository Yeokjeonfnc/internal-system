// 메뉴 mst001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/master/mst001/mst001_filter.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

final List<ListFilterRule<UserFilter, User>> kMst001ListRules =
    <ListFilterRule<UserFilter, User>>[
      (s, u) {
        final q = s.userKeyword.trim().toLowerCase();
        if (q.isEmpty) return true;
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.mobilePhone.toLowerCase().contains(q);
      },
      (s, u) => s.department == '전체' || u.department == s.department,
      (s, u) => s.position == '전체' || u.positionNm == s.position,
    ];
