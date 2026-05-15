// 메뉴 dev003 — [RuleListNotifier]용 필터 규칙만 선언한다.

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/development/dev003/dev003_filter.dart';
import 'package:app_flutter/pages/development/dev003/dev003_model.dart';
import 'package:app_flutter/core/api/code_option.dart';

DateTime? dev003ParseYmd(String s) {
  final parts = s.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// 공통코드(지역 grp=20)로 행의 지역 값(코드 또는 명)을 표시명에 맞춘다.
String dev003SalesAreaRegionLabel(String pRegion, List<CodeOption> options) {
  final key = pRegion.trim();
  if (key.isEmpty) return '';
  for (final o in options) {
    if (o.codeCd == key) return o.codeNm.trim();
  }
  return key;
}

/// 다중 선택 지역 필터 — [dev001]과 동일한 코드/명 매칭 + `전체` 옵션 제외 집합.
bool dev003RegionFilterAllows(
  SalesAreaFilter s,
  SalesAreaRow r,
  List<CodeOption> regionCodeOptions,
) {
  final picksRaw = s.regionNms
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  final picks = picksRaw.where((e) => e != '전체').toSet();
  if (picks.isEmpty) {
    if (s.regionCd == '전체') return true;
    final t = s.regionCd.trim();
    return r.region.trim() == t || r.regionCd.trim() == t;
  }
  final rowNm = r.region.trim();
  final rowCd = r.regionCd.trim();
  if (rowNm.isEmpty && rowCd.isEmpty) return false;
  if (regionCodeOptions.isEmpty) {
    return (rowNm.isNotEmpty && picks.contains(rowNm)) ||
        (rowCd.isNotEmpty && picks.contains(rowCd));
  }
  final candidates = <String>{
    if (rowNm.isNotEmpty) rowNm,
    if (rowCd.isNotEmpty) rowCd,
    if (rowNm.isNotEmpty) dev003SalesAreaRegionLabel(rowNm, regionCodeOptions),
    if (rowCd.isNotEmpty) dev003SalesAreaRegionLabel(rowCd, regionCodeOptions),
  }..removeWhere((e) => e.trim().isEmpty);
  final normalized = candidates.map((e) => e.trim()).toSet();
  for (final p in picks) {
    if (normalized.contains(p)) return true;
  }
  return false;
}

DateTime dev003DateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// API로 받은 [raw]에 목록 필터 규칙을 적용한다.
List<SalesAreaRow> dev003ApplyClientFilters(
  SalesAreaFilter f,
  List<SalesAreaRow> raw,
  List<CodeOption> regionCodeOptions,
) {
  return raw
      .where(
        (row) =>
            kDev003ListRulesCore.every((rule) => rule(f, row)) &&
            dev003RegionFilterAllows(f, row, regionCodeOptions),
      )
      .toList(growable: false);
}

List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> dev003ListRules(
  List<CodeOption> regionCodeOptions,
) {
  return <ListFilterRule<SalesAreaFilter, SalesAreaRow>>[
    (s, r) => dev003RegionFilterAllows(s, r, regionCodeOptions),
  ];
}

({int total, int configured, int unset}) dev003AreaSummary(
  List<SalesAreaRow> rows,
) {
  return (
    total: rows.length,
    configured: rows.where((r) => r.isAreaConfigured).length,
    unset: rows.where((r) => !r.isAreaConfigured).length,
  );
}

/// 지역([dev003RegionFilterAllows]) 제외한 목록 규칙.
final List<ListFilterRule<SalesAreaFilter, SalesAreaRow>> kDev003ListRulesCore =
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
