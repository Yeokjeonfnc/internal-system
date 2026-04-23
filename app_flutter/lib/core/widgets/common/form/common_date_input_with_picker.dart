// 날짜 표시 + 달력 피커 연동 입력 줄.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';

/// 날짜 값을 읽기 전용으로 보여주고, 우측 달력 버튼으로 선택 가능한 컴포넌트.
class DateInputWithPicker extends StatelessWidget {
  const DateInputWithPicker({
    super.key,
    required this.value,
    required this.onPick,
    this.placeholder = '-',
  });

  final DateTime? value;
  final VoidCallback onPick;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ReadonlyInputShell(
            child: Text(
              _formatYmd(value) ?? placeholder,
              style: FormStylePalette.valueStyle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CalendarPickButton(onPressed: onPick),
      ],
    );
  }
}

/// 우측 달력 아이콘 버튼.
class CalendarPickButton extends StatelessWidget {
  const CalendarPickButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '날짜 선택',
      child: OutlinedButton(
        onPressed: onPressed,
        style: accentOutlineButtonStyle(iconOnly: true),
        child: const Icon(Icons.calendar_month_rounded, size: 22),
      ),
    );
  }
}

/// 포인트 컬러로 테마가 적용된 공통 Date Picker 호출 헬퍼.
Future<DateTime?> showAccentDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(1990),
    lastDate: lastDate ?? DateTime(2100),
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: FormStylePalette.accent,
            surface: Colors.white,
            onSurface: FormStylePalette.textPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );
}

String? _formatYmd(DateTime? d) {
  if (d == null) return null;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
