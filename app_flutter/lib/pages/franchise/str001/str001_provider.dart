import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 계약상태는 조건·칩 전체 OR, 그 외 조건은 AND + 부분 일치.
final List<ListFilterRule<StoreFilter, Store>> kStr001ListRules =
    <ListFilterRule<StoreFilter, Store>>[
      (s, r) => storeMatchesContractStatusFilter(
        collectContractStatusFilter(s),
        r,
      ),
      storeMatchesNonContractConditions,
    ];
