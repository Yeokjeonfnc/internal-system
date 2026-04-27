// 활동 관리 — 사이드바 3메뉴(활동현황 / 활동관리 / 활동관리결재)를 서로 다른 화면으로 분리한다.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'activity_approval_management_view.dart';
import 'activity_management_view.dart';
import 'activity_routes.dart';
import 'activity_status_detail_view.dart';

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: const [ActivityStatusDetailView()],
        ),
      );
    }

    if (s == 'manage') {
      /// 사이드바「활동관리」→ 4탭 한 화면. (별도 `/activities/drafts` 등은 동일 위젯·초기탭만 다름)
      return const ActivityManagementView(initialTab: 0);
    }

    if (s == 'approval') {
      ///「활동관리」와 같이 5탭 본문만 전환.
      return const ActivityApprovalManagementView(initialTab: 0);
    }

    /// `/activities` — 세 구역을 한 스크롤에 붙이지 않고, 상위 메뉴만 안내.
    return ColoredBox(
      color: AppTheme.appSurface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            title: '활동 관리',
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
                onTap: () => context.go(ActivityRoutes.groupApproval),
              ),
            ],
          ),
        ],
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

/// 세부 메뉴 진입 시 플레이스홀더(API 연동 전).
class ActivityStubView extends StatelessWidget {
  const ActivityStubView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '화면은 준비 중입니다. 상단 뒤로가기 또는 메뉴에서 '
                    '「활동 관리」로 돌아갈 수 있습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.grey.shade700,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () => context.go(ActivityRoutes.hub),
                    child: const Text('활동 관리 메뉴'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
