// 상태 배지 공통 위젯 — 01_design_system.md §4 배지/칩 규격.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// dot + 텍스트 + 옅은 틴트 배경의 pill 상태 배지.
///
/// 배경은 상태색 8% 틴트(`withValues(alpha: .08)`), 텍스트/dot은 상태색.
/// 계약상태·결재상태·평가상태 등 모든 목록 상태 표기는 이 위젯으로 통일한다.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    required this.color,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.3,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ],
      ),
    );
  }
}

/// 결재상태(apprStatus) → 상태색. (02_screens.md §12)
/// 승인=초록 · 결재중=파랑 · 상신(대기)=앰버 · 반려=빨강 · 임시저장=그레이.
Color approvalStatusColor(String raw) {
  final r = raw.trim().toUpperCase();
  return switch (r) {
    'APPROVED' || '승인' || '결재완료' => AppTheme.statusNew,
    'IN_PROGRESS' || '결재중' => AppTheme.statusRenewal,
    'PENDING' || '상신' || '결재대기' || '대기' => AppTheme.statusPending,
    'REJECTED' || '반려' => AppTheme.statusClosed,
    'DRAFT' || '임시저장' => AppTheme.textMuted,
    _ => AppTheme.textMuted,
  };
}
