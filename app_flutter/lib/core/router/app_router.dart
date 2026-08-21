// go_router 기반 앱 라우트 등록.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/pages/active/shared/activity_hub_view.dart';
import 'package:app_flutter/pages/active/act002/act002_view_register.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/active/act001/act001_view_status.dart';
import 'package:app_flutter/pages/active/act002/act002_view.dart';
import 'package:app_flutter/pages/active/act003/act003_view.dart';
import 'package:app_flutter/pages/active/act004/act004_view.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_shell.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';
import 'package:app_flutter/pages/master/mst002/mst002_view.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_view.dart';
import 'package:app_flutter/pages/messenger/msg001/msg001_view.dart';
import 'package:app_flutter/pages/dashboard/dsh001/dsh001_screen.dart';
import 'package:app_flutter/pages/master/mst006/mst006_view.dart';
import 'package:app_flutter/pages/master/mst006/mst006_view_register.dart';
import 'package:app_flutter/pages/master/mst006/mst006_view_detail.dart';
import 'package:app_flutter/pages/master/mst001/mst001_view.dart';
import 'package:app_flutter/pages/master/mst001/mst001_view_register.dart';
import 'package:app_flutter/pages/master/mst001/mst001_view_detail.dart';
import 'package:app_flutter/pages/master/mst004/mst004_view.dart';
import 'package:app_flutter/pages/master/mst003/mst003_view.dart';
import 'package:app_flutter/pages/master/mst005/mst005_view.dart';
import 'package:app_flutter/core/usage_log/usage_log_recorder.dart';
import 'package:app_flutter/pages/development/dev002/dev002_view_detail.dart';
import 'package:app_flutter/pages/development/dev002/dev002_view.dart';
import 'package:app_flutter/pages/development/dev002/dev002_view_register.dart';
import 'package:app_flutter/pages/development/dev001/dev001_view_detail.dart';
import 'package:app_flutter/pages/development/dev001/dev001_view.dart';
import 'package:app_flutter/pages/development/dev003/dev003_view.dart';
import 'package:app_flutter/pages/development/dev003/dev003_view_register.dart';
import 'package:app_flutter/pages/development/dev003/dev003_search_view.dart';
import 'package:app_flutter/pages/franchise/str001/str001_view_detail_tabs.dart';
import 'package:app_flutter/pages/franchise/str001/str001_view.dart';
import 'package:app_flutter/pages/franchise/str001/str001_view_register.dart';
import 'package:app_flutter/pages/franchise/store_entry/store_entry_view.dart';
import 'package:app_flutter/core/active_mst/active_mst_api_paths.dart';
import 'package:app_flutter/core/property_mst/property_mst_write_request.dart';
import 'package:app_flutter/core/store_mst/store_mst_write_request.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';
import 'package:app_flutter/core/auth/change_password_view.dart';
import 'package:app_flutter/core/auth/login_view.dart';
import '../layout/main_frame_layout.dart';
import 'app_data_refresh.dart';
import 'app_route_def.dart';

class AppRoutes {
  static const String dashboard = '/';

  /// 비밀번호 변경(초기화된 계정은 여기로 강제 이동).
  static const String changePassword = '/change-password';
  static const String stores = StoreMstApiPaths.root;
  static const String storeRegister = '${StoreMstApiPaths.root}/new';
  static const String storeDetail = '${StoreMstApiPaths.root}/:storeIdx';
  static const String founders = '/founders';
  static const String founderRegister = '$founders/new';
  static const String founderDetail = '$founders/:partnerIdx';
  static const String properties = PropertyMstApiPaths.root;
  static const String propertyRegister = '${PropertyMstApiPaths.root}/new';
  static const String propertyDetail =
      '${PropertyMstApiPaths.root}/:propertyNo';
  static const String activities = ActiveMstApiPaths.root;
  static const String salesAreas = '/sales-areas';
  static const String salesAreaSearch = '$salesAreas/search';

  /// SPA 전용 — REST `/users` 등과 경로가 다름.
  static const String master = '/master';

