// 메일함 검색·정렬 — **클라이언트 순수 함수**.
//
// 서버에도 `keyword` 파라미터가 있지만 목록은 어차피 전량 로드하므로, 글자를 칠
// 때마다 서버를 때리면 Resend 와 무관한 DB 부하만 늘고 화면은 깜빡인다.
// 받아 둔 목록을 그 자리에서 걸러 즉시 반응하게 한다. 정렬·페이지 나누기도 같은 이유로
// 클라이언트에서 한다(서버 왕복 없이 헤더 한 번 눌러 바로 뒤집히는 편이 낫다).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';

/// 검색 범위 — 다우오피스처럼 "어디에서 찾을지"를 고를 수 있게 한다.
///
/// 전체 검색만 있으면 본문에 흔한 단어가 걸려 결과가 쏟아진다. 반대로 제목만
/// 되면 "그 사람이 보낸 메일"을 못 찾는다. 둘 다 필요하다.
enum MailSearchScope { all, subject, sender, recipient, body }

extension MailSearchScopeX on MailSearchScope {
  String get label => switch (this) {
    MailSearchScope.all => '전체',
    MailSearchScope.subject => '제목',
    MailSearchScope.sender => '보낸사람',
    MailSearchScope.recipient => '받는사람',
    MailSearchScope.body => '본문',
  };

  String get hint => switch (this) {
    MailSearchScope.all => '제목·보낸사람·받는사람·본문 미리보기',
    MailSearchScope.subject => '제목에서 찾기',
    MailSearchScope.sender => '보낸사람 이름 또는 메일 주소',
    MailSearchScope.recipient => '받는사람 이름 또는 메일 주소',
    MailSearchScope.body => '본문 미리보기에서 찾기',
  };
}

extension MailListItemSearchX on MailListItem {
  bool matchesKeyword(String raw) =>
      matchesScopedKeyword(raw, MailSearchScope.all);

  bool matchesScopedKeyword(String raw, MailSearchScope scope) {
    final q = raw.trim();
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    bool has(String v) => v.toLowerCase().contains(lower);

    return switch (scope) {
      MailSearchScope.subject => has(subject),
      MailSearchScope.sender => has(fromEmail) || has(fromNm),
      MailSearchScope.recipient => has(toSummary),
      // 서버가 주는 것은 본문 전체가 아니라 미리보기(snippet)다. 본문 안쪽까지
      // 찾으려면 서버 검색이 필요한데, 그건 백엔드 몫이라 여기서는 미리보기까지만
      // 훑고 화면에서 그 한계를 안내한다.
      MailSearchScope.body => has(snippet),
      MailSearchScope.all =>
        has(subject) ||
            has(fromEmail) ||
            has(fromNm) ||
            has(toSummary) ||
            has(snippet) ||
            has(userId) ||
            statusLabel.contains(q),
    };
  }
}

List<MailListItem> mailItemsMatchingKeyword(
  List<MailListItem> items,
  String keyword, {
  MailSearchScope scope = MailSearchScope.all,
}) {
  final q = keyword.trim();
  if (q.isEmpty) return items;
  return items.where((m) => m.matchesScopedKeyword(q, scope)).toList();
}

/// 정렬 기준.
enum MailSortField { date, sender, subject }

extension MailSortFieldX on MailSortField {
  String get label => switch (this) {
    MailSortField.date => '날짜',
    MailSortField.sender => '보낸사람',
    MailSortField.subject => '제목',
  };
}

/// 정렬 상태 — 기준 + 오름/내림.
@immutable
class MailSortSpec {
  const MailSortSpec({
    this.field = MailSortField.date,
    this.ascending = false,
  });

  /// 기본값은 **최신순**이다. 메일함을 열었을 때 맨 위가 방금 온 메일이어야 한다.
  static const MailSortSpec latestFirst = MailSortSpec();

  final MailSortField field;
  final bool ascending;

