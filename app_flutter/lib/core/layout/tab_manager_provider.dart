// 상단 멀티 탭(열린 화면)의 목록·동기화·닫기 상태를 Riverpod 으로 관리한다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../router/route_meta.dart';

/// 상단 탭 한 칸.
@immutable
class ManagedTab {
  const ManagedTab({required this.location, required this.title});

  /// `go` 에 넘길 전체 경로 (쿼리 제외).
  final String location;

  /// 탭에 표시할 짧은 제목.
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedTab && location == other.location && title == other.title;

  @override
  int get hashCode => Object.hash(location, title);
}

final tabManagerProvider =
    NotifierProvider<TabManagerNotifier, List<ManagedTab>>(
      TabManagerNotifier.new,
    );

class TabManagerNotifier extends Notifier<List<ManagedTab>> {
  @override
  List<ManagedTab> build() => [];

  /// 방문한 화면 경로 스택(뒤로가기용). 가장 최근 화면이 마지막.
  final List<String> _history = [];
  static const int _kHistoryLimit = 50;

  /// 현재 화면 직전에 방문한 경로. 없으면 null.
  String? previousLocation() =>
      _history.length >= 2 ? _history[_history.length - 2] : null;

  /// 라우트 변경을 이력에 기록한다.
  /// 직전 경로로 되돌아온 경우(뒤로가기)는 스택을 pop, 그 외에는 push.
  void _recordHistory(String location) {
    if (_history.isNotEmpty && _history.last == location) return;
    if (_history.length >= 2 && _history[_history.length - 2] == location) {
      _history.removeLast();
      return;
    }
    _history.add(location);
    if (_history.length > _kHistoryLimit) {
      _history.removeRange(0, _history.length - _kHistoryLimit);
    }
  }

  static bool _isPinned(String location) => location == AppRoutes.dashboard;

  /// 대시보드는 항상 맨 왼쪽(고정 홈 탭), 나머지는 연 순서 유지.
  static List<ManagedTab> canonicalOrder(Iterable<ManagedTab> tabs) {
    ManagedTab? dash;
    final others = <ManagedTab>[];
    for (final t in tabs) {
      if (t.location == AppRoutes.dashboard) {
        dash ??= t;
      } else {
        others.add(t);
      }
    }
    if (dash != null) return [dash, ...others];
    return others;
  }

  String _labelFor(String location) {
    final meta = resolveRouteMeta(location);
    if (location == AppRoutes.dashboard) return '대시보드';
    return meta.title;
  }

  /// 현재 라우트에 맞춰 탭을 추가하거나 제목만 갱신한다.
  void syncWithRoute(String location) {
    _recordHistory(location);
    var list = canonicalOrder(state);
    final label = _labelFor(location);
    final idx = list.indexWhere((t) => t.location == location);
    if (idx >= 0) {
      if (list[idx].title != label) {
        list = [
          ...list.sublist(0, idx),
          ManagedTab(location: location, title: label),
          ...list.sublist(idx + 1),
        ];
        list = canonicalOrder(list);
      }
      if (!listEquals(list, state)) {
        state = list;
      }
      return;
    }
    list = canonicalOrder([
      ...list,
      ManagedTab(location: location, title: label),
    ]);
    state = list;
  }

  /// 탭을 닫는다. [location] 이 현재 화면이면 인접 탭으로 이동한다.
  void closeTab(BuildContext context, String location) {
    if (_isPinned(location)) return;

    state = canonicalOrder(state);
    final current = GoRouterState.of(context).uri.path;
    final i = state.indexWhere((t) => t.location == location);
    if (i < 0) return;

    final newList = List<ManagedTab>.from(state)..removeAt(i);

    if (newList.isEmpty) {
      state = [ManagedTab(location: AppRoutes.dashboard, title: '대시보드')];
      if (current != AppRoutes.dashboard) {
        context.go(AppRoutes.dashboard);
      }
      return;
    }

    final nextIdx = current == location
        ? (i < newList.length ? i : i - 1)
        : null;

    state = canonicalOrder(newList);

    if (nextIdx != null) {
      context.go(state[nextIdx].location);
    }
  }

  void closeAllTabs(BuildContext context) {
    state = const [ManagedTab(location: AppRoutes.dashboard, title: '대시보드')];
    if (GoRouterState.of(context).uri.path != AppRoutes.dashboard) {
      context.go(AppRoutes.dashboard);
    }
  }
}
