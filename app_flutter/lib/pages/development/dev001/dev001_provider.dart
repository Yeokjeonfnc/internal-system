// 메뉴 dev001 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/api/code_option.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev001/dev001_filter.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';

/// 공통코드(지역 grp=20)로 `pRegion` 코드를 화면 지역명과 맞춘다.
String dev001PartnerRegionLabel(String pRegion, List<CodeOption> options) {
  if (pRegion.isEmpty) return '';
  for (final o in options) {
    if (o.codeCd == pRegion) return o.codeNm;
  }
  return pRegion;
}

/// DB에 코드·지역명이 섞여 저장된 경우 공통코드 `codeCd` 로 통일한다.
String dev001PartnerRegionCode(String pRegion, List<CodeOption> options) {
  final raw = pRegion.trim();
  if (raw.isEmpty || options.isEmpty) return raw;
  for (final o in options) {
    if (o.codeCd == raw || o.codeNm == raw) return o.codeCd;
  }
  return raw;
}

/// [regionCodeOptions] — `partnerCodeOptionsProvider(20)` 값(로딩 전엔 빈 리스트).
List<ListFilterRule<PartnerFilter, Partner>> dev001ListRules(
  List<CodeOption> regionCodeOptions,
) {
  return <ListFilterRule<PartnerFilter, Partner>>[
    (s, r) => s.evaluation == null || r.evaluationStatus == s.evaluation,
    (s, r) {
      if (s.regionNms.isEmpty) return true;
      if (regionCodeOptions.isEmpty) {
        return s.regionNms.contains(r.pRegion);
      }
      final label = dev001PartnerRegionLabel(r.pRegion, regionCodeOptions);
      return s.regionNms.contains(label) || s.regionNms.contains(r.pRegion);
    },
    (s, r) {
      if (s.partnerStatus == '전체') return true;
      return statusLabelKo(r.partnerStatus) == s.partnerStatus;
    },
    (s, r) {
      final q = s.partnerKeyword.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.partnerNm.toLowerCase().contains(q) ||
          r.partnerTel.toLowerCase().contains(q) ||
          r.partnerEmail.toLowerCase().contains(q);
    },
  ];
}
