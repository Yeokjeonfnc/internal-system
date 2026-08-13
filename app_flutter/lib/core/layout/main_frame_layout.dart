// 사이드바·상단 멀티 탭·페이지 배너를 포함한 ERP 메인 껍데기 레이아웃이다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/layout/app_mobile_only.dart';
import 'package:app_flutter/core/layout/app_shell_top_banner.dart';

import '../router/app_router.dart';
import '../router/route_meta.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';
import '../theme/app_colors.dart';
import '../theme/shell_tab_chrome.dart';
import '../auth/auth_provider.dart';
import '../menu/menu_codes.dart';
import '../auth/user_profile_dialog.dart';
import '../widgets/common/common_alert_dialog.dart';
import '../widgets/common/common_notification_sheet.dart';
import 'tab_manager_provider.dart';

class MainFrameLayout extends ConsumerStatefulWidget {
  const MainFrameLayout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainFrameLayout> createState() => _MainFrameLayoutState();
}

class _MainFrameLayoutState extends ConsumerState<MainFrameLayout> {
  String? _lastSyncedLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).uri.path;
    if (_lastSyncedLocation == loc) return;
    _lastSyncedLocation = loc;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tabManagerProvider.notifier).syncWithRoute(loc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final meta = resolveRouteMeta(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = useCompactErpLayoutForWidth(constraints.maxWidth);

        if (compact) {
          return Scaffold(
            drawer: Drawer(
              width: 280,
              backgroundColor: AppTheme.sidebarBackground,
              child: SafeArea(
                child: _SidebarNavigation(
                  currentPath: location,
                  inDrawer: true,
                  onAfterNavigate: () {
                    final scaffold = Scaffold.maybeOf(context);
                    if (scaffold != null && scaffold.isDrawerOpen) {
                      scaffold.closeDrawer();
                    }
                  },
                ),
              ),
            ),
            body: Builder(
              builder: (bodyContext) => _MainShellBody(
                location: location,
                meta: meta,
                compact: true,
                onOpenDrawer: () => Scaffold.of(bodyContext).openDrawer(),
                child: widget.child,
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _SidebarNavigation(currentPath: location),
              Expanded(
                child: _MainShellBody(
                  location: location,
                  meta: meta,
                  compact: false,
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 지도(HtmlElementView)와 SelectionArea 가 충돌하는 화면.
bool _shellDisablesTextSelection(String location) {
  return location == AppRoutes.salesAreas ||
      location == AppRoutes.salesAreaSearch ||
      location.startsWith('${AppRoutes.salesAreas}/register/') ||
      location == ActivityRoutes.calendar;
}

/// 상단 탭·배너·본문 영역(데스크톱 Row 오른쪽 / 모바일 Scaffold body).
class _MainShellBody extends ConsumerWidget {
  const _MainShellBody({
    required this.location,
    required this.meta,
    required this.child,
    required this.compact,
    this.onOpenDrawer,
  });

  final String location;
  final RouteMeta meta;
  final Widget child;
  final bool compact;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 데스크톱: 히스토리(열린 화면) 탭 줄은 유지, 제목 배너(대분류 바)만 제거.
            // 컴팩트(모바일): 드로어를 열 햄버거·뒤로가기가 필요해 배너를 유지한다.
            if (!compact) _ShellTabStrip(currentPath: location),
            if (compact)
              _ShellTopBanner(
                meta: meta,
                currentPath: location,
                compact: compact,
                onOpenDrawer: onOpenDrawer,
                onBack: () => _shellNavigateBack(context, ref, location),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: compact ? 0 : 14),
                child: _shellDisablesTextSelection(location)
                    ? child
                    : SelectionArea(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 브라우저형으로 열린 화면을 나열하는 상단 **히스토리 탭 줄**.
///
/// 2026 리디자인: 화이트 바 + 헤어라인 하단 보더, 활성 탭은 잉크블랙 라벨 +
/// 하단 레드 언더라인. (제목 배너는 제거됨 — 이 줄이 유일한 상단 크롬.)
class _ShellTabStrip extends ConsumerWidget {
  const _ShellTabStrip({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabManagerProvider);
    final notifier = ref.read(tabManagerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: SizedBox(
        height: ShellTabChrome.tabStripHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _ShellTabChip(
                        tab: tabs[i],
                        selected: tabs[i].location == currentPath,
                        closable: tabs[i].location != AppRoutes.dashboard,
                        onSelect: () {
                          if (tabs[i].location != currentPath) {
                            context.go(tabs[i].location);
                          }
                        },
                        onClose: () =>
                            notifier.closeTab(context, tabs[i].location),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (tabs.any((tab) => tab.location != AppRoutes.dashboard))
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                child: Center(
                  child: Tooltip(
                    message: '열린 탭 모두 닫기',
                    child: IconButton(
                      onPressed: () => notifier.closeAllTabs(context),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      color: AppTheme.textMuted,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.04),
                        hoverColor: Colors.black.withValues(alpha: 0.07),
                        minimumSize: const Size(30, 30),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 히스토리 탭 한 칸 — 활성: 잉크 라벨 + 하단 2px 레드 언더라인 / 비활성: 뮤트.
class _ShellTabChip extends StatelessWidget {
  const _ShellTabChip({
    required this.tab,
    required this.selected,
    required this.closable,
    required this.onSelect,
    required this.onClose,
  });

  final ManagedTab tab;
  final bool selected;
  final bool closable;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppTheme.accentRed : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onSelect,
            hoverColor: ShellTabChrome.inactiveHoverFill,
            splashColor: Colors.black.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, closable ? 2 : 12, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: selected
                        ? ShellTabChrome.tabTitleMaxWidthActive
                        : ShellTabChrome.tabTitleMaxWidthInactive,
                  ),
                  child: Text(
                    tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.textPrimary
                          : ShellTabChrome.inactiveLabel,
                      fontSize: 13,
                      letterSpacing: -0.15,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (closable)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 14),
              color: ShellTabChrome.inactiveIcon,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(26, 26),
                padding: EdgeInsets.zero,
                hoverColor: Colors.black.withValues(alpha: 0.05),
              ),
              tooltip: '탭 닫기',
            ),
        ],
      ),
    );
  }
}

class _ShellTopBanner extends StatelessWidget {
  const _ShellTopBanner({
    required this.meta,
    required this.currentPath,
    required this.onBack,
    this.compact = false,
    this.onOpenDrawer,
  });

  final RouteMeta meta;
  final String currentPath;
  final VoidCallback onBack;
  final bool compact;
  final VoidCallback? onOpenDrawer;

  bool get _isDashboard => currentPath == AppRoutes.dashboard;

  @override
  Widget build(BuildContext context) {
    return AppShellTopBanner(
      title: meta.title,
      subtitle: meta.subtitle,
      compact: compact,
      onOpenDrawer: onOpenDrawer,
      backIcon: _isDashboard ? Icons.home_rounded : Icons.arrow_back_rounded,
      backTooltip: _isDashboard ? '홈' : '뒤로',
      onBack: _isDashboard ? null : onBack,
      trailing: _isDashboard && !compact
          ? OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('새로고침'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.tableHeaderBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          : null,
    );
  }
}

/// 상단 뒤로가기 버튼 처리.
///
/// 1. 방문 이력(직전에 보던 화면)이 있으면 그 화면으로 돌아간다.
/// 2. 브라우저/내비게이션 스택에 이전 페이지가 있으면 그걸로 pop 한다.
/// 3. 둘 다 없으면 [parentPathFor] 로 부모 경로로 이동한다.
void _shellNavigateBack(
  BuildContext context,
  WidgetRef ref,
  String currentPath,
) {
  final previous = ref.read(tabManagerProvider.notifier).previousLocation();
  if (previous != null && previous != currentPath) {
    context.go(previous);
    return;
  }

  final router = GoRouter.of(context);
  final fallback = parentPathFor(currentPath);
  if (currentPath.startsWith(kActivitiesRoot) && fallback != null) {
    context.go(fallback);
    return;
  }
  if (router.canPop()) {
    router.pop();
    return;
  }
  if (fallback != null) {
    context.go(fallback);
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    required this.currentPath,
    this.onAfterNavigate,
    this.inDrawer = false,
  });

  final String currentPath;
  final VoidCallback? onAfterNavigate;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final auth = provider.Provider.of<AuthProvider>(context);
    bool can(String menuCd) => auth.canViewMenu(menuCd);

    void navigate(void Function() action) {
      final afterNavigate = onAfterNavigate;
      if (afterNavigate != null) {
        afterNavigate();
        WidgetsBinding.instance.addPostFrameCallback((_) => action());
        return;
      }
      action();
    }

    final devChildren = <Widget>[
      if (can(kMenuDev001))
        _SidebarSubMenuItem(
          title: '예비창업자 관리',
          selected:
              currentPath == AppRoutes.founders ||
              currentPath.startsWith('${AppRoutes.founders}/'),
          onTap: () => navigate(() => context.go(AppRoutes.founders)),
        ),
      if (can(kMenuDev002))
        _SidebarSubMenuItem(
          title: '물건 관리',
          selected:
              currentPath == AppRoutes.properties ||
              currentPath.startsWith('${AppRoutes.properties}/'),
          onTap: () => navigate(() => context.go(AppRoutes.properties)),
        ),
      if (can(kMenuDev003))
        _SidebarSubMenuItem(
          title: '영업지역 관리',
          selected:
              currentPath == AppRoutes.salesAreas ||
              currentPath.startsWith('${AppRoutes.salesAreas}/register/'),
          onTap: () => navigate(() => context.go(AppRoutes.salesAreas)),
        ),
      if (can(kMenuDev003))
        _SidebarSubMenuItem(
          title: '영업지역 검색',
          selected: currentPath == AppRoutes.salesAreaSearch,
          onTap: () => navigate(() => context.go(AppRoutes.salesAreaSearch)),
        ),
    ];

    final actChildren = <Widget>[
      if (can(kMenuAct002))
        _SidebarSubMenuItem(
          title: '활동 등록',
          selected:
              currentPath == ActivityRoutes.groupManage ||
              currentPath.startsWith('${ActivityRoutes.groupManage}/') ||
              currentPath.startsWith('${AppRoutes.activities}/manage') ||
              currentPath == ActivityRoutes.drafts ||
              currentPath == ActivityRoutes.instructions ||
              currentPath == ActivityRoutes.checklist,
          onTap: () => navigate(() => context.go(ActivityRoutes.groupManage)),
        ),
      if (can(kMenuAct001))
        _SidebarSubMenuItem(
          title: '활동 현황',
          selected:
              currentPath == ActivityRoutes.groupStatus ||
              currentPath.startsWith('${ActivityRoutes.groupStatus}/') ||
              currentPath.startsWith('$kActivitiesRoot/status/'),
          onTap: () => navigate(() => context.go(ActivityRoutes.groupStatus)),
        ),
      if (can(kMenuAct004) || can(kMenuAct002))
        _SidebarSubMenuItem(
          title: '활동 계획',
          selected:
              currentPath == ActivityRoutes.calendar ||
              currentPath.startsWith('${ActivityRoutes.calendar}/'),
          onTap: () => navigate(() => context.go(ActivityRoutes.calendar)),
        ),
      if (can(kMenuAct003))
        _SidebarSubMenuItem(
          title: '활동관리결재',
          selected:
              currentPath == ActivityRoutes.groupApproval ||
              currentPath.startsWith('${ActivityRoutes.groupApproval}/') ||
              currentPath.startsWith('$kActivitiesRoot/approval/'),
          onTap: () => navigate(() => context.go(ActivityRoutes.approvalAll)),
        ),
    ];

    final eapChildren = <Widget>[
      if (can(kMenuEap001) || can(kMenuAct002) || can(kMenuAct003)) ...[
        const _SidebarGroupLabel('결재하기'),
        _SidebarSubMenuItem(
          title: '결재 대기 문서',
          selected: currentPath == EapRoutes.pending,
          onTap: () => navigate(() => context.go(EapRoutes.pending)),
        ),
        _SidebarSubMenuItem(
          title: '결재 수신 문서',
          selected: currentPath == EapRoutes.received,
          onTap: () => navigate(() => context.go(EapRoutes.received)),
        ),
        _SidebarSubMenuItem(
          title: '참조/열람 대기 문서',
          selected: currentPath == EapRoutes.ccPending,
          onTap: () => navigate(() => context.go(EapRoutes.ccPending)),
        ),
        _SidebarSubMenuItem(
          title: '결재 예정 문서',
          selected: currentPath == EapRoutes.scheduled,
          onTap: () => navigate(() => context.go(EapRoutes.scheduled)),
        ),
        const _SidebarGroupLabel('개인 문서함'),
        _SidebarSubMenuItem(
          title: '기안 문서함',
          selected: currentPath == EapRoutes.drafted,
          onTap: () => navigate(() => context.go(EapRoutes.drafted)),
        ),
        _SidebarSubMenuItem(
          title: '임시 저장함',
          selected: currentPath == EapRoutes.tempSaved,
          onTap: () => navigate(() => context.go(EapRoutes.tempSaved)),
        ),
        _SidebarSubMenuItem(
          title: '결재 문서함',
          selected: currentPath == EapRoutes.approved,
          onTap: () => navigate(() => context.go(EapRoutes.approved)),
        ),
        _SidebarSubMenuItem(
          title: '참조/열람 문서함',
          selected: currentPath == EapRoutes.ccRead,
          onTap: () => navigate(() => context.go(EapRoutes.ccRead)),
        ),
        _SidebarSubMenuItem(
          title: '수신 문서함',
          selected: currentPath == EapRoutes.inbox,
          onTap: () => navigate(() => context.go(EapRoutes.inbox)),
        ),
        _SidebarSubMenuItem(
          title: '발송 문서함',
          selected: currentPath == EapRoutes.sent,
          onTap: () => navigate(() => context.go(EapRoutes.sent)),
        ),
        _SidebarSubMenuItem(
          title: '공문 문서함',
          selected: currentPath == EapRoutes.official,
          onTap: () => navigate(() => context.go(EapRoutes.official)),
        ),
        _SidebarSubMenuItem(
          title: '전자결재 환경설정',
          selected: currentPath == EapRoutes.settings,
          onTap: () => navigate(() => context.go(EapRoutes.settings)),
        ),
      ],
    ];

    final mstChildren = <Widget>[
      if (can(kMenuMst006))
        _SidebarSubMenuItem(
          title: '가맹주관리',
          selected:
              currentPath == AppRoutes.masterOwnerUsers ||
              currentPath.startsWith('${AppRoutes.masterOwnerUsers}/'),
          onTap: () => navigate(() => context.go(AppRoutes.masterOwnerUsers)),
        ),
      if (can(kMenuMst001))
        _SidebarSubMenuItem(
          title: '사원관리',
          selected:
              currentPath == AppRoutes.masterUsers ||
              currentPath.startsWith('${AppRoutes.masterUsers}/'),
          onTap: () => navigate(() => context.go(AppRoutes.masterUsers)),
        ),
      if (can(kMenuMst002))
        _SidebarSubMenuItem(
          title: '부서관리',
          selected:
              currentPath == AppRoutes.masterDepartments ||
              currentPath.startsWith('${AppRoutes.masterDepartments}/'),
          onTap: () => navigate(() => context.go(AppRoutes.masterDepartments)),
        ),
      if (can(kMenuMst003))
        _SidebarSubMenuItem(
          title: '메뉴권한 관리',
          selected:
              currentPath == AppRoutes.masterMenuPermissions ||
              currentPath.startsWith('${AppRoutes.masterMenuPermissions}/'),
          onTap: () =>
              navigate(() => context.go(AppRoutes.masterMenuPermissions)),
        ),
      if (can(kMenuMst004))
        _SidebarSubMenuItem(
          title: '체크리스트 관리',
          selected:
              currentPath == AppRoutes.masterChecklists ||
              currentPath.startsWith('${AppRoutes.masterChecklists}/'),
          onTap: () => navigate(() => context.go(AppRoutes.masterChecklists)),
        ),
      if (can(kMenuMst005))
        _SidebarSubMenuItem(
          title: '사용기록 조회',
          selected:
              currentPath == AppRoutes.masterUsageLogs ||
              currentPath.startsWith('${AppRoutes.masterUsageLogs}/'),
          onTap: () => navigate(() => context.go(AppRoutes.masterUsageLogs)),
        ),
    ];

    return SizedBox(
      width: inDrawer ? double.infinity : 250,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.sidebarBackground,
          border: inDrawer
              ? null
              : const Border(
                  right: BorderSide(color: AppTheme.hairline),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SidebarBrand(),
            const SizedBox(height: 8),
            // 메뉴가 화면보다 길어지면(여러 그룹을 펼쳤을 때) 아래가 잘리므로
            // 가운데 메뉴 영역만 세로 스크롤되게 한다. 브랜드(상단)·프로필(하단)은 고정.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (can(kMenuDsh001))
                      _SidebarMenuItem(
                        icon: Icons.home_filled,
                        title: '홈',
                selected: currentPath == AppRoutes.dashboard,
                onTap: () => navigate(() => context.go(AppRoutes.dashboard)),
              ),
            if (can(kMenuBbs001))
              _SidebarMenuItem(
                icon: Icons.forum_outlined,
                title: '게시판',
                selected:
                    currentPath == AppRoutes.board ||
                    currentPath.startsWith('${AppRoutes.board}/'),
                onTap: () => navigate(() => context.go(AppRoutes.board)),
              ),
            if (!auth.isFranchiseOwner)
              _SidebarMenuItem(
                icon: Icons.chat_bubble_outline,
                title: '메신저',
                selected:
                    currentPath == AppRoutes.chat ||
                    currentPath.startsWith('${AppRoutes.chat}/'),
                onTap: () => navigate(() => context.go(AppRoutes.chat)),
              ),
            if (can(kMenuStr001))
              _SidebarMenuItem(
                icon: Icons.store_mall_directory,
                title: '가맹점 관리',
                selected:
                    currentPath == AppRoutes.stores ||
                    currentPath.startsWith('${AppRoutes.stores}/'),
                onTap: () => navigate(() => context.go(AppRoutes.stores)),
              ),
            if (devChildren.isNotEmpty)
              _SidebarExpandableMenuItem(
                icon: Icons.architecture_rounded,
                title: '개발 관리',
                initiallyExpanded:
                    currentPath == AppRoutes.founders ||
                    currentPath.startsWith('${AppRoutes.founders}/') ||
                    currentPath == AppRoutes.properties ||
                    currentPath.startsWith('${AppRoutes.properties}/') ||
                    currentPath == AppRoutes.salesAreas ||
                    currentPath.startsWith('${AppRoutes.salesAreas}/'),
                children: devChildren,
              ),
            if (actChildren.isNotEmpty)
              _SidebarExpandableMenuItem(
                icon: Icons.edit_note,
                title: '활동 관리',
                initiallyExpanded:
                    currentPath == AppRoutes.activities ||
                    currentPath.startsWith('${AppRoutes.activities}/'),
                children: actChildren,
              ),
            if (eapChildren.isNotEmpty)
              _SidebarExpandableMenuItem(
                icon: Icons.approval_outlined,
                title: '전자결재',
                initiallyExpanded:
                    currentPath == EapRoutes.root ||
                    currentPath.startsWith('${EapRoutes.root}/'),
                onHeaderTap: () => navigate(() => context.go(EapRoutes.home)),
                children: eapChildren,
              ),
            if (mstChildren.isNotEmpty)
              _SidebarExpandableMenuItem(
                icon: Icons.people_alt,
                title: '마스터 관리',
                initiallyExpanded: currentPath.startsWith(
                  '${AppRoutes.master}/',
                ),
                children: mstChildren,
              ),
            if (isNativeMobileApp && !auth.isFranchiseOwner)
              _SidebarMenuItem(
                icon: Icons.nfc,
                title: '출입 관리',
                selected: false,
                onTap: () => navigate(() {
                  final profile = auth.profile;
                  if (profile == null || !profile.canUseStoreEntryTag) {
                    unawaited(
                      showAlertDialog(
                        context,
                        '태그 사용 권한이 없습니다.\n사원 관리에서 태그 사용을 허용해 주세요.',
                      ),
                    );
                    return;
                  }
                  context.push(AppRoutes.storeEntry);
                }),
              ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.hairline),
            const _SidebarUserProfile(),
          ],
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_yj.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '(주)역전에프앤씨',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? AppTheme.sidebarActiveItem : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? AppTheme.accentRed : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              mouseCursor: onTap != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              leading: Icon(
                icon,
                color: selected
                    ? AppTheme.accentRed
                    : const Color(0xFF6E6E74),
                size: 20,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: selected
                      ? AppTheme.textPrimary
                      : const Color(0xFF55555A),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 클릭 시 하위 메뉴를 펼치고 접는 사이드바 메뉴.
///
/// 상위 항목 자체는 라우팅을 하지 않으며, 하위 [children] 이 실제 이동/액션을 담당합니다.
class _SidebarExpandableMenuItem extends StatefulWidget {
  const _SidebarExpandableMenuItem({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.onHeaderTap,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// 현재 경로가 하위 메뉴에 해당하는 경우 펼친 상태로 시작할 때 사용.
  final bool initiallyExpanded;

  /// 지정하면 상위 항목 클릭 시 접고 펴는 대신(또는 그와 함께) 이 이동을 수행하고
  /// 목록을 펼친다. 미지정 시 기존처럼 접기/펴기 토글만 한다.
  final VoidCallback? onHeaderTap;

  @override
  State<_SidebarExpandableMenuItem> createState() =>
      _SidebarExpandableMenuItemState();
}

class _SidebarExpandableMenuItemState
    extends State<_SidebarExpandableMenuItem> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _SidebarExpandableMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 경로 변화로 `initiallyExpanded` 가 true 로 바뀌면 펼쳐진 상태를 유지한다.
    if (!oldWidget.initiallyExpanded && widget.initiallyExpanded) {
      _expanded = true;
    }
  }

  void _handleHeaderTap() {
    final onHeaderTap = widget.onHeaderTap;
    if (onHeaderTap != null) {
      setState(() => _expanded = true);
      onHeaderTap();
      return;
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _handleHeaderTap,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                dense: true,
                mouseCursor: SystemMouseCursors.click,
                leading: Icon(
                  widget.icon,
                  color: const Color(0xFF6E6E74),
                  size: 20,
                ),
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF55555A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          firstChild: const SizedBox(height: 0),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}

/// 확장형 메뉴 내부의 하위 항목.
///
/// 상위 [_SidebarMenuItem] 보다 들여쓰기와 작은 글자로 표시됩니다.
class _SidebarSubMenuItem extends StatelessWidget {
  const _SidebarSubMenuItem({
    required this.title,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selected ? AppTheme.sidebarActiveItem : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 9, 12, 9),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accentRed
                        : const Color(0xFFB5B5B1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.textPrimary
                          : const Color(0xFF55555A),
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 확장형 메뉴 하위 항목들을 묶는 클릭 불가 소제목(예: 전자결재의 "결재하기").
class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 10, 12, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _SidebarUserProfile extends StatelessWidget {
  const _SidebarUserProfile();

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return const SizedBox.shrink();
        }

        final userName = authProvider.userName;
        final userRole = authProvider.positionNm.isEmpty
            ? '직원'
            : authProvider.positionNm;
        final firstChar = userName.isNotEmpty ? userName[0] : '?';

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  firstChar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const NotificationBellIconButton(),
              IconButton(
                tooltip: '설정',
                onPressed: () {
                  showUserProfileDialog(context);
                },
                icon: const Icon(Icons.settings, size: 18),
                color: AppTheme.textMuted,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: '로그아웃',
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                color: AppTheme.textMuted,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