  static const String masterUsers = '$master/users';
  static const String masterUsersRegister = '$master/users/new';
  static const String masterUserDetail = '$master/users/:userIdx';
  static const String masterDepartments = '$master/departments';
  static const String masterMenuPermissions = '$master/menu-permissions';
  static const String masterChecklists = '$master/checklists';
  static const String masterUsageLogs = '$master/usage-logs';
  static const String masterOwnerUsers = '$master/owner-users';
  static const String masterOwnerUsersRegister = '$master/owner-users/new';
  static const String masterOwnerUserDetail = '$master/owner-users/:userIdx';

  /// 모바일 전용 — 가맹점 출입 태그.
  static const String storeEntry = '/store-entry';

  /// 게시판 — 가맹점주 전용.
  static const String board = '/board';

  /// 메신저(사내 채팅).
  static const String chat = '/chat';

  /// 전자결재.
  static const String eap = EapRoutes.root;
}

Page<dynamic> _activityApprovalManagementPage(
  BuildContext context,
  GoRouterState state,
) {
  return NoTransitionPage(
    child: Act003View(initialTab: approvalTabIndex(state.uri.path)),
  );
}

Page<dynamic> _eapPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(
    key: ValueKey(state.uri.toString()),
    child: EapShell(path: state.uri.path, query: state.uri.queryParameters),
  );
}

class AppRouteNames {
  static const String changePassword = 'changePassword';

  AppRouteNames._();

  static const String dashboard = 'dashboard';
  static const String stores = 'stores';
  static const String storeRegister = 'storeRegister';
  static const String storeDetail = 'storeDetail';
  static const String founders = 'founders';
  static const String founderRegister = 'founderRegister';
  static const String founderDetail = 'founderDetail';
  static const String properties = 'properties';
  static const String propertyRegister = 'propertyRegister';
  static const String propertyDetail = 'propertyDetail';
  static const String activities = 'activities';
  static const String salesAreas = 'salesAreas';
  static const String salesAreaSearch = 'salesAreaSearch';
  static const String salesAreaRegister = 'salesAreaRegister';
  static const String masterUsers = 'masterUsers';
  static const String masterUsersRegister = 'masterUsersRegister';
  static const String masterUserDetail = 'masterUserDetail';
  static const String masterDepartments = 'masterDepartments';
  static const String masterMenuPermissions = 'masterMenuPermissions';
  static const String masterChecklists = 'masterChecklists';
  static const String masterUsageLogs = 'masterUsageLogs';
  static const String masterOwnerUsers = 'masterOwnerUsers';
  static const String masterOwnerUsersRegister = 'masterOwnerUsersRegister';
  static const String masterOwnerUserDetail = 'masterOwnerUserDetail';
  static const String storeEntry = 'storeEntry';
  static const String board = 'board';
  static const String chat = 'chat';
}

const String _kPropertyDedupNote =
    '*물건명과 주소(상세주소 제외)가 같으면 중복으로 봅니다. 등록 전 확인하세요.';

