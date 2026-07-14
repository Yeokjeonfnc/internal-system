import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/active/act002/dialogs/act002_dialog_lookup.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';
import 'package:app_flutter/pages/master/mst006/mst006_controller.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';

String _formatPhoneNumberOrDash(String value) {
  final formatted = formatKoreanPhoneDisplay(value);
  return formatted.isEmpty ? '-' : formatted;
}

class _Mst006PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final formatted = formatKoreanPhoneDisplay(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

/// 가맹점주 상세.
class OwnerUserDetailView extends ConsumerWidget {
  const OwnerUserDetailView({super.key, required this.userIdx});

  final int userIdx;

  static const List<String> _tabTitles = ['가맹점주 정보'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(ownerUserDetailProvider(userIdx));
    final detail = userAsync.valueOrNull;
    final displayName = detail?.ownerName ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(
        lead: displayName,
        tail: '님 상세 정보',
      ),
      tabTitles: _tabTitles,
      tabPages: [
        userAsync.when(
          data: (u) => _OwnerUserInfoPanel(userIdx: userIdx, user: u),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('가맹점주 정보를 불러오지 못했습니다.')),
        ),
      ],
    );
  }
}

class _OwnerUserInfoPanel extends ConsumerStatefulWidget {
  const _OwnerUserInfoPanel({required this.userIdx, required this.user});

  final int userIdx;
  final OwnerUser? user;

  @override
  ConsumerState<_OwnerUserInfoPanel> createState() =>
      _OwnerUserInfoPanelState();
}

