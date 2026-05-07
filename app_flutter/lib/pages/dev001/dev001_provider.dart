// 메뉴 dev001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/dev001/dev001_filter.dart';
import 'package:app_flutter/pages/dev001/dev001_model.dart';

final List<ListFilterRule<PartnerFilter, Partner>> kDev001ListRules =
    <ListFilterRule<PartnerFilter, Partner>>[
      (s, r) => s.evaluation == null || r.evaluationStatus == s.evaluation,
      (s, r) => s.pRegion == '전체' || r.pRegion == s.pRegion,
      (s, r) {
        if (s.partnerStatus == '전체') return true;
        return partnerStatusLabelKorean(r.partnerStatus) == s.partnerStatus;
      },
      (s, r) {
        final q = s.partnerKeyword.trim().toLowerCase();
        if (q.isEmpty) return true;
        return r.partnerNm.toLowerCase().contains(q) ||
            r.partnerTel.toLowerCase().contains(q) ||
            r.partnerEmail.toLowerCase().contains(q);
      },
    ];
