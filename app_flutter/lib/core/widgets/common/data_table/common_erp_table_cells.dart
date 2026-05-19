// ERP 테이블 헤더·본문 셀 위젯.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';

/// 관리 리스트의 테이블 헤더 셀. 빨강 배경 + 흰색 굵은 텍스트.
class ErpTableHeaderCell extends StatelessWidget {
  const ErpTableHeaderCell(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.tableCellPaddingH,
        vertical: AppDimensions.tableCellPaddingV,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
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
    final align = alignRight
        ? TextAlign.right
        : (center ? TextAlign.center : TextAlign.left);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.tableCellPaddingH,
        vertical: AppDimensions.tableCellPaddingV,
      ),
      child: Align(
        alignment: alignRight
            ? Alignment.centerRight
            : (center ? Alignment.center : Alignment.centerLeft),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            color: Color(0xFF212529),
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
        ),
      ),
    );
  }
}
