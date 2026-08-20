import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/base_repository.dart'
    show formatApiUserMessage;
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
import 'package:app_flutter/pages/master/mst001/mst001_api.dart';
import 'package:app_flutter/pages/master/mst006/mst006_api.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  const PhoneNumberFormatter();

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

/// 가맹점주 등록.
class OwnerUserRegisterView extends ConsumerStatefulWidget {
  const OwnerUserRegisterView({super.key});

  static const List<String> _tabTitles = ['가맹점주 정보'];

  @override
  ConsumerState<OwnerUserRegisterView> createState() =>
      _OwnerUserRegisterViewState();
}

class _OwnerUserRegisterViewState extends ConsumerState<OwnerUserRegisterView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userIdCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  int? _storeIdx;
  String _storeNm = '';
  String? _verifiedUserIdTrim;
  bool _checkingUserId = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _userIdCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _userIdCtrl.addListener(_onUserIdTextChanged);
  }

  @override
  void dispose() {
    _userIdCtrl.removeListener(_onUserIdTextChanged);
    _nameCtrl.dispose();
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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

  bool _isLoginIdDuplicateCheckOk() {
    final t = _userIdCtrl.text.trim();
    if (t.isEmpty) return true;
    return _verifiedUserIdTrim == t;
  }

  void _onUserIdTextChanged() {
    final t = _userIdCtrl.text.trim();
    final v = _verifiedUserIdTrim;
    if (v != null && v != t) {
      setState(() => _verifiedUserIdTrim = null);
    }
  }

  Future<void> _checkLoginIdDuplicate() async {
    if (_checkingUserId) return;
    final t = _userIdCtrl.text.trim();
    if (t.isEmpty) {
      await showAlertDialog(context, '로그인 ID를 입력한 뒤 중복 확인을 해 주세요.');
      return;
    }
    setState(() => _checkingUserId = true);
    try {
      final available = await Mst001ApiService().isUserIdAvailable(t);
      if (!mounted) return;
      setState(() {
        _checkingUserId = false;
        _verifiedUserIdTrim = available ? t : null;
      });
      if (available) {
        await showAlertDialog(context, '사용 가능한 로그인 ID입니다.');
      } else {
        await showAlertDialog(context, '이미 사용 중인 로그인 ID입니다.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingUserId = false;
        _verifiedUserIdTrim = null;
      });
      await showAlertDialog(context, '중복 확인에 실패했습니다.\n$e');
    }
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
    if (_passwordCtrl.text != _passwordConfirmCtrl.text) {
      await showAlertDialog(context, '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!_isLoginIdDuplicateCheckOk()) {
      await showAlertDialog(context, '로그인 ID 중복 확인을 해 주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final body = OwnerUser.buildCreateRequest(
        ownerName: _nameCtrl.text,
        userPassword: _passwordCtrl.text,
        userId: _userIdCtrl.text,
        storeIdx: _storeIdx!,
        mobilePhone: _phoneCtrl.text,
        email: _emailCtrl.text,
      );
      await Mst006ApiService().createOwner(body);
      if (!mounted) return;
      await showAlertDialog(context, '가맹점주가 등록되었습니다.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // 중복확인을 통과한 뒤에도 저장 사이에 같은 ID 가 먼저 등록될 수 있다.
      // 서버가 내려준 사유를 그대로 보여 줘야 무엇을 고쳐야 하는지 알 수 있다.
      await showAlertDialog(
        context,
        formatApiUserMessage(e, fallback: '등록에 실패했습니다.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScreenWithTabs(
      title: DetailScreenHeadline.plain(text: '가맹점주 등록'),
      tabTitles: OwnerUserRegisterView._tabTitles,
      tabPages: [
        SingleChildScrollView(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '가맹점주 정보',
                                  style: TextStyle(
                                    color: FormStylePalette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamilyFallback:
                                        AppTheme.koreanFontFallback,
                                  ),
                                ),
                              ),
                              SaveActionButton(
                                menuCd: kMenuMst006,
                                forCreate: true,
                                onPressed: _save,
                              ),
                              const SizedBox(width: 8),
                              CancelActionButton(onPressed: _cancel),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(
                            color: FormStylePalette.panelBorder,
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          LabeledFormRow(
                            label: '가맹점명',
                            requiredField: true,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    onPressed: _saving ? null : _pickStore,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: FormStylePalette.accent,
                                      side: const BorderSide(
                                        color: FormStylePalette.accent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      minimumSize: const Size(0, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
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
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '점주명',
                            requiredField: true,
                            child: TextFormField(
                              controller: _nameCtrl,
                              enabled: !_saving,
                              decoration: _fieldDecoration('점주명을 입력하세요.'),
                              validator: (v) => v?.trim().isEmpty ?? true
                                  ? '점주명을 입력하세요.'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '로그인 ID',
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _userIdCtrl,
                                    decoration: _fieldDecoration(
                                      '로그인 ID를 입력하세요.',
                                    ),
                                    enabled: !_saving,
                                    validator: (v) {
                                      final t = v?.trim() ?? '';
                                      if (t.isEmpty) return null;
                                      if (!_isLoginIdDuplicateCheckOk()) {
                                        return '중복 확인을 해 주세요.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: OutlinedButton(
                                    onPressed: _saving || _checkingUserId
                                        ? null
                                        : _checkLoginIdDuplicate,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: FormStylePalette.accent,
                                      side: const BorderSide(
                                        color: FormStylePalette.accent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      minimumSize: const Size(0, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: _checkingUserId
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: FormStylePalette.accent,
                                            ),
                                          )
                                        : Text(
                                            '중복확인',
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
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '비밀번호',
                            requiredField: true,
                            child: TextFormField(
                              controller: _passwordCtrl,
                              enabled: !_saving,
                              obscureText: true,
                              decoration: _fieldDecoration('비밀번호를 입력하세요.'),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return '비밀번호를 입력하세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '비밀번호 확인',
                            requiredField: true,
                            child: TextFormField(
                              controller: _passwordConfirmCtrl,
                              enabled: !_saving,
                              obscureText: true,
                              decoration: _fieldDecoration('비밀번호를 다시 입력하세요.'),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return '비밀번호 확인을 입력하세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '휴대전화',
                            child: TextFormField(
                              controller: _phoneCtrl,
                              enabled: !_saving,
                              decoration: _fieldDecoration('휴대전화 번호를 입력하세요.'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: const [PhoneNumberFormatter()],
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '이메일주소',
                            child: TextFormField(
                              controller: _emailCtrl,
                              enabled: !_saving,
                              decoration: _fieldDecoration('이메일 주소를 입력하세요.'),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
