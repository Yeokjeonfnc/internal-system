// 활동관리 등록 — 전자서명 입력(마우스·터치).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';

/// 전자서명 [저장] 직전 확인 — 미평가 체크리스트 유무에 따라 문구가 달라진다.
Future<bool> showAct002ElectronicSignatureSaveConfirmDialog(
  BuildContext context, {
  required bool hasChecklistGaps,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: false,
    builder: (ctx) => _Act002ElectronicSignatureSaveConfirmDialog(
      hasChecklistGaps: hasChecklistGaps,
    ),
  );
  return ok == true;
}

class _Act002ElectronicSignatureSaveConfirmDialog extends StatelessWidget {
  const _Act002ElectronicSignatureSaveConfirmDialog({
    required this.hasChecklistGaps,
  });

  final bool hasChecklistGaps;

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: FormStylePalette.textPrimary,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: FormStylePalette.panelBg,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErpDialogHeader(
                title: '확인',
                onClose: () => Navigator.of(context).pop(false),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasChecklistGaps) ...[
                      const Text(
                        '미평가 체크리스트가 존재합니다.',
                        textAlign: TextAlign.center,
                        style: _bodyStyle,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Text(
                      '전자서명을 저장하면 입력된 내용 수정 불가합니다.',
                      textAlign: TextAlign.center,
                      style: _bodyStyle,
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: _bodyStyle,
                        children: [
                          TextSpan(text: '바로 '),
                          TextSpan(
                            text: '상신',
                            style: TextStyle(
                              color: AppTheme.accentRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' 하시겠습니까?'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FormStylePalette.neutralGray,
                        side: const BorderSide(color: FormStylePalette.panelBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 서명 패드 팝업. [저장] 시 PNG 바이트를 반환, 취소·닫기는 `null`.
///
/// [hasChecklistGaps] — 미평가 체크리스트 여부. 저장 직전 확인 팝업 문구에 반영된다.
Future<Uint8List?> showAct002ElectronicSignatureDialog(
  BuildContext context, {
  bool Function()? hasChecklistGaps,
}) {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _Act002ElectronicSignatureDialogBody(
      hasChecklistGaps: hasChecklistGaps,
    ),
  );
}

class _Act002ElectronicSignatureDialogBody extends StatefulWidget {
  const _Act002ElectronicSignatureDialogBody({
    this.hasChecklistGaps,
  });

  final bool Function()? hasChecklistGaps;

  @override
  State<_Act002ElectronicSignatureDialogBody> createState() =>
      _Act002ElectronicSignatureDialogBodyState();
}

class _Act002ElectronicSignatureDialogBodyState
    extends State<_Act002ElectronicSignatureDialogBody> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_controller.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서명을 입력한 뒤 저장해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final gaps = widget.hasChecklistGaps?.call() ?? false;
    final confirmed = await showAct002ElectronicSignatureSaveConfirmDialog(
      context,
      hasChecklistGaps: gaps,
    );
    if (!mounted) return;
    if (!confirmed) return;
    try {
      final bytes = await _controller.toPngBytes();
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('서명을 저장할 수 없습니다. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서명을 저장할 수 없습니다. 다시 시도해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: FormStylePalette.panelBg,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErpDialogHeader(
                title: '전자서명',
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FormStylePalette.textPrimary,
                        side: const BorderSide(color: FormStylePalette.panelBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '초기화',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth.isFinite ? c.maxWidth : 520.0;
                    const h = 280.0;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FormStylePalette.panelBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Signature(
                          key: const ValueKey<String>('act002_sig_pad'),
                          controller: _controller,
                          width: w,
                          height: h,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
