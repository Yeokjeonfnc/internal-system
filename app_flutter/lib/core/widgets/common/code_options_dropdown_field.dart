// 공통코드(code_mst) 기반 드롭다운 — 로딩·실패·빈 목록 처리 통일.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/code_option.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// [AsyncValue]로 받은 공통코드 목록을 상세·등록 폼 드롭다운으로 표시한다.
///
/// `/codes` 실패 시 빈 [DropdownButton] 대신 안내 문구를 보여 준다(서버 API 오류 대응).
class CodeOptionsDropdownField extends StatelessWidget {
  const CodeOptionsDropdownField({
    super.key,
    required this.async,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.decoration,
    this.hint = '선택',
    this.emptyMessage = '코드 목록을 불러오지 못했습니다.',
    this.errorMessage = '코드 조회에 실패했습니다. 새로고침 후 다시 시도하세요.',
  });

  final AsyncValue<List<CodeOption>> async;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final InputDecoration? decoration;
  final String hint;
  final String emptyMessage;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _message(errorMessage),
      data: (options) {
        if (options.isEmpty) return _message(emptyMessage);
        final codes = options.map((e) => e.codeCd).toSet();
        final selected =
            value != null && value!.isNotEmpty && codes.contains(value)
            ? value
            : null;
        return DropdownButtonFormField<String>(
          key: ValueKey<String>('code-dd-${options.length}-$selected'),
          initialValue: selected,
          isExpanded: true,
          decoration: decoration,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              color: FormStylePalette.textPrimary,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option.codeCd,
                child: Text(
                  option.codeNm,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        );
      },
    );
  }

  Widget _message(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: FormStylePalette.textMuted,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}
