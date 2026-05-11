// 마스터 — 사원 상세 화면.

import 'dart:async';

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
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_model.dart';
import 'package:app_flutter/pages/master/mst002/mst002_repo.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';

/// 직급 코드 그룹 (`grp_cd = 60`).
const int _kUserPositionGrpCd = 60;

void _flattenDepartmentTree(List<Department> roots, List<Department> out) {
  for (final d in roots) {
    out.add(d);
    _flattenDepartmentTree(d.children, out);
  }
}

String _formatPhoneNumberOrDash(String value) {
  final formatted = formatKoreanPhoneDisplay(value);
  return formatted.isEmpty ? '-' : formatted;
}

Department? _findDeptByName(List<Department> flat, String name) {
  for (final d in flat) {
    if (d.name == name) return d;
  }
  return null;
}

DateTime? _parseJoinDtYmd(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.length < 10) return null;
  try {
    return DateTime.parse(t.substring(0, 10));
  } catch (_) {
    return null;
  }
}

/// 웹 IME 조합 중 assertion 방지(사원 등록 화면과 동일 패턴).
class _Mst001PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

/// 사원 상세.
///
/// [PartnerDetailView] 와 같이 [DetailScreenWithTabs] + 패널 헤더(수정/저장/취소) 패턴을 쓴다.
class UserDetailView extends ConsumerWidget {
  const UserDetailView({super.key, required this.userIdx});

  final int userIdx;

  static const List<String> _tabTitles = ['사원 상세 정보'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userIdx));
    final detail = userAsync.valueOrNull;
    final displayName = detail?.name ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(lead: displayName, tail: '님 상세 정보'),
      tabTitles: _tabTitles,
      tabPages: [
        userAsync.when(
          data: (u) => _UserInfoPanel(userIdx: userIdx, user: u),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('사원 정보를 불러오지 못했습니다.')),
        ),
      ],
    );
  }
}

class _UserInfoPanel extends ConsumerStatefulWidget {
  const _UserInfoPanel({required this.userIdx, required this.user});

  final int userIdx;
  final User? user;

  @override
  ConsumerState<_UserInfoPanel> createState() => _UserInfoPanelState();
}

