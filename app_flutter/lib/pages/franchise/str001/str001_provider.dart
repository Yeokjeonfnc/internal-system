// 메뉴 str001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

bool _matchesStoreContractStatus(StoreFilter s, Store r) {
  if (s.storeStatus.isEmpty) return true;
  if (s.storeStatus.contains(r.storeStatusNm)) return true;
  final code = r.storeStatus.trim().toLowerCase();
  for (final label in s.storeStatus) {
    if (label == '신규계약' && code == 'new') return true;
    if (label == '재계약' && code == 'renewal') return true;
    if (label == '양수도' && code == 'transfer') return true;
    if (label == '폐점' && (code == 'closed' || r.closedYn)) return true;
  }
  return false;
}

/// 가맹점 목록 필터 규칙.
final List<ListFilterRule<StoreFilter, Store>> kStr001ListRules =
    <ListFilterRule<StoreFilter, Store>>[
      _matchesStoreContractStatus,
      (s, r) =>
          s.brandCd == '전체' ||
          r.brandNm == s.brandCd ||
          r.brandCd == s.brandCd,
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
