// 단일 라우트 선언 타입(AppRouteDef) 및 GoRoute 빌더.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 앱에서 다루는 단일 라우트에 대한 선언.
///
/// `GoRoute` 의 name/path/pageBuilder 뿐만 아니라 상단 배너 타이틀과
/// 부모 경로(뒤로가기 fallback) 같은 "메타" 정보를 같은 곳에 모아, 라우트
/// 추가 시 한 위치만 수정하도록 한다.
class AppRouteDef {
  const AppRouteDef({
    required this.name,
    required this.path,
    required this.title,
    required this.pageBuilder,
    this.subtitle = '',
    this.parentPath,
  });

  /// `go_router` 의 name (= `AppRouteNames.*`).
  final String name;

  /// `go_router` 의 path (= `AppRoutes.*`). `:param` 플레이스홀더를 포함할 수 있다.
  final String path;

  /// 상단 배너에 표시할 제목.
  final String title;

  /// 타이틀 아래에 표시할 보조 설명. 없으면 빈 문자열.
  final String subtitle;

  /// `canPop == false` 일 때 이동할 부모 경로. 최상위(대시보드) 는 null.
  final String? parentPath;

  /// 실제 화면을 만들어주는 `GoRoute.pageBuilder` 와 동일한 시그니처.
  final Page<dynamic> Function(BuildContext context, GoRouterState state)
  pageBuilder;

  /// 동적 경로인 경우 `:param` 직전까지의 prefix (뒤에 `/` 포함).
  ///
  /// 예: `/stores/:storeIdx` → `/stores/`. 정적 경로면 `null`.
  /// [resolveRouteMeta] 에서 상세 화면 prefix 매칭에 사용한다.
  String? get dynamicPrefix {
    final idx = path.indexOf('/:');
    if (idx == -1) return null;
    return path.substring(0, idx + 1);
  }
}
