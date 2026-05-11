// 날짜 표시 + 달력 피커 연동 입력 줄.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';

/// 날짜 값을 텍스트 또는 우측 달력 버튼으로 입력하는 컴포넌트.
class DateInputWithPicker extends StatefulWidget {
  const DateInputWithPicker({
    super.key,
    required this.value,
    this.onPick,
    this.onChanged,
    this.placeholder = '-',
  });

  final DateTime? value;
  final VoidCallback? onPick;
  final ValueChanged<DateTime?>? onChanged;
  final String placeholder;

  @override
  State<DateInputWithPicker> createState() => _DateInputWithPickerState();
}

class _DateInputWithPickerState extends State<DateInputWithPicker> {
  late final TextEditingController _controller;
  bool _invalidInput = false;

  bool get _editable => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatYmd(widget.value) ?? '');
  }

  @override
  void didUpdateWidget(DateInputWithPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _formatYmd(widget.value) ?? '';
    if (oldWidget.value != widget.value && _controller.text != nextText) {
      _controller.text = nextText;
      _invalidInput = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _invalidInput = false);
      widget.onChanged?.call(null);
      return;
    }

    final shouldValidate =
        trimmed.replaceAll(RegExp(r'[^0-9]'), '').length >= 8;
    if (!shouldValidate) {
      if (_invalidInput) setState(() => _invalidInput = false);
      return;
    }

    final parsed = _parseYmd(trimmed);
    setState(() => _invalidInput = shouldValidate && parsed == null);
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _editable
              ? TextField(
                  controller: _controller,
                  onChanged: _handleTextChanged,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [_DateTextInputFormatter()],
                  style: FormStylePalette.valueStyle,
                  decoration: InputDecoration(
                    hintText: 'yyyy-MM-dd',
                    hintStyle: TextStyle(
                      color: FormStylePalette.textMuted,
                      fontSize: 13,
                    ),
                    errorText: _invalidInput ? 'yyyy-MM-dd 형식으로 입력하세요.' : null,
                    filled: true,
                    fillColor: FormStylePalette.inputBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: FormStylePalette.panelBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: FormStylePalette.panelBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: FormStylePalette.accent,
                        width: 1.4,
                      ),
                    ),
                  ),
                )
              : ReadonlyInputShell(
                  child: Text(
                    _formatYmd(widget.value) ?? widget.placeholder,
                    style: FormStylePalette.readStyle,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        CalendarPickButton(onPressed: widget.onPick),
      ],
    );
  }
}

/// 우측 달력 아이콘 버튼.
class CalendarPickButton extends StatelessWidget {
  const CalendarPickButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

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

class _DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }
    final rawDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = rawDigits.length > 8 ? rawDigits.substring(0, 8) : rawDigits;
    final formatted = _formatDateInputDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

String _formatDateInputDigits(String digits) {
  if (digits.length <= 4) return digits;
  if (digits.length <= 6) {
    return '${digits.substring(0, 4)}-${digits.substring(4)}';
  }
  return '${digits.substring(0, 4)}-${digits.substring(4, 6)}-${digits.substring(6)}';
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

DateTime? _parseYmd(String value) {
  final normalized = value.trim().replaceAll('/', '-').replaceAll('.', '-');
  final compact = RegExp(r'^\d{8}$');
  final dashed = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

  final match = dashed.firstMatch(normalized);
  if (match != null) {
    return _strictDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  if (compact.hasMatch(normalized)) {
    return _strictDate(
      int.parse(normalized.substring(0, 4)),
      int.parse(normalized.substring(4, 6)),
      int.parse(normalized.substring(6, 8)),
    );
  }

  return null;
}

DateTime? _strictDate(int year, int month, int day) {
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
