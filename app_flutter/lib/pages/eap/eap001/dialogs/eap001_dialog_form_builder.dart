// 전자결재 양식 편집기 — Form Builder (다우오피스형 3패널).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/pages/eap/eap001/eap_form_builder.dart';

/// 양식 빌더(항목 팔레트 · A4 캔버스 · 속성)를 대형 팝업으로 연다.
Future<({String html, String schemaJson})?> showEapFormEditorDialog(
  BuildContext context, {
  required EapFormBuilderController controller,
}) {
  return showDialog<({String html, String schemaJson})>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    requestFocus: false,
    builder: (dialogCtx) => _EapFormEditorDialog(controller: controller),
  );
}

class _EapFormEditorDialog extends ConsumerStatefulWidget {
  const _EapFormEditorDialog({required this.controller});

  final EapFormBuilderController controller;
  @override
  ConsumerState<_EapFormEditorDialog> createState() =>
      _EapFormEditorDialogState();
}

class _EapFormEditorDialogState extends ConsumerState<_EapFormEditorDialog> {
  var _confirming = false;

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      final data = await widget.controller.getFormData();
      if (!mounted) return;
      Navigator.of(context).pop(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : '양식을 읽지 못했습니다. 잠시 후 다시 시도해 주세요.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppTheme.cardBackground,
      child: SizedBox(
        width: size.width * 0.96,
        height: size.height * 0.92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
              child: Row(
                children: [
                  const Text(
                    '양식 편집기',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HTML·엑셀·다우오피스 양식 붙여넣기 지원 (행 추가/자동계산 스크립트 포함)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _confirming
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _confirming ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_confirming ? '적용 중...' : '확인'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: FormStylePalette.panelBorder),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.hairline),
                ),
                child: EapFormBuilderHost(controller: widget.controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
