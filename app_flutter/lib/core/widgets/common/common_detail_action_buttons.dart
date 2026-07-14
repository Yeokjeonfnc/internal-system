// 상세 헤더 수정·저장·취소 액션 버튼.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/router/app_data_refresh.dart';
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
    this.enabled = true,
  });

  final FutureOr<void> Function() onPressed;
  final bool enabled;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled
          ? () => unawaited(Future<void>.sync(onPressed))
          : null,
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

class EditActionButton extends ConsumerWidget {
  const EditActionButton({super.key, required this.onPressed, this.menuCd});

  final FutureOr<void> Function() onPressed;

  /// 지정 시 **수정** 권한이 없으면 버튼을 숨긴다.
  final String? menuCd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (menuCd != null && !context.menuCanUpdate(menuCd!)) {
      return const SizedBox.shrink();
    }
    return DetailActionButton(
      onPressed: () => _runAndRefresh(context, ref, onPressed),
      icon: Icons.edit_rounded,
      label: '수정',
      backgroundColor: FormStylePalette.accent,
      foregroundColor: Colors.white,
    );
  }
}

class SaveActionButton extends ConsumerWidget {
  const SaveActionButton({
    super.key,
    required this.onPressed,
    this.menuCd,
    this.forCreate = false,
    this.enabled = true,
  });

  final FutureOr<void> Function() onPressed;
  final bool enabled;

  /// 지정 시 **등록**([forCreate]) 또는 **수정** 권한이 없으면 숨긴다.
  final String? menuCd;

  /// 신규 등록 화면이면 `true` → [menuCanCreate], 상세 저장이면 [menuCanUpdate].
  final bool forCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (menuCd != null) {
      final allowed = forCreate
          ? context.menuCanCreate(menuCd!)
          : context.menuCanUpdate(menuCd!);
      if (!allowed) {
        return const SizedBox.shrink();
      }
    }
    return DetailActionButton(
      onPressed: () => _runAndRefresh(context, ref, onPressed),
      enabled: enabled,
      icon: Icons.check_rounded,
      label: '저장',
      backgroundColor: FormStylePalette.accent,
      foregroundColor: Colors.white,
    );
  }
}

class CancelActionButton extends ConsumerWidget {
  const CancelActionButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailActionButton(
      onPressed: () => _runAndRefresh(context, ref, onPressed),
      icon: Icons.close_rounded,
      label: '취소',
      backgroundColor: FormStylePalette.neutralGray,
      foregroundColor: Colors.white,
    );
  }
}

Future<void> _runAndRefresh(
  BuildContext context,
  WidgetRef ref,
  FutureOr<void> Function() action,
) async {
  try {
    await action();
  } finally {
    if (context.mounted) {
      refreshAllScreenData(ref);
    }
  }
}
