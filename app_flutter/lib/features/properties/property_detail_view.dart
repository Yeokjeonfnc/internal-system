// 물건 상세 화면(탭·폼 패널).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_field_block.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/features/properties/property_model.dart';
import 'package:app_flutter/features/properties/property_controller.dart';

/// 개발관리 > 물건관리 > 상세 화면.
///
/// 가맹점 상세와 동일하게 상단 타이틀 아래 **빨간 탭바**를 두고,
/// [TabBarView] 안에 탭별 [PropertyInfoPanel] 콘텐츠를 둡니다.
class PropertyDetailView extends ConsumerWidget {
  const PropertyDetailView({super.key, required this.propertyNo});

  final int propertyNo;

  static const List<String> _tabTitles = ['기본정보', '상세조건'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyRepositoryProvider).find(propertyNo);
    final displayName = property?.name ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(lead: displayName, tail: ' 상세 정보'),
      tabTitles: _tabTitles,
      tabPages: [
        PropertyInfoPanel(property: property, fixedTabIndex: 0),
        PropertyInfoPanel(property: property, fixedTabIndex: 1),
      ],
    );
  }
}

/// 기본정보/상세조건 탭을 포함한 물건 정보 패널. 상세/등록 화면에서 공용으로 사용한다.
///
/// - [fixedTabIndex] 가 `null` 이면 패널 **내부**에 탭바+탭뷰(등록 화면 등).
/// - `0` / `1` 이면 해당 탭만 표시(상세는 부모 [TabBarView] 와 조합).
class PropertyInfoPanel extends StatefulWidget {
  const PropertyInfoPanel({
    super.key,
    required this.property,
    this.initiallyEditing = false,
    this.fixedTabIndex,
  });

  final Property? property;

  /// `true` 로 넘기면 패널이 편집 상태로 시작하여 `저장 / 취소` 버튼이 노출된다.
  /// 등록 화면에서 사용한다.
  final bool initiallyEditing;

  /// 상세: 외부 메인 탭과 맞출 탭 인덱스. 등록: null.
  final int? fixedTabIndex;

  @override
  State<PropertyInfoPanel> createState() => _PropertyInfoPanelState();
}

class _PropertyInfoPanelState extends State<PropertyInfoPanel> {
  late bool _isEditing = widget.initiallyEditing;

  void editProperty() => setState(() => _isEditing = true);

  void cancelPropertyEdit() {
    setState(() => _isEditing = false);
    _snack('취소되었습니다.');
  }

