// 목록 화면 상단 등록 버튼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 리스트 화면 상단에서 사용하는 공통 "등록" 버튼.
///
/// 브랜드 accent 컬러를 배경으로 쓰는 작은 FilledButton 스타일이며,
/// 좌측에 `+` 아이콘이 표시됩니다.
class RegisterButton extends StatelessWidget {
  const RegisterButton({super.key, required this.onPressed, this.label = '등록'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accentRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
