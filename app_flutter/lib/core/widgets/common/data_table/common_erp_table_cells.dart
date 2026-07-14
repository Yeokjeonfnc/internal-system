// ERP 테이블 헤더·본문 셀 위젯.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';

/// 관리 리스트의 테이블 헤더 셀 — 라이트 헤더(01_design_system.md §4 테이블).
///
/// 헤더 행 배경은 [kErpTableHeaderRowDecoration]과 함께 쓴다.
/// [light]는 리디자인 전환기 호환용으로 남겨둔 파라미터(값과 무관하게 라이트).
class ErpTableHeaderCell extends StatelessWidget {
  const ErpTableHeaderCell(this.text, {super.key, this.light = true});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? AppDimensions.tableCellPaddingHCompact
            : AppDimensions.tableCellPaddingH,
        vertical: compact
            ? AppDimensions.tableCellPaddingVCompact
            : AppDimensions.tableCellPaddingV,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: compact
                ? AppDimensions.tableHeaderFontSizeCompact
                : 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 관리 리스트의 테이블 본문 셀.
///
/// 세 가지 정렬 옵션을 지원한다.
/// - 기본: 좌측 정렬 (주로 주소, 이름 등)
/// - [center]: 가운데 정렬 (코드, 날짜, 카운트 등)
/// - [alignRight]: 우측 정렬 (금액 등 숫자)
class ErpTableBodyCell extends StatelessWidget {
  const ErpTableBodyCell(
    this.text, {
    super.key,
    this.center = false,
    this.alignRight = false,
  });

  final String text;
  final bool center;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    final align = alignRight
        ? TextAlign.right
        : (center ? TextAlign.center : TextAlign.left);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? AppDimensions.tableCellPaddingHCompact
            : AppDimensions.tableCellPaddingH,
        vertical: compact
            ? AppDimensions.tableCellPaddingVCompact
            : AppDimensions.tableCellPaddingV,
      ),
      child: Align(
        alignment: alignRight
            ? Alignment.centerRight
            : (center ? Alignment.center : Alignment.centerLeft),
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? AppDimensions.tableBodyFontSizeCompact : 12.5,
            height: 1.2,
            color: AppTheme.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
        ),
      ),
    );
  }
}

/// 목록 [Table] 행 더블클릭(상세 이동 등). 셀마다 동일 [onDoubleTap]으로 감싼다.
class ErpTableDoubleTapCell extends StatelessWidget {
  const ErpTableDoubleTapCell({
    super.key,
    required this.onDoubleTap,
    required this.child,
  });

  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    // [Table] 셀은 자식이 텍스트 크기만 잡히면 MouseRegion 커서가 웹에서 안 바뀐다.
    // Material+InkWell(mouseCursor) + 가로·세로 채우기로 셀 전체를 히트 영역으로 만든다.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onDoubleTap: onDoubleTap,
        onTap: compact ? onDoubleTap : null,
        mouseCursor: SystemMouseCursors.click,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: const Color(0x0A000000),
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: compact
                  ? AppDimensions.tableRowMinHeightCompact
                  : AppDimensions.tableRowMinHeight,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
