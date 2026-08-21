import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/franchise/str001/str001_filter.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';

/// 모든 추가 조건은 AND로 결합하고, 각 값은 부분 일치로 찾는다.
final List<ListFilterRule<StoreFilter, Store>> kStr001ListRules =
    <ListFilterRule<StoreFilter, Store>>[
      (s, r) => storeMatchesContractStatusFilter(s.storeStatus, r),
      (s, r) => s.conditions.every((c) {
        final value = c.value.trim();
        if (value.isEmpty) return true;
        if (c.field == StoreFilterField.contractStatus) {
          return storeMatchesContractStatusCondition(c.value, r);
        }
        final target = switch (c.field) {
          StoreFilterField.storeName => r.storeNm,
          StoreFilterField.storeCode => r.storeCd,
          StoreFilterField.ownerName => r.ownerNm,
          StoreFilterField.phone => r.storeTel,
          StoreFilterField.address => '${r.address} ${r.addressDetail}',
          StoreFilterField.contractStartDate => r.contStartDt,
          StoreFilterField.contractEndDate => r.contEndDt,
          StoreFilterField.contractStatus => '',
          StoreFilterField.supervisor => '${r.svId} ${r.svNm}',
          StoreFilterField.businessNumber => r.businessNumber,
          StoreFilterField.notes => r.notes,
        };
        return target.toLowerCase().contains(value.toLowerCase());
      }),
    ];
