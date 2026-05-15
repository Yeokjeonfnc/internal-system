// 사이드바·상단 멀티 탭·페이지 배너를 포함한 ERP 메인 껍데기 레이아웃이다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import '../router/app_router.dart';
import '../router/route_meta.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import '../theme/app_colors.dart';
import '../theme/shell_tab_chrome.dart';
import '../auth/auth_provider.dart';
import '../auth/user_profile_dialog.dart';
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
    return Scaffold(
      body: Row(
        children: [
          _SidebarNavigation(currentPath: location),
          Expanded(
            child: ColoredBox(
              color: AppTheme.appSurface,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShellTabStrip(currentPath: location),
                    _ShellTopBanner(meta: meta, currentPath: location),
                    Expanded(child: SelectionArea(child: widget.child)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 브라우저형으로 열린 화면을 나열하는 상단 탭 줄.
class _ShellTabStrip extends ConsumerWidget {
  const _ShellTabStrip({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabManagerProvider);
    final notifier = ref.read(tabManagerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ShellTabChrome.barGradient),
      child: SizedBox(
        height: ShellTabChrome.tabStripHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      ShellTabChrome.barHighlightLine,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        12,
                        ShellTabChrome.tabStripTopPadding,
                        12,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < tabs.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
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
                      padding: const EdgeInsets.only(right: 10, bottom: 6),
                      child: Tooltip(
                        message: '열린 탭 모두 닫기',
                        child: IconButton(
                          onPressed: () => notifier.closeAllTabs(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            hoverColor: Colors.white.withValues(alpha: 0.18),
                            minimumSize: const Size(34, 34),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellTabChip extends StatefulWidget {
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
  State<_ShellTabChip> createState() => _ShellTabChipState();
}

class _ShellTabChipState extends State<_ShellTabChip> {
  bool _hover = false;

  @override
  void didUpdateWidget(covariant _ShellTabChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _hover = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final inactiveRadius = BorderRadius.circular(8);
    final activeTopRadius = const BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    );

    if (selected) {
      return SizedBox(
        height: ShellTabChrome.tabActiveFillHeight,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: ShellTabChrome.activeTabGradient,
              borderRadius: activeTopRadius,
              border: ShellTabChrome.activeTabBorderSides,
              boxShadow: ShellTabChrome.activeTabShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: widget.onSelect,
                  borderRadius: activeTopRadius,
                  hoverColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      0,
                      widget.closable ? 2 : 14,
                      0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ShellTabChrome.tabTitleMaxWidthActive,
                      ),
                      child: Text(
                        widget.tab.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ShellTabChrome.activeLabelOnRed,
                          fontSize: 17,
                          letterSpacing: -0.15,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.closable)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, size: 15),
                    color: ShellTabChrome.activeIconOnRed,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(30, 30),
                      padding: EdgeInsets.zero,
                      hoverColor: Colors.white.withValues(alpha: 0.14),
                    ),
                    tooltip: '탭 닫기',
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hover ? ShellTabChrome.inactiveHoverFill : Colors.transparent,
          borderRadius: inactiveRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onSelect,
              borderRadius: inactiveRadius,
              hoverColor: ShellTabChrome.inactiveHoverFill,
              splashColor: Colors.white.withValues(alpha: 0.12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  9,
                  widget.closable ? 2 : 14,
                  9,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ShellTabChrome.tabTitleMaxWidthInactive,
                  ),
                  child: Text(
                    widget.tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ShellTabChrome.inactiveLabel,
                      fontSize: 13,
                      letterSpacing: -0.15,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.closable)
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, size: 15),
                color: ShellTabChrome.inactiveIcon,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(30, 30),
                  padding: EdgeInsets.zero,
                  hoverColor: Colors.white.withValues(alpha: 0.12),
                ),
                tooltip: '탭 닫기',
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellTopBanner extends StatelessWidget {
  const _ShellTopBanner({required this.meta, required this.currentPath});

  final RouteMeta meta;
  final String currentPath;

  bool get _isDashboard => currentPath == AppRoutes.dashboard;

  static const double _bannerHeight = 72;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        width: double.infinity,
        height: _bannerHeight,
        padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
        decoration: const BoxDecoration(
          color: AppTheme.accentRed,
          // borderRadius: BorderRadius.only(
          //   topRight: Radius.circular(8),
          //   bottomRight: Radius.circular(8),
          // ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ShellBannerLeadingButton(
              icon: _isDashboard
                  ? Icons.home_rounded
                  : Icons.arrow_back_rounded,
              tooltip: _isDashboard ? '홈' : '뒤로',
              onPressed: _isDashboard
                  ? null
                  : () => _shellNavigateBack(context, currentPath),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.15,
                      fontFamily: AppTheme.brandFontFamily,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  if (meta.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        fontFamily: AppTheme.brandFontFamily,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isDashboard)
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellBannerLeadingButton extends StatelessWidget {
  const _ShellBannerLeadingButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: button);
  }
}

/// 상단 뒤로가기 버튼 처리.
///
/// 1. 브라우저/내비게이션 스택에 이전 페이지가 있으면 그걸로 pop 한다.
/// 2. 없을 때는 [parentPathFor] 로 부모 경로를 조회해서 이동한다.
void _shellNavigateBack(BuildContext context, String currentPath) {
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
  const _SidebarNavigation({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarBrand(),
          const SizedBox(height: 8),
          _SidebarMenuItem(
            icon: Icons.home_filled,
            title: '홈',
            selected: currentPath == AppRoutes.dashboard,
            onTap: () => context.go(AppRoutes.dashboard),
          ),
          _SidebarMenuItem(
            icon: Icons.store_mall_directory,
            title: '가맹점 관리',
            selected:
                currentPath == AppRoutes.stores ||
                currentPath.startsWith('${AppRoutes.stores}/'),
            onTap: () => context.go(AppRoutes.stores),
          ),
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
            children: [
              _SidebarSubMenuItem(
                title: '예비창업자 관리',
                selected:
                    currentPath == AppRoutes.founders ||
                    currentPath.startsWith('${AppRoutes.founders}/'),
                onTap: () => context.go(AppRoutes.founders),
              ),
              _SidebarSubMenuItem(
                title: '물건 관리',
                selected:
                    currentPath == AppRoutes.properties ||
                    currentPath.startsWith('${AppRoutes.properties}/'),
                onTap: () => context.go(AppRoutes.properties),
              ),
              _SidebarSubMenuItem(
                title: '영업지역 관리',
                selected:
                    currentPath == AppRoutes.salesAreas ||
                    currentPath.startsWith('${AppRoutes.salesAreas}/'),
                onTap: () => context.go(AppRoutes.salesAreas),
              ),
            ],
          ),
          _SidebarExpandableMenuItem(
            icon: Icons.edit_note,
            title: '활동관리',
            initiallyExpanded:
                currentPath == AppRoutes.activities ||
                currentPath.startsWith('${AppRoutes.activities}/'),
            children: [
              _SidebarSubMenuItem(
                title: '활동현황',
                selected:
                    currentPath == ActivityRoutes.groupStatus ||
                    currentPath.startsWith('${ActivityRoutes.groupStatus}/') ||
                    currentPath.startsWith('$kActivitiesRoot/status/'),
                onTap: () => context.go(ActivityRoutes.groupStatus),
              ),
              _SidebarSubMenuItem(
                title: '활동관리',
                selected:
                    currentPath == ActivityRoutes.groupManage ||
                    currentPath.startsWith('${ActivityRoutes.groupManage}/') ||
                    currentPath.startsWith('${AppRoutes.activities}/manage') ||
                    currentPath == ActivityRoutes.drafts ||
                    currentPath == ActivityRoutes.instructions ||
                    currentPath == ActivityRoutes.checklist,
                onTap: () => context.go(ActivityRoutes.groupManage),
              ),
              _SidebarSubMenuItem(
                title: '활동관리결재',
                selected:
                    currentPath == ActivityRoutes.groupApproval ||
                    currentPath.startsWith(
                      '${ActivityRoutes.groupApproval}/',
                    ) ||
                    currentPath.startsWith('$kActivitiesRoot/approval/'),
                onTap: () => context.go(ActivityRoutes.approvalAll),
              ),
            ],
          ),
          _SidebarExpandableMenuItem(
            icon: Icons.people_alt,
            title: '마스터 관리',
            initiallyExpanded: currentPath.startsWith('${AppRoutes.master}/'),
            children: [
              _SidebarSubMenuItem(
                title: '사원관리',
                selected:
                    currentPath == AppRoutes.masterUsers ||
                    currentPath.startsWith('${AppRoutes.masterUsers}/'),
                onTap: () => context.go(AppRoutes.masterUsers),
              ),
              _SidebarSubMenuItem(
                title: '부서관리',
                selected:
                    currentPath == AppRoutes.masterDepartments ||
                    currentPath.startsWith('${AppRoutes.masterDepartments}/'),
                onTap: () => context.go(AppRoutes.masterDepartments),
              ),
              _SidebarSubMenuItem(
                title: '메뉴권한 관리',
                selected:
                    currentPath == AppRoutes.masterMenuPermissions ||
                    currentPath.startsWith(
                      '${AppRoutes.masterMenuPermissions}/',
                    ),
                onTap: () => context.go(AppRoutes.masterMenuPermissions),
              ),
              _SidebarSubMenuItem(
                title: '체크리스트 관리',
                selected:
                    currentPath == AppRoutes.masterChecklists ||
                    currentPath.startsWith('${AppRoutes.masterChecklists}/'),
                onTap: () => context.go(AppRoutes.masterChecklists),
              ),
            ],
          ),
          const _SidebarMenuItem(icon: Icons.lock, title: '출입 관리 (Mobile)'),
          const Spacer(),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          const _SidebarUserProfile(),
        ],
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
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
                  width: 3,
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              mouseCursor: onTap != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              leading: Icon(icon, color: Colors.white70, size: 20),
              title: Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFADB5BD),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// 현재 경로가 하위 메뉴에 해당하는 경우 펼친 상태로 시작할 때 사용.
  final bool initiallyExpanded;

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

  void _toggle() => setState(() => _expanded = !_expanded);

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
              onTap: _toggle,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                dense: true,
                mouseCursor: SystemMouseCursors.click,
                leading: Icon(widget.icon, color: Colors.white70, size: 20),
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFFADB5BD),
                    fontSize: 14,
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
                        : const Color(0xFF6C757D),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFADB5BD),
                      fontSize: 13,
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
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFADB5BD),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                color: const Color(0xFFADB5BD),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.03),
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
                color: const Color(0xFFADB5BD),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.03),
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
