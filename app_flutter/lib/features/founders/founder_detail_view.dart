// 예비창업자 상세·신규 등록 화면(탭 골격 공유).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/features/founders/founder_controller.dart';
import 'package:app_flutter/features/founders/founder_model.dart';

/// 예비창업자 상세 화면.
///
/// 가맹점·물건 상세와 동일하게 [DetailScreenWithTabs] 골격을 쓴다.
/// 현재는 탭이 하나뿐이지만, 추후 탭이 늘어나도 같은 패턴으로 확장한다.
class FounderDetailView extends ConsumerWidget {
  const FounderDetailView({super.key, required this.founderNo});

  final int founderNo;

  static const List<String> _tabTitles = ['예비창업자정보'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final founder = ref.watch(founderRepositoryProvider).find(founderNo);
    final displayName = founder?.name ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(lead: displayName, tail: '님 상세 정보'),
      tabTitles: _tabTitles,
      tabPages: [_FounderInfoPanel(founder: founder)],
    );
  }
}

/// "예비창업자정보" 섹션 패널.
///
/// 상단 헤더(제목 + 수정/저장/취소)와 하단 폼을 함께 관리합니다.
class _FounderInfoPanel extends StatefulWidget {
  const _FounderInfoPanel({required this.founder});

  final Founder? founder;

  @override
  State<_FounderInfoPanel> createState() => _FounderInfoPanelState();
}

class _FounderInfoPanelState extends State<_FounderInfoPanel> {
  bool _isEditing = false;

  void editFounder() => setState(() => _isEditing = true);

  void cancelFounderEdit() {
    setState(() => _isEditing = false);
    _snack('취소되었습니다.');
  }

  void saveFounder() {
    setState(() => _isEditing = false);
    _snack('저장되었습니다. (API 연동 예정)');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                    _PanelHeader(
                      title: '예비창업자정보',
                      isEditing: _isEditing,
                      onEnterEdit: editFounder,
                      onSave: saveFounder,
                      onCancel: cancelFounderEdit,
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: FormStylePalette.panelBorder,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    _FounderInfoForm(founder: widget.founder),
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

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.isEditing,
    required this.onEnterEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final bool isEditing;
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
          SaveActionButton(onPressed: onSave),
          const SizedBox(width: 8),
          CancelActionButton(onPressed: onCancel),
        ] else
          EditActionButton(onPressed: onEnterEdit),
      ],
    );
  }
}

/// 예비창업자 기본 정보 폼.
///
/// 날짜 필드는 달력 버튼을 통해 선택 가능하며, 우편번호는 주소검색 버튼과
/// 함께 제공됩니다. 실제 저장은 추후 API 연동 시 상위 패널에서 처리합니다.
class _FounderInfoForm extends StatefulWidget {
  const _FounderInfoForm({required this.founder});

  final Founder? founder;

  @override
  State<_FounderInfoForm> createState() => _FounderInfoFormState();
}

