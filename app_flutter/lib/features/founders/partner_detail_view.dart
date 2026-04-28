// 예비창업자 상세·신규 등록 화면(탭 골격 공유).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/router/app_router.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/features/founders/partner_controller.dart';
import 'package:app_flutter/features/founders/partner_model.dart';

String _formatPhoneNumber(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';

  if (digits.startsWith('02')) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 2)}-${digits.substring(2)}';
    }
    if (digits.length <= 9) {
      return '${digits.substring(0, 2)}-${digits.substring(2, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    }
    final clipped = digits.substring(0, 10);
    return '${clipped.substring(0, 2)}-${clipped.substring(2, 6)}-${clipped.substring(6)}';
  }

  final clipped = digits.length > 11 ? digits.substring(0, 11) : digits;
  if (clipped.length <= 3) return clipped;
  if (clipped.length <= 7) {
    return '${clipped.substring(0, 3)}-${clipped.substring(3)}';
  }
  return '${clipped.substring(0, 3)}-${clipped.substring(3, clipped.length - 4)}-${clipped.substring(clipped.length - 4)}';
}

String _formatPhoneNumberOrDash(String value) {
  final formatted = _formatPhoneNumber(value);
  return formatted.isEmpty ? '-' : formatted;
}

class _PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatPhoneNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 예비창업자 상세 화면.
///
/// 가맹점·물건 상세와 동일하게 [DetailScreenWithTabs] 골격을 쓴다.
/// 현재는 탭이 하나뿐이지만, 추후 탭이 늘어나도 같은 패턴으로 확장한다.
class PartnerDetailView extends ConsumerWidget {
  const PartnerDetailView({super.key, required this.partnerIdx});

  final int partnerIdx;

  static const List<String> _tabTitles = ['예비창업자정보'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final founderAsync = ref.watch(partnerDetailProvider(partnerIdx));
    final founder = founderAsync.valueOrNull;
    final displayName = founder?.partnerNm ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(lead: displayName, tail: '님 상세 정보'),
      tabTitles: _tabTitles,
      tabPages: [
        founderAsync.when(
          data: (founder) => _PartnerInfoPanel(founder: founder),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('예비창업자 정보를 불러오지 못했습니다.')),
        ),
      ],
    );
  }
}

/// "예비창업자정보" 섹션 패널.
///
/// 상단 헤더(제목 + 수정/저장/취소)와 하단 폼을 함께 관리합니다.
class _PartnerInfoPanel extends ConsumerStatefulWidget {
  const _PartnerInfoPanel({required this.founder});

  final Partner? founder;

  @override
  ConsumerState<_PartnerInfoPanel> createState() => _PartnerInfoPanelState();
}

class _PartnerInfoPanelState extends ConsumerState<_PartnerInfoPanel> {
  final _formKey = GlobalKey<_PartnerInfoFormState>();
  bool _isEditing = false;
  bool _saving = false;

  void editPartner() => setState(() => _isEditing = true);

  void cancelPartnerEdit() {
    setState(() => _isEditing = false);
    _snack('취소되었습니다.');
  }