class _OwnerUserInfoPanelState extends ConsumerState<_OwnerUserInfoPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userIdCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;

  bool _isEditing = false;
  bool _saving = false;
  int? _storeIdx;
  String _storeNm = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _userIdCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();
    _applyUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant _OwnerUserInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user && !_isEditing) {
      _applyUser(widget.user);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userIdCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  void _applyUser(OwnerUser? e) {
    if (e == null) return;
    _nameCtrl.text = e.ownerName;
    _userIdCtrl.text = e.userId;
    _phoneCtrl.text = formatKoreanPhoneDisplay(e.mobilePhone);
    _emailCtrl.text = e.email;
    _storeIdx = e.storeIdx;
    _storeNm = e.storeNm;
    _passwordCtrl.clear();
    _passwordConfirmCtrl.clear();
  }

  InputDecoration _fieldDecoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: FormStylePalette.textMuted,
        fontSize: 13,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
      filled: true,
      fillColor: FormStylePalette.inputBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FormStylePalette.accent,
          width: 1.2,
        ),
      ),
    );
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _applyUser(widget.user);
    unawaited(showAlertDialog(context, '취소되었습니다.'));
  }

  Future<void> _pickStore() async {
    if (_saving) return;
    final store = await showDialog<Store>(
      context: context,
      builder: (_) => const StoreLookupDialog(),
    );
    if (store != null && mounted) {
      setState(() {
        _storeIdx = store.storeIdx;
        _storeNm = store.storeNm;
        _nameCtrl.text = store.ownerNm.trim();
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_storeIdx == null) {
      await showAlertDialog(context, '가맹점을 선택해 주세요.');
      return;
    }

    final pw = _passwordCtrl.text;
    final pwc = _passwordConfirmCtrl.text;
    if (pw.isNotEmpty || pwc.isNotEmpty) {
      if (pw != pwc) {
        await showAlertDialog(context, '비밀번호가 일치하지 않습니다.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final body = OwnerUser.buildUpdateRequest(
        ownerName: _nameCtrl.text,
        userPassword: pw,
        userId: _userIdCtrl.text,
        storeIdx: _storeIdx,
        mobilePhone: formatKoreanPhoneDisplay(_phoneCtrl.text),
        email: _emailCtrl.text,
      );
      await ref.read(mst006ApiServiceProvider).updateOwner(widget.userIdx, body);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isEditing = false;
      });
      ref.invalidate(ownerUserDataProvider);
      ref.invalidate(ownerUserDetailProvider(widget.userIdx));
      await showAlertDialog(context, '저장되었습니다.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showAlertDialog(context, '저장에 실패했습니다.\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: Text('가맹점주를 찾을 수 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FormStylePalette.formMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FormStylePalette.panelBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FormStylePalette.panelBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OwnerUserPanelHeader(
                      title: '가맹점주 상세 정보',
                      isEditing: _isEditing,
                      isSaving: _saving,
                      onEnterEdit: _enterEdit,
                      onSave: _save,
                      onCancel: _cancelEdit,
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: FormStylePalette.panelBorder,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LabeledFormRow(
                            label: '가맹점명',
                            child: _isEditing
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ReadonlyValue(
                                          _storeNm.isEmpty ? '-' : _storeNm,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: OutlinedButton(
                                          onPressed:
                                              _saving ? null : _pickStore,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                FormStylePalette.accent,
                                            side: const BorderSide(
                                              color: FormStylePalette.accent,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            minimumSize: const Size(0, 40),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            '검색',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontFamilyFallback:
                                                  AppTheme.koreanFontFallback,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ReadonlyValue(
                                    _storeNm.isEmpty ? '-' : _storeNm,
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '점주명',
                            requiredField: true,
                            child: ReadonlyValue(
                              _nameCtrl.text.trim().isEmpty
                                  ? '-'
                                  : _nameCtrl.text.trim(),
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '로그인 ID',
                            child: ReadonlyValue(
                              _userIdCtrl.text.trim().isEmpty
                                  ? '-'
                                  : _userIdCtrl.text.trim(),
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 15),
                            LabeledFormRow(
                              label: '비밀번호 변경',
                              child: TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: _fieldDecoration('변경 시에만 입력'),
                              ),
                            ),
                            const SizedBox(height: 15),
                            LabeledFormRow(
                              label: '비밀번호 확인',
                              child: TextFormField(
                                controller: _passwordConfirmCtrl,
                                obscureText: true,
                                decoration: _fieldDecoration(
                                  '비밀번호 변경 시 동일하게 입력',
                                ),
                                validator: (v) {
                                  final a = _passwordCtrl.text;
                                  final b = v ?? '';
                                  if (a.isEmpty && b.isEmpty) return null;
                                  if (a != b) {
                                    return '비밀번호가 일치하지 않습니다.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '휴대전화',
                            child: _isEditing
                                ? TextFormField(
                                    controller: _phoneCtrl,
                                    decoration: _fieldDecoration(
                                      '휴대전화 번호를 입력하세요.',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      _Mst006PhoneInputFormatter(),
                                    ],
                                  )
                                : ReadonlyValue(
                                    _formatPhoneNumberOrDash(_phoneCtrl.text),
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '이메일주소',
                            child: _isEditing
                                ? TextFormField(
                                    controller: _emailCtrl,
                                    decoration: _fieldDecoration(
                                      '이메일 주소를 입력하세요.',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      final t = v?.trim() ?? '';
                                      if (t.isEmpty) return null;
                                      final emailRegex = RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                      );
                                      if (!emailRegex.hasMatch(t)) {
                                        return '올바른 이메일 형식이 아닙니다.';
                                      }
                                      return null;
                                    },
                                  )
                                : ReadonlyValue(
                                    _emailCtrl.text.trim().isEmpty
                                        ? '-'
                                        : _emailCtrl.text.trim(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerUserPanelHeader extends StatelessWidget {
  const _OwnerUserPanelHeader({
    required this.title,
    required this.isEditing,
    required this.isSaving,
    required this.onEnterEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEnterEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: FormStylePalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        if (isEditing) ...[
          SaveActionButton(
            menuCd: kMenuMst006,
            onPressed: isSaving ? () {} : onSave,
          ),
          const SizedBox(width: 8),
          CancelActionButton(onPressed: onCancel),
        ] else
          EditActionButton(menuCd: kMenuMst006, onPressed: onEnterEdit),
      ],
    );
  }
}