final List<AppRouteDef> appRouteDefs = <AppRouteDef>[
  AppRouteDef(
    name: AppRouteNames.board,
    path: AppRoutes.board,
    title: '게시판',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) => const NoTransitionPage(child: BoardView()),
  ),
  AppRouteDef(
    name: AppRouteNames.chat,
    path: AppRoutes.chat,
    title: '메신저',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: Msg001View()),
  ),
  AppRouteDef(
    name: AppRouteNames.dashboard,
    path: AppRoutes.dashboard,
    title: '역전에프앤씨',
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: DashboardScreen()),
  ),
  AppRouteDef(
    name: AppRouteNames.stores,
    path: AppRoutes.stores,
    title: '가맹점 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: StoreListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.storeRegister,
    path: AppRoutes.storeRegister,
    title: '가맹점 등록',
    parentPath: AppRoutes.stores,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: StoreRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.storeDetail,
    path: AppRoutes.storeDetail,
    title: '가맹점 상세',
    parentPath: AppRoutes.stores,
    pageBuilder: (context, state) => NoTransitionPage(
      child: StoreDetailView(
        storeIdx: int.tryParse(state.pathParameters['storeIdx'] ?? ''),
      ),
    ),
  ),
  AppRouteDef(
    name: AppRouteNames.founders,
    path: AppRoutes.founders,
    title: '예비창업자 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: PartnerListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.founderRegister,
    path: AppRoutes.founderRegister,
    title: '예비창업자 등록',
    parentPath: AppRoutes.founders,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: PartnerRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.founderDetail,
    path: AppRoutes.founderDetail,
    title: '예비창업자 상세',
    parentPath: AppRoutes.founders,
    pageBuilder: (context, state) {
      final raw = state.pathParameters['partnerIdx'] ?? '';
      final partnerIdx = int.tryParse(raw) ?? -1;
      return NoTransitionPage(child: PartnerDetailView(partnerIdx: partnerIdx));
    },
  ),
  AppRouteDef(
    name: AppRouteNames.properties,
    path: AppRoutes.properties,
    title: '물건 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: PropertyListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.propertyRegister,
    path: AppRoutes.propertyRegister,
    title: '물건 등록',
    subtitle: _kPropertyDedupNote,
    parentPath: AppRoutes.properties,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: PropertyRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.propertyDetail,
    path: AppRoutes.propertyDetail,
    title: '물건 상세',
    subtitle: _kPropertyDedupNote,
    parentPath: AppRoutes.properties,
    pageBuilder: (context, state) {
      final raw = state.pathParameters['propertyNo'] ?? '';
      final propertyNo = int.tryParse(raw) ?? -1;
      return NoTransitionPage(
        child: PropertyDetailView(propertyNo: propertyNo),
      );
    },
  ),
  AppRouteDef(
    name: AppRouteNames.masterUsers,
    path: AppRoutes.masterUsers,
    title: '사원 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: UserListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterUsersRegister,
    path: AppRoutes.masterUsersRegister,
    title: '사원 등록',
    parentPath: AppRoutes.masterUsers,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: UserRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterUserDetail,
    path: AppRoutes.masterUserDetail,
    title: '사원 상세',
    parentPath: AppRoutes.masterUsers,
    pageBuilder: (context, state) {
      final raw = state.pathParameters['userIdx'] ?? '';
      final userIdx = int.tryParse(raw) ?? -1;
      return NoTransitionPage(child: UserDetailView(userIdx: userIdx));
    },
  ),
  AppRouteDef(
    name: AppRouteNames.masterDepartments,
    path: AppRoutes.masterDepartments,
    title: '부서관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: DepartmentView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterMenuPermissions,
    path: AppRoutes.masterMenuPermissions,
    title: '메뉴권한 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: MenuPermissionManagementView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterChecklists,
    path: AppRoutes.masterChecklists,
    title: '체크리스트 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: MasterChecklistManagementView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterUsageLogs,
    path: AppRoutes.masterUsageLogs,
    title: '사용기록 조회',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: UsageLogInquiryView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterOwnerUsers,
    path: AppRoutes.masterOwnerUsers,
    title: '가맹주관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: OwnerUserListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterOwnerUsersRegister,
    path: AppRoutes.masterOwnerUsersRegister,
    title: '가맹점주 등록',
    parentPath: AppRoutes.masterOwnerUsers,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: OwnerUserRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterOwnerUserDetail,
    path: AppRoutes.masterOwnerUserDetail,
    title: '가맹점주 상세',
    parentPath: AppRoutes.masterOwnerUsers,
    pageBuilder: (context, state) {
      final raw = state.pathParameters['userIdx'] ?? '';
      final userIdx = int.tryParse(raw) ?? -1;
      return NoTransitionPage(child: OwnerUserDetailView(userIdx: userIdx));
    },
  ),
];

