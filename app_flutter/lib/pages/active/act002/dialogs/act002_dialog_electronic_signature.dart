// 활동관리 등록 — 전자서명 입력(마우스·터치).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 다크 톤 헤더·본문(요청 UI에 맞춤).
const Color _kSigHeaderBg = Color(0xFF1E3A5F);
const Color _kSigBodyBg = Color(0xFF243B55);
const Color _kSigAccentBtn = Color(0xFF2563EB);

/// 서명 패드 팝업. [저장] 시 PNG 바이트를 반환, 취소·닫기는 `null`.
///
/// [confirmIfChecklistIncomplete] 가 있으면 저장 직전에 호출되며, `false`면 저장하지 않는다.
Future<Uint8List?> showAct002ElectronicSignatureDialog(
  BuildContext context, {
  Future<bool> Function()? confirmIfChecklistIncomplete,
}) {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _Act002ElectronicSignatureDialogBody(
      confirmIfChecklistIncomplete: confirmIfChecklistIncomplete,
    ),
  );
}

class _Act002ElectronicSignatureDialogBody extends StatefulWidget {
  const _Act002ElectronicSignatureDialogBody({
    this.confirmIfChecklistIncomplete,
  });

  final Future<bool> Function()? confirmIfChecklistIncomplete;

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
    final checker = widget.confirmIfChecklistIncomplete;
    if (checker != null) {
      final ok = await checker();
      if (!mounted) return;
      if (!ok) return;
    }
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
          color: _kSigBodyBg,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(color: _kSigHeaderBg),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '전자서명',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: Colors.white,
                        tooltip: '닫기',
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(40, 40),
                          hoverColor: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _HeaderButton(
                      label: '초기화',
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 10),
                    _HeaderButton(label: '저장', onPressed: _onSave),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth.isFinite ? c.maxWidth : 520.0;
                    const h = 280.0;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColoredBox(
                        color: Colors.white,
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _kSigAccentBtn,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      child: Text(label),
    );
  }
}