  void saveProperty() {
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
    final fixed = widget.fixedTabIndex;

    Widget tabBody(int index) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: index == 0
            ? _BasicInfoTab(property: widget.property)
            : _DetailConditionsTab(property: widget.property),
      );
    }

    return Padding(
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
                child: fixed != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PanelHeader(
                            title: '물건정보',
                            isEditing: _isEditing,
                            onEnterEdit: editProperty,
                            onSave: saveProperty,
                            onCancel: cancelPropertyEdit,
                          ),
                          const SizedBox(height: 14),
                          Expanded(child: tabBody(fixed)),
                        ],
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PanelHeader(
                              title: '물건정보',
                              isEditing: _isEditing,
                              onEnterEdit: editProperty,
                              onSave: saveProperty,
                              onCancel: cancelPropertyEdit,
                            ),
                            const SizedBox(height: 14),
                            const DetailMainTabBar(tabTitles: ['기본정보', '상세조건']),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 640,
                              child: TabBarView(
                                children: [tabBody(0), tabBody(1)],
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

/// ================================================================
/// 기본정보 탭
/// ================================================================
class _BasicInfoTab extends StatefulWidget {
  const _BasicInfoTab({required this.property});

  final Property? property;

  @override
  State<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<_BasicInfoTab> {
  DateTime? _surveyDate;
  DateTime? _registrationDate;
  PropertyOwnership? _ownership;
  String _region = _kRegionNone;
  AddressScope _addressScope = AddressScope.domestic;

  late final TextEditingController _postalCodeController;
  late final TextEditingController _addressController;
  late final TextEditingController _addressDetailController;
  late final TextEditingController _nameController;
  late final TextEditingController _surveyorController;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _surveyDate = _parseYmd(p?.surveyDate);
    final parsedRegistration = _parseYmd(p?.registrationDate);
    // 등록 모드(property == null)에서는 기본값으로 오늘 날짜를 채운다.
    _registrationDate =
        parsedRegistration ?? (p == null ? DateTime.now() : null);
    _ownership = p?.ownership;
    final raw = p?.region;
    if (raw == null ||
        raw.isEmpty ||
        !_kPropertyDetailRegionOptions.contains(raw)) {
      _region = _kRegionNone;
    } else {
      _region = raw;
    }
    _addressScope = p?.addressScope ?? AddressScope.domestic;
    _postalCodeController = TextEditingController(text: p?.postalCode ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _addressDetailController = TextEditingController(
      text: p?.addressDetail ?? '',
    );
    _nameController = TextEditingController(text: p?.name ?? '');
    _surveyorController = TextEditingController(
      text: _normalizeDisplay(p?.surveyor),
    );
  }

  /// 표시용 placeholder('-')는 비어 있는 값으로 간주하여 입력창에 표시하지 않는다.
  String _normalizeDisplay(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '';
    return raw;
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _nameController.dispose();
    _surveyorController.dispose();
    super.dispose();
  }

  Future<void> _pickSurveyDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _surveyDate,
    );
    if (picked != null && mounted) {
      setState(() => _surveyDate = picked);
    }
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _registrationDate,
    );
    if (picked != null && mounted) {
      setState(() => _registrationDate = picked);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormRow(
          label: '주소',
          requiredField: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: _DetailTextInput(
                      controller: _postalCodeController,
                      hint: '우편번호',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AccentOutlinedButton(
                    label: '주소검색',
                    onPressed: () => _snack('주소 검색은 추후 연동 예정입니다.'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<AddressScope>(
                      initialValue: _addressScope,
                      items: const [
                        DropdownMenuItem<AddressScope>(
                          value: AddressScope.domestic,
                          child: Text('국내'),
                        ),
                        DropdownMenuItem<AddressScope>(
                          value: AddressScope.overseas,
                          child: Text('국외'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _addressScope = v);
                      },
                      style: FormStylePalette.valueStyle,
                      decoration: _detailDropdownDecoration(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DetailTextInput(
                controller: _addressController,
                hint: '도로명 주소를 입력하세요.',
              ),
              const SizedBox(height: 8),
              _DetailTextInput(
                controller: _addressDetailController,
                hint: '상세 주소 (동·호 등)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '물건명',
          requiredField: true,
          child: _DetailTextInput(
            controller: _nameController,
            hint: '물건명을 입력하세요.',
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '등록일자',
            child: DateInputWithPicker(
              value: _registrationDate,
              onPick: _pickRegistrationDate,
            ),
          ),
          right: FormFieldBlock(
            label: '조사자',
            child: _DetailTextInput(
              controller: _surveyorController,
              hint: '조사자를 입력하세요.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '조사일자',
            child: DateInputWithPicker(
              value: _registrationDate,
              onPick: _pickSurveyDate,
            ),
          ),
          right: FormFieldBlock(
            label: '종류',
            child: DropdownButtonFormField<PropertyOwnership>(
              initialValue: _ownership,
              items: const [
                DropdownMenuItem<PropertyOwnership>(
                  value: PropertyOwnership.leased,
                  child: Text('임대차'),
                ),
                DropdownMenuItem<PropertyOwnership>(
                  value: PropertyOwnership.owned,
                  child: Text('자가'),
                ),
              ],
              onChanged: (v) => setState(() => _ownership = v),
              style: FormStylePalette.valueStyle,
              decoration: _detailDropdownDecoration(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '지역',
          child: DropdownButtonFormField<String>(
            initialValue: _region,
            items: _kPropertyDetailRegionOptions
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _region = v);
            },
            style: FormStylePalette.valueStyle,
            decoration: _detailDropdownDecoration(),
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '사진',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: ReadonlyValue('첨부된 사진이 없습니다.')),
              const SizedBox(width: 8),
              AccentOutlinedButton(
                label: '사진첨부',
                onPressed: () => _snack('사진 첨부는 추후 연동 예정입니다.'),
              ),
              const SizedBox(width: 6),
              AccentOutlinedButton(
                label: '미리보기',
                onPressed: () => _snack('첨부된 사진이 없어 미리볼 수 없습니다.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _parseYmd(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.replaceAll(',', '').trim();
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }
}

/// ================================================================
/// 상세조건 탭 — 점포조건 + 임대조건
/// ================================================================
class _DetailConditionsTab extends StatelessWidget {
  const _DetailConditionsTab({required this.property});

  final Property? property;

  @override
  Widget build(BuildContext context) {
    final p = property;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('점포조건'),
        const SizedBox(height: 10),
        FormRowTwo(
          left: FormFieldBlock(
            label: '위치',
            child: ReadonlyValue(p?.address ?? '-'),
          ),
          right: FormFieldBlock(
            label: '층수',
            child: ReadonlyValue(p?.floor ?? '-'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '면적(계약㎡)',
            child: ReadonlyWithSuffix(
              value: _formatArea(p?.areaSqm),
              suffix: '㎡',
            ),
          ),
          right: FormFieldBlock(
            label: '면적(실㎡)',
            child: ReadonlyWithSuffix(
              value: _formatArea(p?.actualAreaSqm),
              suffix: '㎡',
            ),
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '특이사항',
          child: ReadonlyInputShell(
            child: Text(
              (p?.notes.isEmpty ?? true) ? '-' : p!.notes,
              style: FormStylePalette.valueStyle,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('임대조건'),
        const SizedBox(height: 10),
        FormRowTwo(
          left: FormFieldBlock(
            label: '임대차 보증금',
            child: ReadonlyWithSuffix(
              value: _formatMoney(p?.deposit),
              suffix: '원',
            ),
          ),
          right: FormFieldBlock(
            label: '임차료',
            child: ReadonlyWithSuffix(
              value: _formatMoney(p?.rent),
              suffix: '원',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '권리금',
            child: ReadonlyWithSuffix(
              value: _formatMoney(p?.keyMoney),
              suffix: '원',
            ),
          ),
          right: FormFieldBlock(
            label: '관리비',
            child: ReadonlyWithSuffix(
              value: _formatMoney(p?.managementFee),
              suffix: '원',
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 3, height: 16, color: FormStylePalette.accent),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: FormStylePalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }
}

String _formatArea(double? area) {
  if (area == null) return '-';
  if (area == 0) return '0';
  if (area == area.truncateToDouble()) {
    return area.toStringAsFixed(0);
  }
  return area.toStringAsFixed(2);
}

String _formatMoney(int? amount) {
  if (amount == null) return '-';
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final tail = text.length - i;
    buffer.write(text[i]);
    if (tail > 1 && tail % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// "구분없음" 라벨.
const String _kRegionNone = '구분없음';

/// 상세 화면의 지역 드롭다운 옵션.
///
/// 목록 화면(`PropertyRepository.regions()`)과 달리 "전체" 대신
/// "구분없음"을 사용한다.
const List<String> _kPropertyDetailRegionOptions = [
  _kRegionNone,
  '서울',
  '부산',
  '대구',
  '인천',
  '광주',
  '대전',
  '울산',
  '세종',
  '경기',
  '강원',
  '충북',
  '충남',
  '전북',
  '전남',
  '경북',
  '경남',
  '제주',
  '국외',
];

/// 상세 화면의 편집 가능한 텍스트 입력 필드. ReadonlyInputShell 과 톤을 맞춘다.
class _DetailTextInput extends StatelessWidget {
  const _DetailTextInput({
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
          vertical: 12,
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

/// 상세 화면 드롭다운의 입력 장식. ReadonlyInputShell 과 같은 톤을 유지한다.
InputDecoration _detailDropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: FormStylePalette.inputBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