  /// 같은 열을 다시 누르면 방향만 뒤집고, 다른 열이면 그 열의 기본 방향으로 간다.
  MailSortSpec toggled(MailSortField next) {
    if (next == field) {
      return MailSortSpec(field: field, ascending: !ascending);
    }
    // 날짜는 최신순(내림), 이름·제목은 가나다순(오름)이 사람이 기대하는 기본값이다.
    return MailSortSpec(
      field: next,
      ascending: next != MailSortField.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MailSortSpec &&
      other.field == field &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}

/// 정렬. **원본 리스트를 건드리지 않는다** — Riverpod 캐시에 들어 있는 리스트를
/// 그 자리에서 sort 하면 다른 화면이 보고 있던 순서까지 바뀐다.
List<MailListItem> sortMailItems(List<MailListItem> items, MailSortSpec spec) {
  final copy = List<MailListItem>.of(items);
  int cmp(MailListItem a, MailListItem b) {
    switch (spec.field) {
      case MailSortField.date:
        final av = a.mailAt;
        final bv = b.mailAt;
        // 날짜 없는 건(수집 중 등)은 방향과 무관하게 항상 뒤로 보낸다.
        if (av == null && bv == null) return 0;
        if (av == null) return 1;
        if (bv == null) return -1;
        return av.compareTo(bv);
      case MailSortField.sender:
        return a.counterpartLabel.toLowerCase().compareTo(
          b.counterpartLabel.toLowerCase(),
        );
      case MailSortField.subject:
        return a.subjectLabel.toLowerCase().compareTo(
          b.subjectLabel.toLowerCase(),
        );
    }
  }

  copy.sort((a, b) {
    final r = cmp(a, b);
    if (r != 0) return spec.ascending ? r : -r;
    // 같은 값이면 mailIdx 로 안정적인 순서를 만든다. 안 하면 다시 그릴 때마다
    // 같은 날짜 메일들의 위아래가 뒤바뀌어 클릭을 놓친다.
    return spec.ascending
        ? a.mailIdx.compareTo(b.mailIdx)
        : b.mailIdx.compareTo(a.mailIdx);
  });
  return copy;
}

/// 페이지당 표시 개수 선택지.
const List<int> kMailPageSizes = <int>[25, 50, 100, 200];

/// 메일함 상단 검색줄 — 범위 + 키워드 + "내 담당 메일만" 토글.
///
/// 담당자 필터를 `userId` 가 아니라 `mine` 으로 표현하는 이유는 서버 쪽과 같다.
/// 쿼리 파라미터 이름 `userId` 는 `AuthTokenFilter` 예약어라 토큰 주인과 다르면
/// 무조건 403 이 떨어진다.
class MailSearchBar extends StatelessWidget {
  const MailSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.mine = false,
    this.onMineChanged,
    this.scope = MailSearchScope.all,
    this.onScopeChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool mine;
  final ValueChanged<bool>? onMineChanged;
  final MailSearchScope scope;
  final ValueChanged<MailSearchScope>? onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterStackedItems(
            items: [
              if (onScopeChanged != null)
                FilterDropdownSlot<MailSearchScope>(
                  label: '검색 범위',
                  value: scope,
                  items: [
                    for (final s in MailSearchScope.values)
                      DropdownMenuItem<MailSearchScope?>(
                        value: s,
                        child: Text(s.label),
                      ),
                  ],
                  onChanged: (v) =>
                      onScopeChanged!.call(v ?? MailSearchScope.all),
                ).toItem(),
              FilterTextSlot(
                label: '키워드',
                hint: scope.hint,
                controller: controller,
                onChanged: onChanged,
              ).toItem(),
            ],
          ),
          if (scope == MailSearchScope.body)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                // 한계를 숨기지 않는다 — "본문 검색인데 왜 안 나오냐"를 막는다.
                '본문 검색은 목록에 내려온 미리보기 범위에서만 찾습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          if (onMineChanged != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: mine,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => onMineChanged!.call(v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => onMineChanged!.call(!mine),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text(
                      '내 담당 메일만 보기',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
