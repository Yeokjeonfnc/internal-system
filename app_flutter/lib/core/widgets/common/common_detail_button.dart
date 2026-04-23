// 목록 테이블 행의 상세보기 버튼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 목록 테이블 행 끝에 붙는 공통 "상세보기" 버튼.
///
/// 가맹점관리·예비창업자관리 등 여러 화면의 목록 테이블에서 동일한 스타일로 사용됩니다.
class DetailButton extends StatelessWidget {
  const DetailButton({super.key, required this.onPressed, this.label = '상세보기'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.description_outlined, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}
