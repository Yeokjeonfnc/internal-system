// 새 결재 기안 — 다우오피스 연동 준비 UI.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

Future<void> showEapNewDraftSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _EapNewDraftSheet(),
  );
}

class _EapNewDraftSheet extends StatefulWidget {
  const _EapNewDraftSheet();

  @override
  State<_EapNewDraftSheet> createState() => _EapNewDraftSheetState();
}

class _EapNewDraftSheetState extends State<_EapNewDraftSheet> {
  String _formCode = 'yeokjeon_eap01';
  final _titleCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결재 제목을 입력해 주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '다우오피스 기안 API 연결 후 결재 화면으로 이동합니다.\n'
          '(백엔드 /api/eap/draft 구현 필요)',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  DropdownButtonFormField<String>(
                    value: _formCode,
                    decoration: _fieldDeco('결재 양식'),
                    items: const [
                      DropdownMenuItem(
                        value: 'yeokjeon_eap01',
                        child: Text('품의 기본 (연동)'),
                      ),
                      DropdownMenuItem(
                        value: 'yeokjeon_eap02',
                        child: Text('지출결의서 (연동)'),
                      ),
                      DropdownMenuItem(
                        value: 'yeokjeon_eap03',
                        child: Text('휴가신청서 (연동)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _formCode = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _fieldDeco('결재 제목'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('다우오피스에서 기안'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.inputBorder),
      ),
    );
  }
}
