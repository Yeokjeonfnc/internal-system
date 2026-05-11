// 메뉴 str001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 가맹점 목록 필터 규칙.
final List<ListFilterRule<StoreFilter, Store>> kStr001ListRules =
    <ListFilterRule<StoreFilter, Store>>[
      (s, r) =>
          s.storeStatus.isEmpty || s.storeStatus.contains(r.storeStatusNm),
      (s, r) => s.brandCd == '전체' || r.brandNm == s.brandCd,
      (s, r) => s.regionNms.isEmpty || s.regionNms.contains(r.region),
      (s, r) {
        final q = s.storeKeyword.trim();
        if (q.isEmpty) return true;
        final ql = q.toLowerCase();
        return r.storeNm.toLowerCase().contains(ql) ||
            r.storeCd.toLowerCase().contains(ql) ||
            r.ownerNm.toLowerCase().contains(ql);
      },
    ];
