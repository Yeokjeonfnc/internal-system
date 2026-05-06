import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
          borderRadius: BorderRadius.circular(12),
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
