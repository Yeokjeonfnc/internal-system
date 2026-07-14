import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/master/mst006/mst006_filter.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';

final List<ListFilterRule<OwnerUserFilter, OwnerUser>> kMst006ListRules =
    <ListFilterRule<OwnerUserFilter, OwnerUser>>[
      (s, u) {
        final q = s.keyword.trim().toLowerCase();
        if (q.isEmpty) return true;
        return u.ownerName.toLowerCase().contains(q) ||
            u.storeNm.toLowerCase().contains(q) ||
            u.userId.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.mobilePhone.toLowerCase().contains(q);
      },
    ];
