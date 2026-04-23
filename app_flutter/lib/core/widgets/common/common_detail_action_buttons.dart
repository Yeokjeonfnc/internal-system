// 상세 헤더 수정·저장·취소 액션 버튼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 상세 화면 헤더의 수정/저장/취소 액션 버튼 공통 골격.
class DetailActionButton extends StatelessWidget {
  const DetailActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class EditActionButton extends StatelessWidget {
  const EditActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DetailActionButton(
      onPressed: onPressed,
      icon: Icons.edit_rounded,
      label: '수정',
      backgroundColor: FormStylePalette.accent,
      foregroundColor: Colors.white,
    );
  }
}

class SaveActionButton extends StatelessWidget {
  const SaveActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DetailActionButton(
      onPressed: onPressed,
      icon: Icons.check_rounded,
      label: '저장',
      backgroundColor: FormStylePalette.accent,
      foregroundColor: Colors.white,
    );
  }
}

class CancelActionButton extends StatelessWidget {
  const CancelActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DetailActionButton(
      onPressed: onPressed,
      icon: Icons.close_rounded,
      label: '취소',
      backgroundColor: FormStylePalette.neutralGray,
      foregroundColor: Colors.white,
    );
  }
}
