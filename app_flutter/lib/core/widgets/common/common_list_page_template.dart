// 가맹점·물건 등 목록 화면의 공통 카드 레이아웃(칩·필터·테이블)이다.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_side_drawer.dart';
import 'package:app_flutter/core/widgets/common/common_register_button.dart';

/// 관리 리스트 화면(가맹점/예비창업자/물건 등)을 구성하는 공용 셸.
///
/// - 상단: 적용 조건 **칩 요약** + 우측 **[필터(n)]** 버튼 → 우측 슬라이드 시트
/// - 선택: [mainSearchFields] — 칩 아래 본문 카드에 2열 검색칸 등 인라인 배치
/// - 중간: 조회 건수 + (선택) 등록 버튼
/// - 하단: 테이블
class ListPageTemplate extends StatelessWidget {
  const ListPageTemplate({
    super.key,
    required this.activeFilters,
    required this.filterSheetBody,
    required this.countText,
    required this.table,
    this.onRegister,
    this.filterSheetTitle = '검색 조건',
    this.mainSearchFields,
  });

  /// 메인에 표시할 칩(비어 있으면 안내 문구만).
  final List<ActiveFilterChip> activeFilters;

  /// 슬라이드 패널 안에 넣을 필터 폼(보통 [CommonFilterBar] 2열 구성).
  final Widget filterSheetBody;

  /// 칩 행 아래·건수 행 위에 붙는 인라인 검색 영역(가맹점 목록 등).
  final Widget? mainSearchFields;

  final String countText;
  final Widget table;
  final VoidCallback? onRegister;

  /// 슬라이드 패널 제목.
  final String filterSheetTitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.listScreenHPadding,
          0,
          AppDimensions.listScreenHPadding,
          AppDimensions.listScreenBottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.contentMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: const Color(0xFFE2E5EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.listCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ActiveFilterChipsBar(chips: activeFilters),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => showListFilterEndSheet(
                            context,
                            title: filterSheetTitle,
                            child: filterSheetBody,
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: Text('필터(${activeFilters.length})'),
                          style: FilledButton.styleFrom(
                            foregroundColor: AppTheme.accentRed,
                            backgroundColor: const Color(0xFFFFF1F2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFFCE7E8)),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.1,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (mainSearchFields != null) ...[
                      const SizedBox(height: 12),
                      mainSearchFields!,
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            countText,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        if (onRegister != null)
                          RegisterButton(onPressed: onRegister!),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(child: table),
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
