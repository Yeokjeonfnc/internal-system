import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/form_style_palette.dart';

/// 공통 알림 다이얼로그
/// SnackBar 대신 사용하는 중앙 팝업 알림
Future<void> showAlertDialog(
  BuildContext context,
  String message, {
  String title = '알림',
}) async {
  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}

/// 웹 등에서 모바일 전용 기능(가맹점출입관리 등) 안내.
Future<void> showMobileOnlyFeatureDialog(
  BuildContext context, {
  String message = '가맹점출입관리는 모바일에서만 지원합니다.',
}) async {
  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: FormStylePalette.textPrimary,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
            ),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      );
    },
  );
}