  Future<void> savePartner() async {
    final founder = widget.founder;
    final payload = _formKey.currentState?.toPayload();
    if (founder == null || payload == null || !_validate(payload)) return;

    setState(() => _saving = true);
    final saved = await ref
        .read(partnerApiServiceProvider)
        .updatePartner(founder.partnerIdx, payload);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved != null) {
        _formKey.currentState?._syncPartner(saved);
        _isEditing = false;
      }
    });

    if (saved == null) {
      _snack('저장에 실패했습니다.');
      return;
    }
    ref.invalidate(partnerDataProvider);
    ref.invalidate(partnerDetailProvider(founder.partnerIdx));
    _snack('저장되었습니다.');
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
                      isSaving: _saving,
                      onEnterEdit: editPartner,
                      onSave: savePartner,
                      onCancel: cancelPartnerEdit,
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: FormStylePalette.panelBorder,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    _PartnerInfoForm(
                      key: _formKey,
                      founder: widget.founder,
                      isEditing: _isEditing,
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

  bool _validate(Map<String, dynamic> payload) {
    final missing = <String>[];
    if ((payload['partnerNm'] as String? ?? '').trim().isEmpty) {
      missing.add('성명');
    }
    if ((payload['partnerTel'] as String? ?? '').trim().isEmpty) {
      missing.add('휴대전화');
    }
    if (missing.isEmpty) return true;
    _snack('${missing.join(', ')} 항목을 입력해 주세요.');
    return false;
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
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

/// 예비창업자 기본 정보 폼.
///
/// 날짜 필드는 달력 버튼을 통해 선택 가능하며, 우편번호는 주소검색 버튼과
/// 함께 제공됩니다. 실제 저장은 추후 API 연동 시 상위 패널에서 처리합니다.
class _PartnerInfoForm extends ConsumerStatefulWidget {
  const _PartnerInfoForm({
    super.key,
    required this.founder,
    required this.isEditing,
  });

  final Partner? founder;
  final bool isEditing;

  @override
  ConsumerState<_PartnerInfoForm> createState() => _PartnerInfoFormState();
}

class _PartnerInfoFormState extends ConsumerState<_PartnerInfoForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _addressController;
  late final TextEditingController _addressDetailController;
  DateTime? _registrationDate;
  DateTime? _birthDate;
  PartnerStatus _partnerStatus = PartnerStatus.prospect;
  Gender _gender = Gender.male;
  String _region = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _zipCodeController = TextEditingController();
    _addressController = TextEditingController();
    _addressDetailController = TextEditingController();
    _syncPartner(widget.founder);
  }

  @override
  void didUpdateWidget(covariant _PartnerInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.founder != widget.founder) {
      _syncPartner(widget.founder);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _zipCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  void _syncPartner(Partner? partner) {
    _registrationDate = _parseYmd(partner?.createDt);
    _birthDate = _parseYmd(partner?.partnerBirth);
    _partnerStatus = partner?.partnerStatus ?? PartnerStatus.prospect;
    _gender = partner?.gender ?? Gender.male;
    _nameController.text = partner?.partnerNm ?? '';
    _phoneController.text = partner?.partnerTel ?? '';
    _emailController.text = partner?.partnerEmail ?? '';
    _zipCodeController.text = partner?.pZipCd ?? '';
    _addressController.text = partner?.pAddress ?? '';
    _addressDetailController.text = partner?.pAddressDetail ?? '';
    _region = partner?.pRegion ?? '';
  }

  Map<String, dynamic> toPayload() {
    return {
      'partnerNm': _nameController.text.trim(),
      'partnerStatus': partnerStatusLabelKorean(_partnerStatus),
      'partnerTel': _phoneController.text.trim(),
      'partnerEmail': _emailController.text.trim(),
      'gender': _gender == Gender.female ? 'F' : 'M',
      'partnerBirth': _formatYmd(_birthDate),
      'pZipCd': _zipCodeController.text.trim(),
      'pAddress': _addressController.text.trim(),
      'pAddressDetail': _addressDetailController.text.trim(),
      'pRegion': _region,
    };
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
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormRow(
          label: '성명',
          requiredField: true,
          child: widget.isEditing
              ? _PartnerRegisterTextInput(
                  controller: _nameController,
                  hint: '성명을 입력하세요.',
                )
              : ReadonlyValue(widget.founder?.partnerNm ?? '-'),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상태',
          requiredField: true,
          child: widget.isEditing
              ? _PartnerStatusDropdown(
                  value: _partnerStatus,
                  onChanged: (v) => setState(
                    () => _partnerStatus = v ?? PartnerStatus.prospect,
                  ),
                )
              : _PartnerStatusReadonlyValue(
                  status: widget.founder?.partnerStatus,
                ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '등록일자',
          requiredField: true,
          child: DateInputWithPicker(
            value: _registrationDate,
            onPick: widget.isEditing ? _pickRegistrationDate : () {},
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '휴대전화',
          requiredField: true,
          child: widget.isEditing
              ? _PartnerRegisterTextInput(
                  controller: _phoneController,
                  hint: '휴대전화 번호를 입력하세요.',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_PhoneNumberTextInputFormatter()],
                )
              : ReadonlyValue(
                  _formatPhoneNumberOrDash(widget.founder?.partnerTel ?? ''),
                ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '이메일주소',
          requiredField: true,
          child: widget.isEditing
              ? _PartnerRegisterTextInput(
                  controller: _emailController,
                  hint: '이메일 주소를 입력하세요.',
                  keyboardType: TextInputType.emailAddress,
                )
              : ReadonlyValue(widget.founder?.partnerEmail ?? '-'),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '성별',
          child: widget.isEditing
              ? _PartnerRegisterGenderDropdown(
                  value: _gender,
                  onChanged: (v) => setState(() => _gender = v ?? Gender.male),
                )
              : _GenderReadonlyValue(gender: widget.founder?.gender),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '생년월일',
          child: DateInputWithPicker(
            value: _birthDate,
            onPick: _pickBirthDate,
            onChanged: widget.isEditing
                ? (value) => setState(() => _birthDate = value)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '우편번호',
          child: Row(
            children: [
              Expanded(
                child: widget.isEditing
                    ? _PartnerRegisterTextInput(
                        controller: _zipCodeController,
                        hint: '우편번호',
                        keyboardType: TextInputType.number,
                      )
                    : ReadonlyValue(
                        _zipCodeController.text.isEmpty
                            ? '-'
                            : _zipCodeController.text,
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
          child: widget.isEditing
              ? _PartnerRegisterTextInput(
                  controller: _addressController,
                  hint: '기본 주소',
                )
              : ReadonlyValue(
                  _addressController.text.isEmpty
                      ? '-'
                      : _addressController.text,
                ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상세주소',
          child: widget.isEditing
              ? _PartnerRegisterTextInput(
                  controller: _addressDetailController,
                  hint: '상세 주소 (동·호 등)',
                )
              : ReadonlyValue(
                  _addressDetailController.text.isEmpty
                      ? '-'
                      : _addressDetailController.text,
                ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '지역',
          child: widget.isEditing
              ? _PartnerRegionDropdown(
                  value: _region,
                  options: regionOptions,
                  onChanged: (v) => setState(() => _region = v ?? ''),
                )
              : ReadonlyValue(_regionLabel(_region, regionOptions)),
        ),
      ],
    );
  }

  DateTime? _parseYmd(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String? _formatYmd(DateTime? date) {
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  String _regionLabel(String code, List<CodeOption> options) {
    if (code.isEmpty) return '-';
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }
}

/// 예비창업자 신규 등록 화면.
///
/// [DetailScreenWithTabs] 골격으로 상세·물건 등록과 동일한 상단·탭 스타일을 쓴다.
/// 탭은 현재 하나(`예비창업자정보`)뿐이다.
class PartnerRegisterView extends StatelessWidget {
  const PartnerRegisterView({super.key});

  static const List<String> _tabTitles = ['예비창업자정보'];

  @override
  Widget build(BuildContext context) {
    return DetailScreenWithTabs(
      /// 셸 상단 배너와 제목이 겹치지 않게 본문에서 제목 띠 생략.
      title: const SizedBox.shrink(),
      tabTitles: _tabTitles,
      tabPages: const [_PartnerRegisterPanel()],
    );
  }
}

class _PartnerRegisterPanel extends ConsumerStatefulWidget {
  const _PartnerRegisterPanel();

  @override
  ConsumerState<_PartnerRegisterPanel> createState() =>
      _PartnerRegisterPanelState();
}

class _PartnerRegisterPanelState extends ConsumerState<_PartnerRegisterPanel> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();

  DateTime? _registrationDate = DateTime.now();
  DateTime? _birthDate;
  Gender? _gender;
  PartnerStatus _partnerStatus = PartnerStatus.prospect;
  String _region = '';
  bool _saving = false;

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

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _saving = true);
    final saved = await ref.read(partnerApiServiceProvider).createPartner({
      'partnerNm': _nameController.text.trim(),
      'partnerStatus': partnerStatusLabelKorean(_partnerStatus),
      'partnerTel': _phoneController.text.trim(),
      'partnerEmail': _emailController.text.trim(),
      'gender': _gender == Gender.female ? 'F' : 'M',
      'partnerBirth': _formatYmd(_birthDate),
      'pZipCd': _postalCodeController.text.trim(),
      'pAddress': _addressController.text.trim(),
      'pAddressDetail': _addressDetailController.text.trim(),
      'pRegion': _region,
    });
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등록에 실패했습니다.')));
      return;
    }
    ref.invalidate(partnerDataProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('등록되었습니다.')));
    context.go(AppRoutes.founders);
  }

  String? _formatYmd(DateTime? date) {
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
                    _PartnerRegisterPanelHeader(
                      onSave: _save,
                      onCancel: _cancel,
                      isSaving: _saving,
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
    final regionOptions =
        ref.watch(partnerCodeOptionsProvider(20)).value ?? const <CodeOption>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormRow(
          label: '성명',
          requiredField: true,
          child: _PartnerRegisterTextInput(
            controller: _nameController,
            hint: '성명을 입력하세요.',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상태',
          requiredField: true,
          child: _PartnerStatusDropdown(
            value: _partnerStatus,
            onChanged: (v) =>
                setState(() => _partnerStatus = v ?? PartnerStatus.prospect),
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
          child: _PartnerRegisterTextInput(
            controller: _phoneController,
            hint: '휴대전화 번호를 입력하세요.',
            keyboardType: TextInputType.phone,
            inputFormatters: [_PhoneNumberTextInputFormatter()],
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '이메일주소',
          requiredField: true,
          child: _PartnerRegisterTextInput(
            controller: _emailController,
            hint: '이메일 주소를 입력하세요.',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '성별',
          child: _PartnerRegisterGenderDropdown(
            value: _gender,
            onChanged: (v) => setState(() => _gender = v),
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '생년월일',
          child: DateInputWithPicker(
            value: _birthDate,
            onPick: _pickBirthDate,
            onChanged: (value) => setState(() => _birthDate = value),
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '우편번호',
          child: Row(
            children: [
              Expanded(
                child: _PartnerRegisterTextInput(
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
          child: _PartnerRegisterTextInput(
            controller: _addressController,
            hint: '기본 주소',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '상세주소',
          child: _PartnerRegisterTextInput(
            controller: _addressDetailController,
            hint: '상세 주소 (동·호 등)',
          ),
        ),
        const SizedBox(height: 10),
        LabeledFormRow(
          label: '지역',
          child: _PartnerRegionDropdown(
            value: _region,
            options: regionOptions,
            onChanged: (v) => setState(() => _region = v ?? ''),
          ),
        ),
      ],
    );
  }
}

class _PartnerRegisterPanelHeader extends StatelessWidget {
  const _PartnerRegisterPanelHeader({
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

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
        SaveActionButton(onPressed: isSaving ? () {} : onSave),
        const SizedBox(width: 8),
        CancelActionButton(onPressed: onCancel),
      ],
    );
  }
}

/// 등록 화면 전용 TextField (상세 화면 입력칸과 같은 외형).
class _PartnerRegisterTextInput extends StatelessWidget {
  const _PartnerRegisterTextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

class _PartnerRegisterGenderDropdown extends StatelessWidget {
  const _PartnerRegisterGenderDropdown({
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

class _GenderReadonlyValue extends StatelessWidget {
  const _GenderReadonlyValue({required this.gender});

  final Gender? gender;

  @override
  Widget build(BuildContext context) {
    final label = switch (gender) {
      Gender.male => '남',
      Gender.female => '여',
      null => '-',
    };
    final color = switch (gender) {
      Gender.male => const Color(0xFF1E3A8A),
      Gender.female => const Color(0xFFE91E63),
      null => FormStylePalette.textPrimary,
    };

    return ReadonlyInputShell(
      child: Text(
        label,
        style: FormStylePalette.valueStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PartnerStatusReadonlyValue extends StatelessWidget {
  const _PartnerStatusReadonlyValue({required this.status});

  final PartnerStatus? status;

  @override
  Widget build(BuildContext context) {
    final label = status == null ? '-' : partnerStatusLabelKorean(status!);
    final color = switch (status) {
      PartnerStatus.prospect => const Color(0xFFC2185B),
      PartnerStatus.franchisee => const Color(0xFF7B1FA2),
      null => FormStylePalette.textPrimary,
    };

    return ReadonlyInputShell(
      child: Text(
        label,
        style: FormStylePalette.valueStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PartnerStatusDropdown extends StatelessWidget {
  const _PartnerStatusDropdown({required this.value, required this.onChanged});

  final PartnerStatus? value;
  final ValueChanged<PartnerStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PartnerStatus?>(
      initialValue: value,
      items: const [
        DropdownMenuItem<PartnerStatus?>(
          value: PartnerStatus.prospect,
          child: Text('예비창업자'),
        ),
        DropdownMenuItem<PartnerStatus?>(
          value: PartnerStatus.franchisee,
          child: Text('가맹점사업자'),
        ),
      ],
      onChanged: onChanged,
      decoration: _founderRegisterDropdownDecoration(),
    );
  }
}

class _PartnerRegionDropdown extends StatelessWidget {
  const _PartnerRegionDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<CodeOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.any((e) => e.codeCd == value) ? value : null;
    return DropdownButtonFormField<String?>(
      initialValue: selectedValue,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('선택')),
        for (final option in options)
          DropdownMenuItem<String?>(
            value: option.codeCd,
            child: Text(option.codeNm),
          ),
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
