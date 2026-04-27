// go_router 기반 앱 라우트 등록.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:app_flutter/features/founders/founder_detail_view.dart';
import 'package:app_flutter/features/founders/founder_list_view.dart';
import 'package:app_flutter/features/master/employee_list_view.dart';
import 'package:app_flutter/features/master/employee_register_view.dart';
import 'package:app_flutter/features/properties/property_detail_view.dart';
import 'package:app_flutter/features/properties/property_list_view.dart';
import 'package:app_flutter/features/properties/property_register_view.dart';
import 'package:app_flutter/features/stores/store_detail_view.dart';
import 'package:app_flutter/features/stores/store_list_view.dart';
import 'package:app_flutter/features/stores/store_register_view.dart';
import 'package:app_flutter/features/activities/activity_approval_management_view.dart';
import 'package:app_flutter/features/activities/activity_hub_view.dart';
import 'package:app_flutter/features/activities/activity_management_view.dart';
import 'package:app_flutter/features/activities/activity_register_view.dart';
import 'package:app_flutter/features/activities/activity_routes.dart';
import 'package:app_flutter/features/activities/activity_status_detail_view.dart';
import 'package:app_flutter/features/sales_area/sales_area_list_view.dart';
import 'package:app_flutter/features/sales_area/sales_area_register_view.dart';
import 'package:app_flutter/features/master/master_management_placeholders.dart';
import 'package:app_flutter/features/master/department_view.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import '../layout/main_frame_layout.dart';
import 'app_data_refresh.dart';
import 'app_route_def.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String stores = '/stores';
  static const String storeRegister = '/stores/new';
  static const String storeDetail = '/stores/:storeIdx';
  static const String founders = '/founders';
  static const String founderRegister = '/founders/new';
  static const String founderDetail = '/founders/:founderNo';
  static const String properties = '/properties';
  static const String propertyRegister = '/properties/new';
  static const String propertyDetail = '/properties/:propertyNo';
  static const String activities = '/activities';
  static const String salesAreas = '/sales-areas';

  static const String masterEmployees = '/master/employees';
  static const String masterEmployeesRegister = '/master/employees/new';
  static const String masterDepartments = '/master/departments';
  static const String masterMenuPermissions = '/master/menu-permissions';
  static const String masterChecklists = '/master/checklists';
}

Page<dynamic> _activityStubPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(
    child: ActivityStubView(title: activityPageTitle(state.uri.path)),
  );
}

Page<dynamic> _activityApprovalManagementPage(
  BuildContext context,
  GoRouterState state,
) {
  return NoTransitionPage(
    child: ActivityApprovalManagementView(
      initialTab: activityApprovalInitialTabForPath(state.uri.path),
    ),
  );
}

class AppRouteNames {
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
  static const String salesAreaRegister = 'salesAreaRegister';
  static const String masterEmployees = 'masterEmployees';
  static const String masterEmployeesRegister = 'masterEmployeesRegister';
  static const String masterDepartments = 'masterDepartments';
  static const String masterMenuPermissions = 'masterMenuPermissions';
  static const String masterChecklists = 'masterChecklists';
}

const String _kPropertyDedupNote =
    '*물건명과 주소(상세주소 제외)가 같으면 중복으로 봅니다. 등록 전 확인하세요.';

final List<AppRouteDef> appRouteDefs = <AppRouteDef>[
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
        storeCd: Uri.decodeComponent(state.pathParameters['storeCd'] ?? ''),
      ),
    ),
  ),
  AppRouteDef(
    name: AppRouteNames.founders,
    path: AppRoutes.founders,
    title: '예비창업자 관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: FounderListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.founderRegister,
    path: AppRoutes.founderRegister,
    title: '예비창업자 등록',
    parentPath: AppRoutes.founders,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: FounderRegisterView()),
  ),
  AppRouteDef(
    name: AppRouteNames.founderDetail,
    path: AppRoutes.founderDetail,
    title: '예비창업자 상세',
    parentPath: AppRoutes.founders,
    pageBuilder: (context, state) {
      final raw = state.pathParameters['founderNo'] ?? '';
      final founderNo = int.tryParse(raw) ?? -1;
      return NoTransitionPage(child: FounderDetailView(founderNo: founderNo));
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
    name: AppRouteNames.masterEmployees,
    path: AppRoutes.masterEmployees,
    title: '사원관리',
    parentPath: AppRoutes.dashboard,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: EmployeeListView()),
  ),
  AppRouteDef(
    name: AppRouteNames.masterEmployeesRegister,
    path: AppRoutes.masterEmployeesRegister,
    title: '사원등록',
    parentPath: AppRoutes.masterEmployees,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: EmployeeRegisterView()),
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
];

List<RouteBase> _shellChildRoutes() {
  const storeNested = {
    AppRouteNames.stores,
    AppRouteNames.storeRegister,
    AppRouteNames.storeDetail,
  };
  const salesAreaNested = {
    AppRouteNames.salesAreas,
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
          path: ':storeCd',
          name: AppRouteNames.storeDetail,
          pageBuilder: (context, state) => NoTransitionPage(
            child: StoreDetailView(
              storeCd: Uri.decodeComponent(
                state.pathParameters['storeCd'] ?? '',
              ),
            ),
          ),
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
          path: 'drafts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityManagementView(initialTab: 0),
          ),
        ),
        GoRoute(
          path: 'manage',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityManagementView(initialTab: 1),
          ),
        ),
        GoRoute(
          path: 'instructions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityManagementView(initialTab: 2),
          ),
        ),
        GoRoute(
          path: 'checklist',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityManagementView(initialTab: 3),
          ),
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
        GoRoute(path: 'approval/instructions', pageBuilder: _activityStubPage),
        GoRoute(
          path: 'approval/suggestions',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/checklist',
          pageBuilder: _activityApprovalManagementPage,
        ),
        GoRoute(
          path: 'approval/checklist-stats',
          pageBuilder: _activityStubPage,
        ),
      ],
    ),
    for (final def in appRouteDefs)
      if (def.name != AppRouteNames.dashboard &&
          !storeNested.contains(def.name) &&
          !salesAreaNested.contains(def.name))
        GoRoute(name: def.name, path: def.path, pageBuilder: def.pageBuilder),
  ];
}

final appRouter = GoRouter(
  redirect: (context, state) {
    final path = state.uri.path;
    if ((path.startsWith('/stores/') ||
            path.startsWith('/founders/') ||
            path.startsWith('/properties/')) &&
        state.uri.hasQuery) {
      return Uri(path: path).toString();
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => _RouteDataRefreshBoundary(
        routeKey: state.uri.toString(),
        child: MainFrameLayout(child: child),
      ),
      routes: _shellChildRoutes(),
    ),
  ],
);

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
    Future.microtask(_refreshAllScreenData);
  }

  @override
  void didUpdateWidget(covariant _RouteDataRefreshBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeKey != widget.routeKey) {
      Future.microtask(_refreshAllScreenData);
    }
  }

  void _refreshAllScreenData() {
    if (!mounted) return;
    refreshAllScreenData(ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
