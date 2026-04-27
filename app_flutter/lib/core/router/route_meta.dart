// 라우트별 상단 배너 제목·부모 경로 메타.

import 'package:app_flutter/features/activities/activity_routes.dart';

import 'app_router.dart';

/// 각 라우트의 상단 배너 타이틀/서브타이틀 및 뒤로가기 시 되돌아갈 부모 경로 메타.
///
/// - [title]: 상단 배너에 표시할 제목.
/// - [subtitle]: 타이틀 아래 설명 문구. 없으면 빈 문자열.
/// - [parentPath]: 히스토리가 없을 때 뒤로가기에서 fallback 으로 이동할 경로.
///   null 이면 상위가 없음(홈/루트).
class RouteMeta {
  const RouteMeta({required this.title, this.subtitle = '', this.parentPath});

  final String title;
  final String subtitle;
  final String? parentPath;
}

/// 주어진 경로([path])에 해당하는 [RouteMeta] 를 반환한다.
///
/// 매칭 규칙:
/// 1. [appRouteDefs] 의 `path` 와 정확히 일치 → 해당 def 의 메타 반환.
/// 2. `:param` 을 포함한 동적 라우트의 prefix 와 매칭 (상세 페이지) → 해당 def 의 메타 반환.
/// 3. 모두 실패하면 기본값(루트 타이틀) 반환.
RouteMeta resolveRouteMeta(String path) {
  if (path == AppRoutes.salesAreas) {
    return const RouteMeta(title: '영업지역 관리', parentPath: AppRoutes.dashboard);
  }
  if (path.startsWith('${AppRoutes.salesAreas}/register/')) {
    return const RouteMeta(title: '영업지역 등록', parentPath: AppRoutes.salesAreas);
  }
  for (final def in appRouteDefs) {
    if (def.path == path) {
      return RouteMeta(
        title: def.title,
        subtitle: def.subtitle,
        parentPath: def.parentPath,
      );
    }
  }

  for (final def in appRouteDefs) {
    final prefix = def.dynamicPrefix;
    if (prefix == null) continue;
    if (path.startsWith(prefix) && path.length > prefix.length) {
      return RouteMeta(
        title: def.title,
        subtitle: def.subtitle,
        parentPath: def.parentPath,
      );
    }
  }

  if (path.startsWith(kActivitiesRoot)) {
    if (path == ActivityRoutes.hub) {
      return const RouteMeta(title: '활동 관리', parentPath: AppRoutes.dashboard);
    }
    final title = activityPageTitle(path);
    return RouteMeta(title: title, parentPath: ActivityRoutes.hub);
  }

  return const RouteMeta(title: '역전에프앤씨');
}

/// 뒤로가기에서 `canPop == false` 일 때 이동할 부모 경로.
String? parentPathFor(String currentPath) =>
    resolveRouteMeta(currentPath).parentPath;
