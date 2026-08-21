// 새 결재 기안 — 양식 선택 후 [작성].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

Future<void> showEapNewDraftSheet(BuildContext context) async {
  IframePointerGate.push();
  try {
    final formCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _EapNewDraftSheet(),
    );
    if (!context.mounted || formCode == null || formCode.isEmpty) return;
    context.go(EapRoutes.composeWith(formCode));
  } finally {
    IframePointerGate.pop();
  }
}

class _EapNewDraftSheet extends ConsumerStatefulWidget {
  const _EapNewDraftSheet();

  @override
  ConsumerState<_EapNewDraftSheet> createState() => _EapNewDraftSheetState();
}

class _EapNewDraftSheetState extends ConsumerState<_EapNewDraftSheet> {
  String? _formCode;

  void _onWrite() {
    final forms = ref.read(eapEnabledFormsProvider).valueOrNull;
    final code = _formCode ??
        (forms != null && forms.isNotEmpty ? forms.first.formCode : null);
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결재 양식을 선택해 주세요.')),
      );
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(eapEnabledFormsProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        '새 결재 진행',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  formsAsync.when(
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, _) => const Text(
                      '양식 목록을 불러오지 못했습니다.',
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 13),
                    ),
                    data: (forms) {
                      final items = forms
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.formCode,
                              child: Text('${f.formName} (${f.formCode})'),
                            ),
                          )
                          .toList();
                      final selected = _formCode ??
                          (forms.isNotEmpty ? forms.first.formCode : null);
                      return DropdownButtonFormField<String>(
                        initialValue: selected,
                        decoration: const InputDecoration(
                          labelText: '결재 양식',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: items,
                        onChanged: (v) {
                          if (v != null) setState(() => _formCode = v);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _onWrite,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '작성',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