class _FounderInfoFormState extends State<_FounderInfoForm> {
  DateTime? _registrationDate;
  DateTime? _birthDate;
  String _postalCode = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    final founder = widget.founder;
    _registrationDate = _parseYmd(founder?.registrationDate);
    _birthDate = _parseYmd(founder?.birthDate);
    _postalCode = founder?.postalCode ?? '';
    _address = founder?.address ?? '';
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _registrationDate,
    );
    if (picked != null) {
      setState(() => _registrationDate = picked);
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _birthDate,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _openAddressSearch() {
    // TODO: 실제 주소 검색 API 연동 시 교체 예정.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('주소 검색은 추후 연동 예정입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final addressDetail = widget.founder?.addressDetail ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormRow(
          label: '성명',
          requiredField: true,
          child: ReadonlyValue(widget.founder?.name ?? '-'),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상태',
          requiredField: true,
          child: ReadonlyValue(
            widget.founder == null
                ? '-'
                : founderStatusLabelKorean(widget.founder!.founderStatus),
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '등록일자',
          requiredField: true,
          child: DateInputWithPicker(
            value: _registrationDate,
            onPick: _pickRegistrationDate,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '휴대전화',
          requiredField: true,
          child: ReadonlyValue(widget.founder?.phone ?? '-'),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '이메일주소',
          requiredField: true,
          child: ReadonlyValue(widget.founder?.email ?? '-'),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '성별',
          child: ReadonlyValue(_genderLabel(widget.founder?.gender)),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '생년월일',
          child: DateInputWithPicker(value: _birthDate, onPick: _pickBirthDate),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '우편번호',
          child: Row(
            children: [
              Expanded(
                child: ReadonlyValue(_postalCode.isEmpty ? '-' : _postalCode),
              ),
              const SizedBox(width: 8),
              AccentOutlinedButton(
                label: '주소검색',
                onPressed: _openAddressSearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '주소',
          child: ReadonlyValue(_address.isEmpty ? '-' : _address),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상세주소',
          child: ReadonlyInputShell(
            child: Text(
              addressDetail.isEmpty ? '상세 주소 (동·호 등)' : addressDetail,
              style: addressDetail.isEmpty
                  ? const TextStyle(
                      color: FormStylePalette.textMuted,
                      fontSize: 14,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    )
                  : FormStylePalette.valueStyle,
            ),
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '지역',
          child: ReadonlyValue(widget.founder?.region ?? '-'),
        ),
      ],
    );
  }

  String _genderLabel(Gender? gender) {
    switch (gender) {
      case Gender.male:
        return '남';
      case Gender.female:
        return '여';
      case null:
        return '-';
    }
  }

  DateTime? _parseYmd(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}

/// 예비창업자 신규 등록 화면.
///
/// [DetailScreenWithTabs] 골격으로 상세·물건 등록과 동일한 상단·탭 스타일을 쓴다.
/// 탭은 현재 하나(`예비창업자정보`)뿐이다.
class FounderRegisterView extends StatelessWidget {
  const FounderRegisterView({super.key});

  static const List<String> _tabTitles = ['예비창업자정보'];

  @override
  Widget build(BuildContext context) {
    return DetailScreenWithTabs(
      /// 셸 상단 배너와 제목이 겹치지 않게 본문에서 제목 띠 생략.
      title: const SizedBox.shrink(),
      tabTitles: _tabTitles,
      tabPages: const [_FounderRegisterPanel()],
    );
  }
}

class _FounderRegisterPanel extends StatefulWidget {
  const _FounderRegisterPanel();

  @override
  State<_FounderRegisterPanel> createState() => _FounderRegisterPanelState();
}

class _FounderRegisterPanelState extends State<_FounderRegisterPanel> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();

  DateTime? _registrationDate = DateTime.now();
  DateTime? _birthDate;
  Gender? _gender;
  String? _region;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _registrationDate,
    );
    if (picked != null) {
      setState(() => _registrationDate = picked);
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _openAddressSearch() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('주소 검색은 추후 연동 예정입니다.')));
  }

  bool _validate() {
    final missing = <String>[];
    if (_nameController.text.trim().isEmpty) missing.add('성명');
    if (_registrationDate == null) missing.add('등록일자');
    if (_phoneController.text.trim().isEmpty) missing.add('휴대전화');
    if (_emailController.text.trim().isEmpty) missing.add('이메일주소');

    if (missing.isEmpty) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${missing.join(', ')} 항목을 입력해 주세요.')),
    );
    return false;
  }

  void _save() {
    if (!_validate()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('등록되었습니다. (API 연동 예정)')));
    context.go(AppRoutes.founders);
  }

  void _cancel() {
    context.go(AppRoutes.founders);
  }

  @override
  Widget build(BuildContext context) {
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
                    _FounderRegisterPanelHeader(
                      onSave: _save,
                      onCancel: _cancel,
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: FormStylePalette.panelBorder,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormRow(
          label: '성명',
          requiredField: true,
          child: _FounderRegisterTextInput(
            controller: _nameController,
            hint: '성명을 입력하세요.',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '등록일자',
          requiredField: true,
          child: DateInputWithPicker(
            value: _registrationDate,
            onPick: _pickRegistrationDate,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '휴대전화',
          requiredField: true,
          child: _FounderRegisterTextInput(
            controller: _phoneController,
            hint: '휴대전화 번호를 입력하세요.',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '이메일주소',
          requiredField: true,
          child: _FounderRegisterTextInput(
            controller: _emailController,
            hint: '이메일 주소를 입력하세요.',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '성별',
          child: _FounderRegisterGenderDropdown(
            value: _gender,
            onChanged: (v) => setState(() => _gender = v),
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '생년월일',
          child: DateInputWithPicker(value: _birthDate, onPick: _pickBirthDate),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '우편번호',
          child: Row(
            children: [
              Expanded(
                child: _FounderRegisterTextInput(
                  controller: _postalCodeController,
                  hint: '우편번호',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              AccentOutlinedButton(
                label: '주소검색',
                onPressed: _openAddressSearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '주소',
          child: _FounderRegisterTextInput(
            controller: _addressController,
            hint: '기본 주소',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상세주소',
          child: _FounderRegisterTextInput(
            controller: _addressDetailController,
            hint: '상세 주소 (동·호 등)',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '지역',
          child: _FounderRegisterRegionDropdown(
            value: _region,
            onChanged: (v) => setState(() => _region = v),
          ),
        ),
      ],
    );
  }
}

class _FounderRegisterPanelHeader extends StatelessWidget {
  const _FounderRegisterPanelHeader({
    required this.onSave,
    required this.onCancel,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '예비창업자정보',
            style: TextStyle(
              color: FormStylePalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
        SaveActionButton(onPressed: onSave),
        const SizedBox(width: 8),
        CancelActionButton(onPressed: onCancel),
      ],
    );
  }
}

/// 등록 화면 전용 TextField (상세 화면 입력칸과 같은 외형).
class _FounderRegisterTextInput extends StatelessWidget {
  const _FounderRegisterTextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: FormStylePalette.valueStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: FormStylePalette.textMuted,
          fontSize: 14,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
        filled: true,
        fillColor: FormStylePalette.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: FormStylePalette.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: FormStylePalette.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: FormStylePalette.accent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _FounderRegisterGenderDropdown extends StatelessWidget {
  const _FounderRegisterGenderDropdown({
    required this.value,
    required this.onChanged,
  });

  final Gender? value;
  final ValueChanged<Gender?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Gender?>(
      initialValue: value,
      items: const [
        DropdownMenuItem<Gender?>(value: null, child: Text('선택')),
        DropdownMenuItem<Gender?>(value: Gender.male, child: Text('남')),
        DropdownMenuItem<Gender?>(value: Gender.female, child: Text('여')),
      ],
      onChanged: onChanged,
      decoration: _founderRegisterDropdownDecoration(),
    );
  }
}

class _FounderRegisterRegionDropdown extends ConsumerWidget {
  const _FounderRegisterRegionDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref
        .watch(founderRepositoryProvider)
        .regions()
        .where((e) => e != '전체')
        .toList();
    return DropdownButtonFormField<String?>(
      initialValue: value,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('선택')),
        for (final item in options)
          DropdownMenuItem<String?>(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
      decoration: _founderRegisterDropdownDecoration(),
    );
  }
}

InputDecoration _founderRegisterDropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: FormStylePalette.inputBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: FormStylePalette.accent, width: 1.4),
    ),
  );
}