List<RouteBase> _shellChildRoutes() {
  const storeNested = {
    AppRouteNames.stores,
    AppRouteNames.storeRegister,
    AppRouteNames.storeDetail,
  };
  const propertyNested = {
    AppRouteNames.properties,
    AppRouteNames.propertyRegister,
    AppRouteNames.propertyDetail,
  };
  const salesAreaNested = {
    AppRouteNames.salesAreas,
    AppRouteNames.salesAreaSearch,
    AppRouteNames.salesAreaRegister,
  };
  return [
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRouteNames.dashboard,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: DashboardScreen()),
    ),
    // `/stores` + 자식으로 두어 `goNamed(storeRegister)` 가 등록되도록 한다(형제 단독 경로는 이름 누락 이슈 방지).
    GoRoute(
      path: AppRoutes.stores,
      name: AppRouteNames.stores,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: StoreListView()),
      routes: [
        GoRoute(
          path: 'new',
          name: AppRouteNames.storeRegister,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StoreRegisterView()),
        ),
        GoRoute(
          path: ':storeIdx',
          name: AppRouteNames.storeDetail,
          pageBuilder: (context, state) => NoTransitionPage(
            child: StoreDetailView(
              storeIdx: int.tryParse(state.pathParameters['storeIdx'] ?? ''),
            ),
          ),
        ),
      ],
    ),
    // `/properties` + 자식 — `goNamed(propertyRegister)`·저장 후 목록 복귀(`goNamed(properties)`) 안정화.
    GoRoute(
      path: AppRoutes.properties,
      name: AppRouteNames.properties,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: PropertyListView()),
      routes: [
        GoRoute(
          path: 'new',
          name: AppRouteNames.propertyRegister,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PropertyRegisterView()),
        ),
        GoRoute(
          path: ':propertyNo',
          name: AppRouteNames.propertyDetail,
          pageBuilder: (context, state) {
            final raw = state.pathParameters['propertyNo'] ?? '';
            final propertyNo = int.tryParse(raw) ?? -1;
            return NoTransitionPage(
              child: PropertyDetailView(propertyNo: propertyNo),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.salesAreas,
      name: AppRouteNames.salesAreas,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SalesAreaListView()),
      routes: [
        GoRoute(
          path: 'search',
          name: AppRouteNames.salesAreaSearch,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SalesAreaSearchView()),
        ),
        GoRoute(
          path: 'register',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SalesAreaRegisterView()),
        ),
        GoRoute(
          path: 'register/:rowId',
          name: AppRouteNames.salesAreaRegister,
          pageBuilder: (context, state) {
            final raw = state.pathParameters['rowId'] ?? '';
            final rowId = int.tryParse(raw) ?? -1;
            return NoTransitionPage(child: SalesAreaRegisterView(rowId: rowId));
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.activities,
      name: AppRouteNames.activities,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: ActivityHubView()),
      routes: [
        GoRoute(
          path: 'group/:section',
          pageBuilder: (context, state) {
            final key = state.pathParameters['section'] ?? '';
            return NoTransitionPage(child: ActivityHubView(section: key));
          },
        ),
        GoRoute(
          path: 'status/by-assignee',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ColoredBox(
              color: AppTheme.appSurface,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: ActivityStatusDetailView(initialTab: 0),
              ),
            ),
          ),
        ),
        GoRoute(
          path: 'status/by-store',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ColoredBox(
              color: AppTheme.appSurface,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: ActivityStatusDetailView(initialTab: 1),
              ),
            ),
          ),
        ),
        GoRoute(
          path: 'manage/register',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ActivityRegisterView()),
        ),
        GoRoute(
          path: 'manage/:actIdx',
          pageBuilder: (context, state) {
            final actIdx = int.tryParse(state.pathParameters['actIdx'] ?? '');
            return NoTransitionPage(
              child: ActivityRegisterView(actIdx: actIdx),
            );
          },
        ),
        GoRoute(
          path: 'drafts/:actIdx',
          pageBuilder: (context, state) {
            final actIdx = int.tryParse(state.pathParameters['actIdx'] ?? '');
            return NoTransitionPage(
              child: ActivityRegisterView(actIdx: actIdx),
            );
          },
        ),
        GoRoute(
          path: 'drafts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Act002View(initialTab: 0)),
        ),
        GoRoute(
          path: 'manage',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Act002View(initialTab: 1)),
        ),
        GoRoute(
          path: 'instructions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Act002View(initialTab: 2)),
        ),
        GoRoute(
          path: 'checklist',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Act002View(initialTab: 2)),
        ),
        GoRoute(
          path: 'calendar',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ColoredBox(
              color: AppTheme.appSurface,
              child: const Act004View(),
            ),
          ),
        ),
        GoRoute(
          path: 'approval/activity/:actIdx',
          pageBuilder: (context, state) {
            final actIdx = int.tryParse(state.pathParameters['actIdx'] ?? '');
            return NoTransitionPage(
              child: ActivityRegisterView(actIdx: actIdx),
            );
          },
        ),
        GoRoute(
          path: 'approval/all',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/pending',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/active',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/suggestions',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/instructions',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/checklist',
          pageBuilder: _activityApprovalManagementPage,
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.eap,
      redirect: (context, state) {
        final path = state.uri.path;
        if (path == AppRoutes.eap) {
          return EapRoutes.home;
        }
        if (path == '${AppRoutes.eap}/settings') {
          return EapRoutes.compose;
        }
        const legacyToInbox = {
          'pending',
          'received',
          'cc-pending',
          'scheduled',
        };
        const legacyToSent = {'drafted', 'temp-saved'};
        const legacyToCc = {'cc-read'};
        const legacyToAll = {'approved', 'official'};
        final rest = path.startsWith('${AppRoutes.eap}/')
            ? path.substring('${AppRoutes.eap}/'.length)
            : '';
        if (legacyToInbox.contains(rest)) return EapRoutes.inbox;
        if (legacyToSent.contains(rest)) return EapRoutes.sent;
        if (legacyToCc.contains(rest)) return EapRoutes.cc;
        if (legacyToAll.contains(rest)) return EapRoutes.all;
        return null;
      },
      routes: [
        GoRoute(path: 'home', pageBuilder: _eapPage),
        GoRoute(path: 'settings', pageBuilder: _eapPage),
        GoRoute(path: 'compose', pageBuilder: _eapPage),
        GoRoute(path: 'inbox', pageBuilder: _eapPage),
        GoRoute(path: 'sent', pageBuilder: _eapPage),
        GoRoute(path: 'cc', pageBuilder: _eapPage),
        GoRoute(path: 'all', pageBuilder: _eapPage),
        GoRoute(path: 'forms', pageBuilder: _eapPage),
        GoRoute(path: 'forms/new', pageBuilder: _eapPage),
        GoRoute(path: 'forms/edit/:formCode', pageBuilder: _eapPage),
        GoRoute(path: 'doc/:docId', pageBuilder: _eapPage),
        // 구 경로 — redirect 에서 새 메뉴로 보낸다.
        GoRoute(path: 'pending', pageBuilder: _eapPage),
        GoRoute(path: 'received', pageBuilder: _eapPage),
        GoRoute(path: 'cc-pending', pageBuilder: _eapPage),
        GoRoute(path: 'scheduled', pageBuilder: _eapPage),
        GoRoute(path: 'drafted', pageBuilder: _eapPage),
        GoRoute(path: 'temp-saved', pageBuilder: _eapPage),
        GoRoute(path: 'approved', pageBuilder: _eapPage),
        GoRoute(path: 'cc-read', pageBuilder: _eapPage),
        GoRoute(path: 'official', pageBuilder: _eapPage),
      ],
    ),
    for (final def in appRouteDefs)
      if (def.name != AppRouteNames.dashboard &&
          !storeNested.contains(def.name) &&
          !propertyNested.contains(def.name) &&
          !salesAreaNested.contains(def.name))
        GoRoute(name: def.name, path: def.path, pageBuilder: def.pageBuilder),
  ];
}

