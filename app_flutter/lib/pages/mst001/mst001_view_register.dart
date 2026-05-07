// 마스터 — 사원 등록 화면.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/format/korean_phone_display.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/pages/mst002/mst002_model.dart';
import 'package:app_flutter/pages/mst002/mst002_repo.dart';
import 'package:app_flutter/pages/mst001/mst001_model.dart';
import 'package:app_flutter/pages/mst001/mst001_api.dart';
import 'package:app_flutter/pages/str001/str001_controller.dart';

/// 직급 코드 그룹 ([UserService] 의 `grp_cd = 60` 과 동일).
const int _kEmployeePositionGrpCd = 60;

void _flattenDepartmentTree(List<Department> roots, List<Department> out) {
  for (final d in roots) {
    out.add(d);
    _flattenDepartmentTree(d.children, out);
  }
}

/// 사원 등록 화면.
///
/// 폼 필드는 [Employee] 의 의미(이름·부서명·직급명·휴대전화·이메일·태그)와 맞추고,
/// 저장 시 [Employee.buildCreateUserRequest] 로 `/users` POST 본문을 만든다.
class EmployeeRegisterView extends ConsumerStatefulWidget {
  const EmployeeRegisterView({super.key});

  static const List<String> _tabTitles = ['사원정보'];

  @override
  ConsumerState<EmployeeRegisterView> createState() =>
      _EmployeeRegisterViewState();
}

