// 목록 페이지 하단 페이저 — 메일 `MailPagerBar` 와 같은 토큰.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';

const List<int> kCommonPageSizes = <int>[25, 50, 100, 200];

class CommonPagerBar extends StatelessWidget {
  const CommonPagerBar({
    super.key,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizes = kCommonPageSizes,
  });

  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizes;

  int get pageCount =>
      totalCount <= 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  @override
  Widget build(BuildContext context) {
    final last = pageCount;
    final current = page.clamp(1, last);
    final from = totalCount == 0 ? 0 : (current - 1) * pageSize + 1;
    final to = (current * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        6,
        AppDimensions.listScreenHPadding,
        4,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            '$totalCount건 중 $from–$to',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '이전 페이지',
            visualDensity: VisualDensity.compact,
            onPressed: current > 1 ? () => onPageChanged(current - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
          ),
          Text(
            '$current / $last',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          IconButton(
            tooltip: '다음 페이지',
            visualDensity: VisualDensity.compact,
            onPressed: current < last ? () => onPageChanged(current + 1) : null,
            icon: const Icon(Icons.chevron_right, size: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            '페이지당',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          DropdownButton<int>(
            value: pageSizes.contains(pageSize) ? pageSize : pageSizes.first,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            items: [
              for (final n in pageSizes)
                DropdownMenuItem<int>(value: n, child: Text('$n건')),
            ],
            onChanged: (v) => onPageSizeChanged(v ?? pageSizes.first),
          ),
        ],
      ),
    );
  }
}