class _UserInfoPanelState extends ConsumerState<_UserInfoPanel> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _saving = false;

  late final TextEditingController _userIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;

  final _departmentRepository = DepartmentRepository();
  List<Department> _flatDepartments = [];
  bool _departmentsLoading = true;
  String? _selectedDeptId;
  String? _selectedPositionCd;
  TagYn _tagYn = TagYn.untagged;
  DateTime? _joinDt;

  String? _verifiedUserIdTrim;
  String _originalUserIdTrim = '';

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
    _applyUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant _UserInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user && !_isEditing) {
      _applyUser(widget.user);
    }
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

  void _onUserIdTextChanged() {
    final t = _userIdCtrl.text.trim();
    final v = _verifiedUserIdTrim;
    if (v != null && v != t) {
      setState(() => _verifiedUserIdTrim = null);
    }
  }

  Future<void> _loadDepartments() async {
    final roots = await _departmentRepository.all();
    if (!mounted) return;
    final flat = <Department>[];
    _flattenDepartmentTree(roots, flat);
    setState(() {
      _flatDepartments = flat;
      _departmentsLoading = false;
    });
    _applyUser(widget.user);
  }

  void _applyUser(User? e) {
    if (e == null) return;
    _nameCtrl.text = e.name;
    _userIdCtrl.text = e.userId;
    _originalUserIdTrim = e.userId.trim();
    _verifiedUserIdTrim = _originalUserIdTrim.isEmpty
        ? null
        : _originalUserIdTrim;
    _phoneCtrl.text = formatKoreanPhoneDisplay(e.mobilePhone);
    _emailCtrl.text = e.email;
    _tagYn = e.tagYn;
    _joinDt = _parseJoinDtYmd(e.joinDt);
    _passwordCtrl.clear();
    _passwordConfirmCtrl.clear();

    final di = e.deptIdx;
    if (di != null) {
      final idStr = di.toString();
      if (_flatDepartments.any((d) => d.id == idStr)) {
        _selectedDeptId = idStr;
      } else {
        _selectedDeptId =
            _findDeptByName(_flatDepartments, e.department)?.id ??
            _selectedDeptId;
      }
    } else {
      _selectedDeptId = _findDeptByName(_flatDepartments, e.department)?.id;
    }

    final posCd = e.positionCd?.trim();
    if (posCd != null && posCd.isNotEmpty) {
      _selectedPositionCd = posCd;
    } else {
      _selectedPositionCd = null;
    }
    if (mounted) setState(() {});
  }

  String? get _effectiveDeptId {
    if (_flatDepartments.isEmpty) return null;
    final id = _selectedDeptId;
    if (id != null && _flatDepartments.any((d) => d.id == id)) return id;
    return _flatDepartments.first.id;
  }

  String _effectivePositionCd(List<CodeOption> options) {
    if (options.isEmpty) return '';
    final cur = _selectedPositionCd;
    if (cur != null && options.any((o) => o.codeCd == cur)) {
      return cur;
    }
    final e = widget.user;
    if (e != null) {
      for (final o in options) {
        if (o.codeNm == e.positionNm) return o.codeCd;
      }
    }
    return options.first.codeCd;
  }

  String _joinDtYmdForApi() {
    final d = _joinDt;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _joinReadonlyDisplay() {
    final ymd = _joinDtYmdForApi();
    if (ymd.isNotEmpty) return ymd;
    final s = widget.user?.joinDt ?? '';
    return s.isEmpty ? '-' : s;
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
    if (t == _originalUserIdTrim) return true;
    return _verifiedUserIdTrim == t;
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _applyUser(widget.user);
    unawaited(showAlertDialog(context, '취소되었습니다.'));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final pw = _passwordCtrl.text;
    final pwc = _passwordConfirmCtrl.text;
    if (pw.isNotEmpty || pwc.isNotEmpty) {
      if (pw != pwc) {
        await showAlertDialog(context, '비밀번호가 일치하지 않습니다.');
        return;
      }
    }

    if (!_isLoginIdDuplicateCheckOk()) {
      await showAlertDialog(context, '로그인 ID 중복 확인을 해 주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final positionOpts =
          ref.read(codeOptionsProvider(_kUserPositionGrpCd)).value ??
          const <CodeOption>[];
      final deptIdx = int.tryParse(_effectiveDeptId ?? '');
      final body = User.buildUpdateUserRequest(
        name: _nameCtrl.text,
        userPassword: pw,
        userId: _userIdCtrl.text,
        deptIdx: deptIdx,
        mobilePhone: formatKoreanPhoneDisplay(_phoneCtrl.text),
        email: _emailCtrl.text,
        joinDt: _joinDtYmdForApi(),
        positionCd: _effectivePositionCd(positionOpts),
        tagYn: _tagYn == TagYn.tagged,
      );
      await ref.read(mst001ApiServiceProvider).updateUser(widget.userIdx, body);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isEditing = false;
      });
      ref.invalidate(userDataProvider);
      ref.invalidate(userDetailProvider(widget.userIdx));
      await showAlertDialog(context, '저장되었습니다.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showAlertDialog(context, '저장에 실패했습니다.\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(codeOptionsProvider(_kUserPositionGrpCd));
    final positionOptions = positionAsync.value ?? const <CodeOption>[];

    if (widget.user == null) {
      return const Center(child: Text('사원을 찾을 수 없습니다.'));
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
                    _UserPanelHeader(
                      title: '사원 상세 정보',
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
                            label: '이름',
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
                                  if (a != b) return '비밀번호가 일치하지 않습니다.';
                                  return null;
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '부서',
                            child: _isEditing
                                ? (_departmentsLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
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
                                                  style: FormStylePalette
                                                      .valueStyle,
                                                ),
                                              ),
                                          ],
                                          onChanged: (v) {
                                            setState(() => _selectedDeptId = v);
                                          },
                                        ))
                                : ReadonlyValue(
                                    widget.user!.department.isEmpty
                                        ? '-'
                                        : widget.user!.department,
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '직급(직책)',
                            child: _isEditing
                                ? (positionAsync.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
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
                                          '직급 코드(그룹 $_kUserPositionGrpCd)가 없습니다.',
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
                                                  style: FormStylePalette
                                                      .valueStyle,
                                                ),
                                              ),
                                          ],
                                          onChanged: (v) {
                                            setState(
                                              () => _selectedPositionCd = v,
                                            );
                                          },
                                        ))
                                : ReadonlyValue(
                                    widget.user!.positionNm.isEmpty
                                        ? '-'
                                        : widget.user!.positionNm,
                                  ),
                          ),
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
                                      _Mst001PhoneInputFormatter(),
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
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '태그사용여부',
                            child: _isEditing
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: CheckboxListTile(
                                      value: _tagYn == TagYn.tagged,
                                      onChanged: _saving
                                          ? null
                                          : (v) {
                                              setState(
                                                () => _tagYn = v == true
                                                    ? TagYn.tagged
                                                    : TagYn.untagged,
                                              );
                                            },
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: AppTheme.accentRed,
                                      title: Text(
                                        '태그 사용 허용',
                                        style: FormStylePalette.valueStyle
                                            .copyWith(fontSize: 13),
                                      ),
                                    ),
                                  )
                                : _TagYnFieldChip(
                                    tagYn: widget.user?.tagYn ?? _tagYn,
                                  ),
                          ),
                          const SizedBox(height: 15),
                          LabeledFormRow(
                            label: '입사년월일',
                            child: ReadonlyValue(_joinReadonlyDisplay()),
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

class _UserPanelHeader extends StatelessWidget {
  const _UserPanelHeader({
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
          SaveActionButton(onPressed: isSaving ? () {} : onSave),
          const SizedBox(width: 8),
          CancelActionButton(onPressed: onCancel),
        ] else
          EditActionButton(onPressed: onEnterEdit),
      ],
    );
  }
}

/// 읽기 전용 — 태그 사용 여부를 칩 형태로 표시한다.
class _TagYnFieldChip extends StatelessWidget {
  const _TagYnFieldChip({required this.tagYn});

  final TagYn tagYn;

  @override
  Widget build(BuildContext context) {
    final tagged = tagYn == TagYn.tagged;
    final (Color fg, Color bg, Color border) = tagged
        ? (
            const Color.fromARGB(255, 224, 38, 116),
            const Color(0xFFEDE9FE),
            const Color(0xFFC4B5FD),
          )
        : (
            const Color(0xFF065F46),
            const Color(0xFFD1FAE5),
            const Color(0xFFA7F3D0),
          );
    final label = tagged ? '사용' : '미사용';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }
}
