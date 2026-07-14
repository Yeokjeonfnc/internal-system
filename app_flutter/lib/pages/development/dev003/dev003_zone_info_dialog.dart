import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

/// 영업지역 비고(zone_info) 입력 팝업.
Future<String?> showSalesAreaZoneInfoDialog(
  BuildContext context, {
  required String initialText,
  required bool readOnly,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _SalesAreaZoneInfoDialog(
        initialText: initialText,
        readOnly: readOnly,
      );
    },
  );
}

class _SalesAreaZoneInfoDialog extends StatefulWidget {
  const _SalesAreaZoneInfoDialog({
    required this.initialText,
    required this.readOnly,
  });

  final String initialText;
  final bool readOnly;

  @override
  State<_SalesAreaZoneInfoDialog> createState() =>
      _SalesAreaZoneInfoDialogState();
}

class _SalesAreaZoneInfoDialogState extends State<_SalesAreaZoneInfoDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: const Text(
        '영업지역정보',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: FormStylePalette.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          autofocus: !widget.readOnly,
          enableInteractiveSelection: !widget.readOnly,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 10,
          minLines: 8,
          style: const TextStyle(
            fontSize: kSearchFilterFontSize,
            color: kSearchFilterTextColor,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
          decoration: const InputDecoration(
            hintText: '영업지역에 대한 비고를 입력하세요',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(),
          child: Text(widget.readOnly ? '닫기' : '취소'),
        ),
        if (!widget.readOnly)
          FilledButton(
            onPressed: () => _close(_controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