late final GoRouter appRouter;

/// [auth]와 동일 인스턴스로 [refreshListenable]을 연결한다. [main]에서 한 번만 호출.
GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      final auth = provider.Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isSessionRestored) {
        return null;
      }
      final isLoggedIn = auth.isLoggedIn;
      final isLoginRoute = state.uri.path == '/login';

      // 로그인되지 않았고 로그인 페이지가 아니면 로그인 페이지로 리다이렉트
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // 초기화된 비밀번호로 로그인한 경우 — 변경 전까지 다른 화면을 열 수 없다.
      final isChangePasswordRoute = state.uri.path == AppRoutes.changePassword;
      if (isLoggedIn && (auth.profile?.mustChangePassword ?? false)) {
        return isChangePasswordRoute ? null : AppRoutes.changePassword;
      }
      // 변경이 끝났는데 아직 변경 화면에 있으면 원래 진입 화면으로 보낸다.
      if (isLoggedIn && isChangePasswordRoute) {
        return auth.firstAllowedPath ?? '/';
      }

      // 이미 로그인했는데 로그인 페이지로 가려고 하면 홈으로 리다이렉트
      if (isLoggedIn && isLoginRoute) {
        final next = auth.firstAllowedPath;
        if (next != null) return next;
        if (!auth.usesMenuPermissions) return '/';
        return null;
      }

      final path = state.uri.path;
      if (isLoggedIn && !isLoginRoute) {
        if (auth.isFranchiseOwner && !auth.canAccessPath(path)) {
          final next = auth.firstAllowedPath;
          if (next != null && next != path) return next;
        } else if (auth.usesMenuPermissions && !auth.canAccessPath(path)) {
          final menuCd = menuCdForPath(path);
          if (menuCd != null && isMenuCreatePath(path)) {
            final list = listRouteForMenuCd(menuCd);
            if (list != null && list != path) {
              return list;
            }
          }
          final next = auth.firstAllowedPath;
          if (next != null && next != path) {
            return next;
          }
        }
      }
      if ((path.startsWith('${StoreMstApiPaths.root}/') ||
              path.startsWith('${AppRoutes.founders}/') ||
              path.startsWith('${PropertyMstApiPaths.root}/')) &&
          state.uri.hasQuery) {
        return Uri(path: path).toString();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: const LoginView()),
      ),
      // 셸(사이드바) 밖에 두어 비밀번호 변경 전에는 메뉴로 못 빠져나가게 한다.
      GoRoute(
        path: AppRoutes.changePassword,
        name: AppRouteNames.changePassword,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: const ChangePasswordView()),
      ),
      GoRoute(
        path: AppRoutes.storeEntry,
        name: AppRouteNames.storeEntry,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StoreEntryView()),
      ),
      ShellRoute(
        builder: (context, state, child) => _RouteDataRefreshBoundary(
          routeKey: state.uri.toString(),
          child: MainFrameLayout(child: child),
        ),
        routes: _shellChildRoutes(),
      ),
    ],
  );
}

