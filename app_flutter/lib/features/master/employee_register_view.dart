// 마스터 — 사원 등록 화면.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/features/master/employee_controller.dart';

/// 사원 등록 화면.
class EmployeeRegisterView extends ConsumerStatefulWidget {
  const EmployeeRegisterView({super.key});

  static const List<String> _tabTitles = ['사원정보'];

  @override
  ConsumerState<EmployeeRegisterView> createState() =>
      _EmployeeRegisterViewState();
}

class _EmployeeRegisterViewState extends ConsumerState<EmployeeRegisterView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  String _selectedDepartment = '영업팀';
  String _selectedJobTitle = '사원'; // Added for dropdown
  String _selectedMenuPermission = '일반사원';
  DateTime? _hireDate;
  bool _tagYn = false;

  static const _menuPermissionOptions = ['일반사원', '팀장', '부서장', '관리자'];
  static const _jobTitleOptions = [
    '사원',
    '대리',
    '과장',
    '차장',
    '부장',
    '임원',
  ]; // Added job title options

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await showAlertDialog(context, '사원이 등록되었습니다.');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        ref.watch(employeeRepositoryProvider).departmentOptions()..remove('전체');
    if (!departments.contains(_selectedDepartment) && departments.isNotEmpty) {
      _selectedDepartment = departments.first;
    }

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
                              decoration: const InputDecoration(
                                hintText: '이름을 입력하세요.',
                              ),
                              validator: (v) =>
                                  v?.isEmpty == true ? '이름을 입력하세요.' : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '부서',
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDepartment,
                              items: departments
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedDepartment = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '직급(직책)',
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedJobTitle,
                              items: _jobTitleOptions
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedJobTitle = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '휴대전화',
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                hintText: '휴대전화 번호를 입력하세요.',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '이메일주소',
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                hintText: '이메일 주소를 입력하세요.',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v?.isEmpty == true) return null;
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(v!)) {
                                  return '올바른 이메일 형식이 아닙니다.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '입사년월',
                            child: DateInputWithPicker(
                              value: _hireDate,
                              onPick: _pickHireDate,
                              onChanged: (value) =>
                                  setState(() => _hireDate = value),
                              placeholder: '날짜를 선택하세요.',
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '메뉴권한',
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedMenuPermission,
                              items: _menuPermissionOptions
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedMenuPermission = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          LabeledFormRow(
                            label: '태그사용자',
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CheckboxListTile(
                                value: _tagYn,
                                onChanged: (v) {
                                  setState(() => _tagYn = v ?? false);
                                },
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppTheme.accentRed,
                                title: const Text('태그 사용 허용'),
                              ),
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
