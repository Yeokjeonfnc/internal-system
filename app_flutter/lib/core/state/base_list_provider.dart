// 목록 필터·소스 행을 묶는 Riverpod 베이스.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 한 줄 필터 규칙: `(state, row)` 가 모두 참이면 행을 통과.
typedef ListFilterRule<F, T> = bool Function(F state, T row);

/// 리스트 + 검색/필터 상태 공통 베이스.
abstract class ListFilterNotifier<F, T> extends Notifier<F> {
  List<T> get source;

  bool matches(T row);

  List<T> filtered() => source.where(matches).toList(growable: false);

  /// 이전 API 호환.
  List<T> getFilteredList() => filtered();
}

/// [rules] 만 나열하면 [matches] 가 자동 구성된다.
abstract class RuleListNotifier<F, T> extends ListFilterNotifier<F, T> {
  List<ListFilterRule<F, T>> get rules;

  @override
  bool matches(T row) {
    for (final r in rules) {
      if (!r(state, row)) return false;
    }
    return true;
  }
}

/// 비동기 목록 소스 + [RuleListNotifier] 공통.
///
/// - [listAsync]: `ref.watch(…DataProvider)` 를 그대로 반환.
/// - [rules]: 화면별 `*_provider.dart` 에서만 선언한 규칙 리스트를 넘긴다.
abstract class BaseListNotifier<F, T> extends RuleListNotifier<F, T> {
  AsyncValue<List<T>> get listAsync;

  List<ListFilterRule<F, T>> get ruleList;

  @override
  List<T> get source =>
      listAsync.maybeWhen(data: (rows) => rows, orElse: () => const []);

  @override
  List<ListFilterRule<F, T>> get rules => ruleList;
}