class PhoneNumberFormatter extends TextInputFormatter {
  const PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 웹 IME: 조합 중에 숫자만 남기면 text는 비는데 composing 만 남아
    // TextInputClient.updateEditingState assertion 이 날 수 있음.
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }
    final formatted = formatKoreanPhoneDisplay(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

class _EmployeeRegisterViewState extends ConsumerState<EmployeeRegisterView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _userIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;

  final _departmentRepository = DepartmentRepository();

  List<Department> _flatDepartments = [];
  bool _departmentsLoading = true;

  /// [Department.id] (`deptIdx` 문자열) — 파싱 실패 시에도 드롭다운 값과 일치시키기 위해 문자열로 둔다.
  String? _selectedDeptId;
  String? _selectedPositionCd;

  /// [Employee.tagYn] 와 동일 — API `svYn`
  bool _tagYn = false;
  bool _saving = false;

  /// 로그인 ID를 입력했을 때만 사용. [trim] 값과 일치하면 중복확인 통과로 본다.
  String? _verifiedUserIdTrim;

  bool _checkingUserId = false;

  /// 입사년월일(선택). API `joinDt` 는 `yyyy-MM-dd` 문자열.
  DateTime? _joinDt;

  String _joinDtYmdForApi() {
    final d = _joinDt;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickJoinDt() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _joinDt ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _joinDt = picked);
    }
  }

  String _effectivePositionCd(List<CodeOption> options) {
    if (options.isEmpty) return '';
    final cur = _selectedPositionCd;
    if (cur != null && options.any((e) => e.codeCd == cur)) {
      return cur;
    }
    return options.first.codeCd;
  }

  /// 부서 드롭다운·저장 시 공통. 목록이 비면 null.
  String? get _effectiveDeptId {
    if (_flatDepartments.isEmpty) return null;
    final id = _selectedDeptId;
    if (id != null && _flatDepartments.any((d) => d.id == id)) return id;
    return _flatDepartments.first.id;
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
      final available = await Emp001ApiService().isUserIdAvailable(t);
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

  @override
  void initState() {
    super.initState();
    _userIdCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();
    _userIdCtrl.addListener(_onUserIdTextChanged);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final roots = await _departmentRepository.all();
    if (!mounted) return;
    final flat = <Department>[];
    _flattenDepartmentTree(roots, flat);
    setState(() {
      _flatDepartments = flat;
      _departmentsLoading = false;
      if (_selectedDeptId == null && flat.isNotEmpty) {
        _selectedDeptId = flat.first.id;
      }
    });
  }

  @override
  void dispose() {
    _userIdCtrl.removeListener(_onUserIdTextChanged);
    _userIdCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
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
      final positionOpts =
          ref.read(codeOptionsProvider(_kEmployeePositionGrpCd)).value ??
          const <CodeOption>[];
      final deptIdx = int.tryParse(_effectiveDeptId ?? '');
      final body = Employee.buildCreateUserRequest(
        name: _nameCtrl.text,
        userPassword: _passwordCtrl.text,
        userId: _userIdCtrl.text,
        deptIdx: deptIdx,
        mobilePhone: formatKoreanPhoneDisplay(_phoneCtrl.text),
        email: _emailCtrl.text,
        joinDt: _joinDtYmdForApi(),
        positionCd: _effectivePositionCd(positionOpts),
        tagYn: _tagYn,
      );
      await Emp001ApiService().createUser(body);
      if (!mounted) return;
      await showAlertDialog(context, '사원이 등록되었습니다.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await showAlertDialog(context, '등록에 실패했습니다.\n$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(
      codeOptionsProvider(_kEmployeePositionGrpCd),
    );
    final positionOptions = positionAsync.value ?? const <CodeOption>[];

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.plain(text: '사원 등록'),
      tabTitles: EmployeeRegisterView._tabTitles,
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
                                  '사원정보',
                                  style: TextStyle(
                                    color: FormStylePalette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamilyFallback:
                                        AppTheme.koreanFontFallback,
                                  ),
                                ),
                              ),
                              SaveActionButton(onPressed: _save),
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
                            label: '이름',
                            requiredField: true,
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: _fieldDecoration('이름을 입력하세요.'),
                              validator: (v) => v?.trim().isEmpty ?? true
                                  ? '이름을 입력하세요.'
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
                            label: '부서',
                            child: _departmentsLoading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : _flatDepartments.isEmpty
                                ? Text(
                                    '등록된 부서가 없습니다.',
                                    style: TextStyle(
                                      color: FormStylePalette.textMuted,
                                      fontSize: 13,
                                      fontFamilyFallback:
                                          AppTheme.koreanFontFallback,
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: _effectiveDeptId,
                                    decoration: _fieldDecoration('부서 선택'),
                                    items: [
                                      for (final d in _flatDepartments)
                                        DropdownMenuItem<String>(
                                          value: d.id,
                                          child: Text(
                                            d.name,
                                            style: FormStylePalette.valueStyle,
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _selectedDeptId = v);
                                    },
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '직급(직책)',
                            child: positionAsync.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : positionOptions.isEmpty
                                ? Text(
                                    '직급 코드(그룹 $_kEmployeePositionGrpCd)가 없습니다.',
                                    style: TextStyle(
                                      color: FormStylePalette.textMuted,
                                      fontSize: 13,
                                      fontFamilyFallback:
                                          AppTheme.koreanFontFallback,
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: _effectivePositionCd(
                                      positionOptions,
                                    ),
                                    decoration: _fieldDecoration('직급 선택'),
                                    items: [
                                      for (final o in positionOptions)
                                        DropdownMenuItem<String>(
                                          value: o.codeCd,
                                          child: Text(
                                            o.codeNm,
                                            style: FormStylePalette.valueStyle,
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _selectedPositionCd = v);
                                    },
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '휴대전화',
                            child: TextFormField(
                              controller: _phoneCtrl,
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
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '태그사용여부',
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CheckboxListTile(
                                value: _tagYn,
                                onChanged: _saving
                                    ? null
                                    : (v) {
                                        setState(() => _tagYn = v ?? false);
                                      },
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppTheme.accentRed,
                                title: Text(
                                  '태그 사용 허용',
                                  style: FormStylePalette.valueStyle.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '입사년월일',
                            child: DateInputWithPicker(
                              value: _joinDt,
                              onPick: _saving ? null : _pickJoinDt,
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(() => _joinDt = value),
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
