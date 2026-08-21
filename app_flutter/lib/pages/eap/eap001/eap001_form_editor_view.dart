// 전자결재 서식 등록·수정 — 다우오피스형 양식 편집기.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/eap/eap001/dialogs/eap001_dialog_form_builder.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_content_html_preview.dart';
import 'package:app_flutter/pages/eap/eap001/eap_form_builder.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_provider.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_quill.dart';
import 'package:app_flutter/pages/eap/shared/eap_routes.dart';

class Eap001FormEditorView extends ConsumerStatefulWidget {
  const Eap001FormEditorView({super.key, this.formCode});

  final String? formCode;

  @override
  ConsumerState<Eap001FormEditorView> createState() =>
      _Eap001FormEditorViewState();
}

class _Eap001FormEditorViewState extends ConsumerState<Eap001FormEditorView> {
  final _formNoCtrl = TextEditingController();
  final _formNameCtrl = TextEditingController();
  final _builderCtrl = EapFormBuilderController();

  String _category = kEapFormCategories.first;
  String _previewHtml = '';
  String _fieldSchemaJson = '[]';
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  bool _loaded = false;
  bool _openingBuilder = false;

  bool get _isEdit => (widget.formCode ?? '').isNotEmpty;

  bool get _hasPreview => _previewHtml.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loading = true;
  }

  @override
  void dispose() {
    _formNoCtrl.dispose();
    _formNameCtrl.dispose();
    super.dispose();
  }

  void _applyForm(EapFormConfig form) {
    if (_loaded) return;
    _loaded = true;
    final html = eapStoredBodyToHtml(form.contentHtml, form.contentDelta);
    _builderCtrl.setHtml(html);
    setState(() {
      _formNoCtrl.text = form.formCode;
      _formNameCtrl.text = form.formName;
      _category = kEapFormCategories.contains(form.category)
          ? form.category
          : form.category.isEmpty
          ? kEapFormCategories.first
          : form.category;
      _previewHtml = html;
      _fieldSchemaJson = form.fieldSchema.isEmpty ? '[]' : form.fieldSchema;
      _loading = false;
    });
  }

  InputDecoration get _dec => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: FormStylePalette.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: FormStylePalette.accent, width: 1.4),
    ),
  );

  Future<void> _openBuilder() async {
    if (_openingBuilder) return;
    setState(() => _openingBuilder = true);
    try {
      final result = await showEapFormEditorDialog(
        context,
        controller: _builderCtrl,
      );
      if (!mounted || result == null) return;
      setState(() {
        _previewHtml = result.html;
        _fieldSchemaJson = result.schemaJson;
      });
    } finally {
      if (mounted) setState(() => _openingBuilder = false);
    }
  }

  Future<void> _save() async {
    final name = _formNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기본정보에서 서식명을 입력해 주세요.')));
      return;
    }
    final formData = _hasPreview
        ? await _builderCtrl.getFormData()
        : (html: _previewHtml, schemaJson: _fieldSchemaJson);
    final html = formData.html;
    if (html.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('양식 편집기에서 서식을 작성해 주세요.')));
      return;
    }
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    final today = DateTime.now();
    final form = EapFormConfig(
      formCode: _formNoCtrl.text.trim(),
      formName: name,
      category: _category,
      contentHtml: html,
      fieldSchema: formData.schemaJson,
      createdBy: auth.userId,
      createdByNm: auth.userName,
      createdAt: today,
    );
    setState(() => _saving = true);
    try {
      final api = ref.read(eapApiProvider);
      if (_isEdit) {
        await api.updateForm(form);
      } else {
        await api.createForm(form);
      }
      if (!mounted) return;
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
      if (_isEdit) {
        ref.invalidate(eapFormDetailProvider(form.formCode));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '서식을 수정했습니다.' : '서식을 등록했습니다.')),
      );
      context.go(EapRoutes.forms);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다.\n$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final name = _formNameCtrl.text.trim();
    final code = widget.formCode ?? '';
    if (code.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('서식 삭제'),
        content: Text(
          '${name.isEmpty ? code : name} 서식을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(eapApiProvider).deleteForm(code);
      if (!mounted) return;
      ref.invalidate(eapFormsProvider);
      ref.invalidate(eapEnabledFormsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서식을 삭제했습니다.')),
      );
      context.go(EapRoutes.forms);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했습니다.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = provider.Provider.of<AuthProvider>(context);
    final today = DateTime.now();
    final dateLabel =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (_isEdit) {
      final async = ref.watch(eapFormDetailProvider(widget.formCode!));
      async.whenData((form) {
        if (form != null) _applyForm(form);
      });
      if (_loading && !async.hasValue && !async.hasError) {
        return const ColoredBox(
          color: AppTheme.appSurface,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
    }

    return ColoredBox(
      color: AppTheme.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Text(
                  _isEdit ? '서식 수정' : '서식 등록',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                const Spacer(),
                if (_isEdit && auth.isSuperAdmin) ...[
                  OutlinedButton(
                    onPressed: (_saving || _deleting) ? null : _confirmAndDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                    ),
                    child: Text(_deleting ? '삭제 중...' : '삭제'),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton(
                  onPressed: (_saving || _deleting)
                      ? null
                      : () => context.go(EapRoutes.forms),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: (_saving || _deleting) ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_saving ? '저장 중...' : '저장'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      border: Border.all(color: AppTheme.hairline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LabeledFormRow(
                            label: '문서분류',
                            requiredField: true,
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  kEapFormCategories.contains(_category)
                                  ? _category
                                  : kEapFormCategories.first,
                              items: [
                                for (final c in kEapFormCategories)
                                  DropdownMenuItem(value: c, child: Text(c)),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                              decoration: _dec,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '서식명',
                            requiredField: true,
                            child: TextField(
                              controller: _formNameCtrl,
                              decoration: _dec.copyWith(hintText: '서식명'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '문서번호',
                            child: _isEdit
                                ? ReadonlyValue(_formNoCtrl.text)
                                : const ReadonlyValue('저장 시 자동 부여'),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '등록일·등록자',
                            child: ReadonlyValue(
                              '$dateLabel / ${auth.userName.isEmpty ? auth.userId : auth.userName}',
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '양식 편집',
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _openingBuilder
                                    ? null
                                    : _openBuilder,
                                icon: const Icon(
                                  Icons.edit_note_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  _openingBuilder ? '편집기 여는 중...' : '양식 편집기',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        border: Border.all(color: AppTheme.hairline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              children: [
                                const Text(
                                  '서식 미리보기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamilyFallback:
                                        AppTheme.koreanFontFallback,
                                  ),
                                ),
                                const Spacer(),
                                if (_hasPreview)
                                  TextButton.icon(
                                    onPressed: _openingBuilder
                                        ? null
                                        : _openBuilder,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('다시 편집'),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.hairline),
                          if (_hasPreview)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                                child: eapContentHtmlPreview(
                                  _previewHtml,
                                  seamless: true,
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '「양식 편집기」에서 표와 본문을 작성하세요.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          fontFamilyFallback:
                                              AppTheme.koreanFontFallback,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
