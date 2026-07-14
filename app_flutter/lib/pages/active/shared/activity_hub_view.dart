// 활동 관리 — 사이드바 3메뉴(활동현황 / 활동관리 / 활동관리결재)를 서로 다른 화면으로 분리한다.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_flutter/pages/active/act002/act002_view.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/pages/active/shared/activity_routes.dart';
import 'package:app_flutter/pages/active/act001/act001_view_status.dart';

/// - [section] 없음: `/activities` — 상위 3메뉴만(각각 별도 경로로 이동).
/// - `status`: 활동현황만.
/// - `manage`: 임시보관~체크리스트 **탭 화면**만(가맹점 등록형 레드 탭).
/// - `approval`: 활동관리결재 하위 링크만.
class ActivityHubView extends StatelessWidget {
  const ActivityHubView({super.key, this.section});

  /// `group/:section` 의 `section` — `null`이면 루트 허브 `/activities`.
  final String? section;

  @override
  Widget build(BuildContext context) {
    final s = section;

    if (s == 'status') {
      return ColoredBox(
        color: AppTheme.appSurface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: const ActivityStatusDetailView(),
        ),
      );
    }

    if (s == 'manage') {
      /// 사이드바「활동관리」→ 4탭 한 화면. (별도 `/activities/drafts` 등은 동일 위젯·초기탭만 다름)
      return const Act002View(initialTab: 0);
    }

    if (s == 'approval') {
      return const _ActivityApprovalRouteRedirect();
    }

    /// `/activities` — 세 구역을 한 스크롤에 붙이지 않고, 상위 메뉴만 안내.
    return ColoredBox(
      color: AppTheme.appSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '메뉴를 선택하세요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: '활동관리',
              items: [
                _MenuTile(
                  label: '활동현황',
                  onTap: () => context.go(ActivityRoutes.groupStatus),
                ),
                _MenuTile(
                  label: '활동관리',
                  onTap: () => context.go(ActivityRoutes.groupManage),
                ),
                _MenuTile(
                  label: '활동관리결재',
                  onTap: () => context.go(ActivityRoutes.approvalAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.2,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 22),
      onTap: onTap,
    );
  }
}

/// `/activities/group/approval` 진입 시 표준 결재 경로(`/activities/approval/all`)로 보낸다.
class _ActivityApprovalRouteRedirect extends StatefulWidget {
  const _ActivityApprovalRouteRedirect();

  @override
  State<_ActivityApprovalRouteRedirect> createState() =>
      _ActivityApprovalRouteRedirectState();
}

class _ActivityApprovalRouteRedirectState
    extends State<_ActivityApprovalRouteRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(ActivityRoutes.approvalAll);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.appSurface,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
