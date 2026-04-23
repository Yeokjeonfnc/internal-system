// 마스터 관리 하위 화면 — API·본문 UI 연동 전 플레이스홀더.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

class MasterModulePlaceholderView extends StatelessWidget {
  const MasterModulePlaceholderView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.listScreenHPadding,
              16,
              AppDimensions.listScreenHPadding,
              AppDimensions.listScreenBottomPadding,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: const Color(0xFFE2E5EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '화면 구성 및 데이터 연동은 추후 진행 예정입니다.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: FormStylePalette.textPrimary.withValues(alpha: 0.65),
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 부서관리
class DepartmentManagementView extends StatelessWidget {
  const DepartmentManagementView({super.key});

  @override
  Widget build(BuildContext context) =>
      const MasterModulePlaceholderView(title: '부서관리');
}

/// 메뉴권한 관리
class MenuPermissionManagementView extends StatelessWidget {
  const MenuPermissionManagementView({super.key});

  @override
  Widget build(BuildContext context) =>
      const MasterModulePlaceholderView(title: '메뉴권한 관리');
}

/// 체크리스트 관리 (마스터)
class MasterChecklistManagementView extends StatelessWidget {
  const MasterChecklistManagementView({super.key});

  @override
  Widget build(BuildContext context) =>
      const MasterModulePlaceholderView(title: '체크리스트 관리');
}