class _RouteDataRefreshBoundary extends ConsumerStatefulWidget {
  const _RouteDataRefreshBoundary({
    required this.routeKey,
    required this.child,
  });

  final String routeKey;
  final Widget child;

  @override
  ConsumerState<_RouteDataRefreshBoundary> createState() =>
      _RouteDataRefreshBoundaryState();
}

class _RouteDataRefreshBoundaryState
    extends ConsumerState<_RouteDataRefreshBoundary> {
  @override
  void initState() {
    super.initState();
    ApiReachability.recoveryTick.addListener(_onBackendRecovered);
    Future.microtask(_onRouteEntered);
  }

  @override
  void dispose() {
    ApiReachability.recoveryTick.removeListener(_onBackendRecovered);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RouteDataRefreshBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeKey != widget.routeKey) {
      Future.microtask(_onRouteEntered);
    }
  }

  void _onBackendRecovered() {
    if (!mounted) return;
    refreshAllScreenData(ref);
  }

  void _onRouteEntered() {
    if (!mounted) return;
    // 전체 무효화는 쓰기 작업과 백엔드 복구의 몫이다 — 이동마다 부르면 세션 캐시가
    // 매번 비워져 재진입 화면이 항상 스피너부터 뜨고 무관한 목록까지 다시 내려받는다.
    refreshRouteScreenData(ref, Uri.parse(widget.routeKey).path);
    _recordMenuUsage();
  }

  void _recordMenuUsage() {
    if (!mounted) return;
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) return;
    final path = Uri.parse(widget.routeKey).path;
    UsageLogRecorder.instance.onRouteChanged(
      path: path,
      profile: auth.profile,
      permissionFor: auth.permissionFor,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
