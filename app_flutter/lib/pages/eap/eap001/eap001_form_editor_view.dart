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
import 'package:app_flutter/core/web/iframe_pointer_gate.dart';
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
  bool _saving = false;
  bool _deleting = false;
  bool _loaded = false;
  bool _openingBuilder = false;

  bool get _isEdit => (widget.formCode ?? '').isNotEmpty;

  bool get _hasPreview => _previewHtml.trim().isNotEmpty;

  /// 문서분류 선택지 — 기본 목록에, 현재 값이 목록에 없으면 그 값을 덧붙인다.
  /// (예전 서식이나 외부에서 들어온 분류를 잃지 않으면서 화면에도 정확히 보이게 한다.)
  List<String> get _categoryOptions => kEapFormCategories.contains(_category)
      ? kEapFormCategories
      : [_category, ...kEapFormCategories];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _formNoCtrl.dispose();
    _formNameCtrl.dispose();
    super.dispose();
  }

  /// 불러온 서식을 화면 상태에 채운다.
  ///
  /// **build() 안에서 호출되므로 setState 를 쓰지 않는다.** 예전 코드는 여기서
  /// setState 를 불렀는데, 그건 "build 도중 markNeedsBuild" 라 프레임워크가
  /// 이 요소를 더티 목록에 넣었다가 build 끝에 _dirty 를 되돌려 **다시 그리지
  /// 않고 버리는** 상태가 된다. 지금은 이 build 가 아래에서 곧바로 필드를 읽으므로
  /// 값만 대입하면 충분하고, 부작용도 없다.
  void _applyForm(EapFormConfig form) {
    if (_loaded) return;
    _loaded = true;
    final html = eapStoredBodyToHtml(form.contentHtml, form.contentDelta);
    _builderCtrl.setHtml(html);
    _formNoCtrl.text = form.formCode;
    _formNameCtrl.text = form.formName;
    _category = kEapFormCategories.contains(form.category)
        ? form.category
        : form.category.isEmpty
        ? kEapFormCategories.first
        : form.category;
    _previewHtml = html;
    _fieldSchemaJson = form.fieldSchema.isEmpty ? '[]' : form.fieldSchema;
  }

  /// 서식을 못 불러왔을 때 빈 화면 대신 이유를 보여 준다.
  ///
  /// 예전에는 실패해도 그냥 빈 등록 폼이 그려져서, 사용자에겐 "회색 화면"으로만
  /// 보이고 무엇이 잘못됐는지 알 길이 없었다.
  Widget _loadFailure(String message, {Object? error}) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(eapFormDetailProvider(widget.formCode!)),
                    child: const Text('다시 시도'),
                  ),
                  FilledButton(
                    onPressed: () => context.go(EapRoutes.forms),
                    child: const Text('목록으로'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    // 다이얼로그가 떠 있는 동안 뒤쪽 미리보기 iframe 의 마우스 입력을 끈다.
    //
    // iframe 은 Flutter 가 그리는 화면 위에 얹힌 별개의 DOM 이라, 모달을 띄워도
    // **그 위로 겹친 영역의 클릭을 iframe 이 먼저 가져간다.** 그래서 편집기
    // 다이얼로그 안을 눌렀는데 아무 반응이 없는 일이 생긴다.
    // (기안하기 쪽 `_pickLine`·`_pickFormField` 는 이미 이 처리를 하고 있었다.)
    try {
      final result = await IframePointerGate.whileBlocked(
        context,
        () => showEapFormEditorDialog(
          context,
          controller: _builderCtrl,
        ),
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
    // 저장 값은 **화면 상태**에서 가져온다. 편집기 컨트롤러에 다시 묻지 않는다.
    //
    // 예전에는 `_hasPreview` 일 때 `_builderCtrl.getFormData()` 를 호출했는데,
    // 수정 모드에서는 `_applyForm` 이 `_previewHtml` 을 채우므로 `_hasPreview` 가 항상
    // true 다. 그런데 「양식 편집기」를 열지 않았거나 열었다 닫았으면 컨트롤러는
    // 이미 detach 된 상태(`_get == null`)라 **초기값 `'[]'` 를 그대로 돌려준다.**
    // 그 결과 서식명이나 문서분류만 고쳐 저장해도 **fieldSchema 가 통째로 비워졌다.**
    //
    // 두 필드는 이미 정확하다: 로드 시 `_applyForm` 이 저장된 값으로 채우고,
    // 「확인」으로 편집기를 닫을 때 `_openBuilder` 가 결과로 덮어쓴다.
    final formData = (html: _previewHtml, schemaJson: _fieldSchemaJson);
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
        content: Text('${name.isEmpty ? code : name} 서식을 삭제하시겠습니까?'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서식을 삭제했습니다.')));
      context.go(EapRoutes.forms);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제에 실패했습니다.\n$e')));
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

    if (_isEdit && !_loaded) {
      final async = ref.watch(eapFormDetailProvider(widget.formCode!));
      final form = async.valueOrNull;
      if (form != null) {
        _applyForm(form);
      } else if (async.isLoading) {
        return const ColoredBox(
          color: AppTheme.appSurface,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      } else if (async.hasError) {
        return _loadFailure('서식을 불러오지 못했습니다.', error: async.error);
      } else {
        // 요청은 끝났는데 값이 없다 = 삭제됐거나 문서번호가 잘못됐다.
        return _loadFailure('서식 「${widget.formCode}」 을(를) 찾을 수 없습니다.');
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
                    onPressed: (_saving || _deleting)
                        ? null
                        : _confirmAndDelete,
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
                              // 목록에 없는 분류(예전 서식·외부에서 들어온 값)는
                              // **항목으로 추가해서 그대로 보여 준다.**
                              // 예전에는 그런 값을 저장값으로는 유지하면서 화면에는
                              // 목록의 첫 항목('기타문서')을 표시했다. 그래서 사용자가
                              // 손대지 않고 저장하면 **보이는 것과 저장되는 것이 달랐다.**
                              initialValue: _category,
                              items: [
                                for (final c in _categoryOptions)
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
                                  formDesignPreview: true,
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
