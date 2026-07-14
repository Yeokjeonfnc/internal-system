// 가맹점·물건 등 목록 화면의 공통 카드 레이아웃(칩·검색·테이블)이다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_filter_side_drawer.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/widgets/common/common_register_button.dart';

/// 관리 리스트 화면(가맹점/예비창업자/물건 등)을 구성하는 공용 셸.
///
/// - 상단: 적용 조건 **칩 요약** + (선택) **새로고침**
/// - 선택: [mainSearchFields] — 칩 아래 본문 카드에 인라인 검색 영역
/// - 선택: [belowMainSearch] — 본문 검색 아래·건수 행 위(영업지역 요약 등)
/// - 중간: 조회 건수 + (선택) 등록 버튼
/// - 하단: 테이블
class ListPageTemplate extends StatelessWidget {
  const ListPageTemplate({
    super.key,
    required this.activeFilters,
    required this.countText,
    required this.table,
    this.onRegister,
    this.registerMenuCd,
    this.onRefresh,
    this.mainSearchFields,
    this.filterSheetBuilder,
    this.belowMainSearch,
    this.filterSheetTitle = '검색 조건',
  });

  /// 메인에 표시할 칩(비어 있으면 안내 문구만).
  final List<ActiveFilterChip> activeFilters;

  /// 칩 행 아래·건수 행 위에 붙는 인라인 검색 영역(가맹점 목록 등).
  final Widget? mainSearchFields;

  /// 모바일 필터 시트 본문. 지정 시 [ref.watch] 등으로 상태 변경 시 시트 UI가 갱신된다.
  /// 미지정 시 [mainSearchFields] 스냅샷을 사용한다.
  final WidgetBuilder? filterSheetBuilder;

  /// [mainSearchFields] 아래·조회 건수 텍스트 위에 넣는 보조 블록(집계 바 등).
  final Widget? belowMainSearch;

  final String countText;
  final Widget table;
  final VoidCallback? onRegister;

  /// 지정 시 [onRegister] 는 해당 메뉴의 **등록** 권한이 있을 때만 표시.
  final String? registerMenuCd;

  final VoidCallback? onRefresh;

  /// [showListFilterEndSheet] 제목(모바일·좁은 화면).
  final String filterSheetTitle;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final hPad = compact ? 6.0 : AppDimensions.listScreenHPadding;

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          hPad,
          0,
          hPad,
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
                border: Border.all(color: AppTheme.hairline),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? 8 : AppDimensions.listCardPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact) ...[
                          Expanded(
                            child: ActiveFilterChipsBar(chips: activeFilters),
                          ),
                          const SizedBox(width: 8),
                        ] else
                          const Spacer(),
                        if (compact && mainSearchFields != null) ...[
                          OutlinedButton.icon(
                            onPressed: () => showListFilterEndSheet(
                              context,
                              title: filterSheetTitle,
                              builder: (sheetCtx) => Consumer(
                                builder: (context, ref, _) {
                                  if (filterSheetBuilder != null) {
                                    return filterSheetBuilder!(sheetCtx);
                                  }
                                  return mainSearchFields!;
                                },
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: Text(
                              activeFilters.isEmpty
                                  ? '검색·필터'
                                  : '검색·필터 (${activeFilters.length})',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              side: const BorderSide(
                                color: AppTheme.inputBorder,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamilyFallback: AppTheme.koreanFontFallback,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onRefresh != null) ...[
                          OutlinedButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            label: const Text('새로고침'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: AppTheme.tableHeaderBorder,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamilyFallback: AppTheme.koreanFontFallback,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    if (!compact && mainSearchFields != null) ...[
                      const SizedBox(height: 12),
                      mainSearchFields!,
                    ],
                    if (!compact && belowMainSearch != null) ...[
                      const SizedBox(height: 12),
                      belowMainSearch!,
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            countText,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        if (onRegister != null &&
                            (registerMenuCd == null ||
                                context.menuCanCreate(registerMenuCd!)))
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
