// 메뉴 dev003 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';

DateTime? dev003ParseYmd(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime dev003DateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// API로 받은 [raw]에 목록 필터 규칙을 적용한다.
List<SalesAreaRow> dev003ApplyClientFilters(
  SalesAreaFilter f,
  List<SalesAreaRow> raw,
) {
  return raw
      .where((row) => kDev003ListRules.every((rule) => rule(f, row)))
      .toList(growable: false);
}

({int total, int configured, int unset}) dev003AreaSummary(List<SalesAreaRow> rows) {
  return (
    total: rows.length,
    configured: rows.where((r) => r.isAreaConfigured).length,
    unset: rows.where((r) => !r.isAreaConfigured).length,
  );
}

final List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> kDev003ListRules =
    <ListFilterRule<SalesAreaFilter, SalesAreaRow>>[
      (s, r) {
        if (s.strategicOpeningOnly) return r.isStrategicOpening;
        return true;
      },
      (s, r) {
        if (s.includeNonFranchise) return true;
        return r.isFranchise;
      },
      (s, r) {
        if (s.includeUnsetArea) return true;
        return r.isAreaConfigured;
      },
      (s, r) {
        if (s.regionCd == '전체') return true;
        return r.region == s.regionCd;
      },
      (s, r) {
        if (s.brandCd == '전체') return true;
        return r.brand == s.brandCd;
      },
      (s, r) {
        final q = s.keyword.trim().toLowerCase();
        if (q.isEmpty) return true;
        return r.salesAreaName.toLowerCase().contains(q) ||
            r.propertyName.toLowerCase().contains(q);
      },
      (s, r) {
        final p = dev003ParseYmd(r.settingDateYmd);
        if (p == null) return true;
        final a = dev003DateOnly(s.rangeStart);
        final b = dev003DateOnly(s.rangeEnd);
        return !p.isBefore(a) && !p.isAfter(b);
      },
    ];
