import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// ERP 메인 셸·독립 모바일 화면 공통 상단 배너.
///
/// 2026 리디자인: 화이트 탑바 + 헤어라인 하단 보더 + 잉크블랙 타이틀
/// (`prototype/Yeokjeon App.dc.html` topbar 규격).
class AppShellTopBanner extends StatelessWidget {
  const AppShellTopBanner({
    super.key,
    required this.title,
    this.subtitle = '',
    this.compact = false,
    this.onOpenDrawer,
    this.onBack,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back_rounded,
    this.backTooltip = '뒤로',
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onBack;
  final bool showBackButton;
  final IconData backIcon;
  final String backTooltip;
  final Widget? trailing;

  bool get _hasSubtitle => subtitle.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final minBannerHeight = compact ? (_hasSubtitle ? 64.0 : 48.0) : 60.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minBannerHeight),
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 20,
        compact ? 8 : 8,
        compact ? 8 : 16,
        compact ? 8 : 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onOpenDrawer != null) ...[
            AppShellBannerLeadingButton(
              icon: Icons.menu_rounded,
              tooltip: '메뉴',
              onPressed: onOpenDrawer,
            ),
            SizedBox(width: compact ? 4 : 10),
          ],
          if (showBackButton)
            AppShellBannerLeadingButton(
              icon: backIcon,
              tooltip: backTooltip,
              onPressed: onBack,
            ),
          if (showBackButton) SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: compact ? 16 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.15,
                    fontFamily: AppTheme.brandFontFamily,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                if (_hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: compact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: compact ? 11 : 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                      height: 1.25,
                      fontFamily: AppTheme.brandFontFamily,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AppShellBannerLeadingButton extends StatelessWidget {
  const AppShellBannerLeadingButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    final button = Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.tableHeaderBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        hoverColor: const Color(0xFFF4F4F2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: AppTheme.textSecondary, size: 17),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: button);
  }
}
