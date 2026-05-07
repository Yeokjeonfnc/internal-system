// 물건 상세 화면(탭·폼 패널).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/address/kakao_postcode_picker.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_field_block.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/dev002/dev002_model.dart';
import 'package:app_flutter/pages/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/mst001/mst001_dialog_lookup.dart';
import 'package:app_flutter/pages/mst001/mst001_model.dart';

class PropertyRegisterDraft {
  PropertyRegisterDraft() : registrationDate = DateTime.now();

  DateTime? surveyDate;
  DateTime? registrationDate;
  PropertyOwnership ownership = PropertyOwnership.leased;
  PropertyStatus status = PropertyStatus.pending;
  String region = _kRegionNone;
  AddressScope addressScope = AddressScope.domestic;
  String postalCode = '';
  String address = '';
  String addressDetail = '';
  String name = '';
  String surveyor = '';
  String floor = '';
  String contArea = '';
  String realArea = '';
  String rentDeposit = '0';
  String monthlyRent = '0';
  String premiumFee = '0';
  String maintFee = '0';
  String notes = '';

  void hydrateFromProperty(Property property) {
    surveyDate = _propertyParseYmd(property.surveyDate);
    registrationDate = _propertyParseYmd(property.registrationDate);
    ownership = property.ownership;
    status = property.status;
    region = property.region;
    addressScope = property.addressScope;
    postalCode = property.postalCode;
    address = property.address;
    addressDetail = property.addressDetail;
    name = property.name;
    surveyor = property.surveyor;
    floor = property.floor == '-' ? '' : property.floor;
    contArea = _propertyNumberText(property.areaSqm);
    realArea = _propertyNumberText(property.actualAreaSqm);
    rentDeposit = property.deposit == 0
        ? '0'
        : _formatMoneyInput(property.deposit);
    monthlyRent = property.rent == 0 ? '0' : _formatMoneyInput(property.rent);
    premiumFee = property.keyMoney == 0
        ? '0'
        : _formatMoneyInput(property.keyMoney);
    maintFee = property.managementFee == 0
        ? '0'
        : _formatMoneyInput(property.managementFee);
    notes = property.notes;
  }

  Map<String, dynamic> toPayload() {
    return {
      'propNm': name.trim(),
      'zipCd': postalCode.trim(),
      'address': address.trim(),
      'addressDetail': addressDetail.trim(),
      'region': region == _kRegionNone ? null : region,
      'propStatus': _propertyStatusCode(status),
      'propType': _propertyTypeCode(ownership),
      'surveyor': surveyor.trim(),
      'floor': int.tryParse(floor.trim()),
      'contArea': _doubleFromText(contArea),
      'realArea': _doubleFromText(realArea),
      'rentDeposit': _intFromMoneyText(rentDeposit),
      'monthlyRent': _intFromMoneyText(monthlyRent),
      'premiumFee': _intFromMoneyText(premiumFee),
      'maintFee': _intFromMoneyText(maintFee),
      'propNotes': notes.trim(),
      'surveyDt': _formatPayloadDate(surveyDate),
    };
  }
}

String _propertyNumberText(num? value) {
  if (value == null || value == 0) return '';
  final doubleValue = value.toDouble();
  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toInt().toString();
  }
  return doubleValue.toString();
}

DateTime? _propertyParseYmd(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// 개발관리 > 물건관리 > 상세 화면.
///
/// 가맹점 상세와 동일하게 상단 타이틀 아래 **빨간 탭바**를 두고,
/// [DetailScreenWithTabs] 안에 탭별 [PropertyInfoPanel] 콘텐츠를 둡니다.
class PropertyDetailView extends ConsumerStatefulWidget {
  const PropertyDetailView({super.key, required this.propertyNo});

  final int propertyNo;

  static const List<String> _tabTitles = ['기본정보', '상세조건'];

  @override
  ConsumerState<PropertyDetailView> createState() => _PropertyDetailViewState();
}

class _PropertyDetailViewState extends ConsumerState<PropertyDetailView> {
  PropertyRegisterDraft? _draft;
  int? _draftPropertyNo;
  bool _isEditing = false;

  /// 취소 시 두 탭 폼을 서버(또는 마지막 로드) 값으로 되돌린다.
  int _formSessionEpoch = 0;

  @override
  void dispose() {
    _draft = null;
    super.dispose();
  }

  PropertyRegisterDraft? _draftForProperty(Property? property) {
    if (property == null) return null;
    if (_draft == null || _draftPropertyNo != property.propIdx) {
      _draft = PropertyRegisterDraft()..hydrateFromProperty(property);
      _draftPropertyNo = property.propIdx;
      _isEditing = false;
    }
    return _draft;
  }

  Future<void> _handleSharedCancelEditing() async {
    final property = ref
        .read(propertyDetailProvider(widget.propertyNo))
        .valueOrNull;
    if (property != null) {
      _draft?.hydrateFromProperty(property);
    }
    setState(() {
      _isEditing = false;
      _formSessionEpoch++;
    });
    await showAlertDialog(context, '취소되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailProvider(widget.propertyNo));
    final property = propertyAsync.valueOrNull;
    final draft = _draftForProperty(property);
    final displayName = property?.name ?? '알 수 없음';

    return DetailScreenWithTabs(
      title: DetailScreenHeadline.leadTail(lead: displayName, tail: ' 상세 정보'),
      tabTitles: PropertyDetailView._tabTitles,
      tabPages: [
        propertyAsync.when(
          data: (property) => PropertyInfoPanel(
            key: ValueKey('prop_panel_0_$_formSessionEpoch'),
            property: property,
            fixedTabIndex: 0,
            registerDraft: draft,
            sharedEditing: _isEditing,
            onEditModeChanged: (value) => setState(() => _isEditing = value),
            onSharedCancelEditing: _handleSharedCancelEditing,
            onSaved: (_) => setState(() => _formSessionEpoch++),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('물건 정보를 불러오지 못했습니다.')),
        ),
        propertyAsync.when(
          data: (property) => PropertyInfoPanel(
            key: ValueKey('prop_panel_1_$_formSessionEpoch'),
            property: property,
            fixedTabIndex: 1,
            registerDraft: draft,
            sharedEditing: _isEditing,
            onEditModeChanged: (value) => setState(() => _isEditing = value),
            onSharedCancelEditing: _handleSharedCancelEditing,
            onSaved: (_) => setState(() => _formSessionEpoch++),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('물건 정보를 불러오지 못했습니다.')),
        ),
      ],
    );
  }
}

/// 기본정보/상세조건 탭을 포함한 물건 정보 패널. 상세/등록 화면에서 공용으로 사용한다.
///
/// - `fixedTabIndex` 가 `null` 이면 패널 **내부**에 탭바와 [IndexedStack] 본문(탭 전환 시 입력값 유지).
/// - `0` / `1` 이면 해당 탭만 표시(상세는 부모 [DetailScreenWithTabs] 와 조합).
class PropertyInfoPanel extends ConsumerStatefulWidget {
  const PropertyInfoPanel({
    super.key,
    required this.property,
    this.initiallyEditing = false,
    this.fixedTabIndex,
    this.onSaved,
    this.registerDraft,
    this.sharedEditing,
    this.onEditModeChanged,
    this.onSharedCancelEditing,
  });

  final Property? property;

  /// `true` 로 넘기면 패널이 편집 상태로 시작하여 `저장 / 취소` 버튼이 노출된다.
  /// 등록 화면에서 사용한다.
  final bool initiallyEditing;

  /// 상세: 외부 메인 탭과 맞출 탭 인덱스. 등록: null.
  final int? fixedTabIndex;
  final ValueChanged<Property>? onSaved;
  final PropertyRegisterDraft? registerDraft;
  final bool? sharedEditing;
  final ValueChanged<bool>? onEditModeChanged;

  /// 여러 메인 탭에 패널이 나뉜 경우, 취소 시 부모가 드래프트 초기화·폼 재빌드를 한 번에 처리한다.
  final VoidCallback? onSharedCancelEditing;

  @override
  ConsumerState<PropertyInfoPanel> createState() => _PropertyInfoPanelState();
}

class _PropertyInfoPanelState extends ConsumerState<PropertyInfoPanel> {
  final _basicInfoKey = GlobalKey<_BasicInfoTabState>();
  final _detailConditionsKey = GlobalKey<_DetailConditionsTabState>();
  late bool _isEditing = widget.initiallyEditing;

  bool get _editing => widget.sharedEditing ?? _isEditing;

  void editProperty() {
    widget.onEditModeChanged?.call(true);
    setState(() => _isEditing = true);
  }

  void cancelPropertyEdit() {
    if (widget.onSharedCancelEditing != null) {
      widget.onSharedCancelEditing!();
      return;
    }
    widget.onEditModeChanged?.call(false);
    setState(() => _isEditing = false);
    _snack('취소되었습니다.');
  }

  Future<void> saveProperty() async {
    final Map<String, dynamic> payload;
    if (widget.registerDraft != null) {
      payload = Map<String, dynamic>.from(widget.registerDraft!.toPayload());
    } else {
      payload = {};
      if (widget.fixedTabIndex == 0 || widget.fixedTabIndex == null) {
        payload.addAll(_basicInfoKey.currentState?.toPayload() ?? {});
      }
      if (widget.fixedTabIndex == 1 || widget.fixedTabIndex == null) {
        payload.addAll(_detailConditionsKey.currentState?.toPayload() ?? {});
      }
    }
    if (widget.property != null &&
        (payload['propNm'] as String? ?? '').trim().isEmpty) {
      payload['propNm'] = widget.property!.name;
    }

    if ((payload['propNm'] as String? ?? '').trim().isEmpty) {
      _snack('물건명을 입력해 주세요.');
      return;
    }

    final saved = widget.property == null
        ? await ref.read(propertyApiServiceProvider).createProperty(payload)
        : await ref
              .read(propertyApiServiceProvider)
              .updateProperty(widget.property!.propIdx, payload);
    if (!mounted) return;
    if (saved == null) {
      _snack('저장에 실패했습니다.');
      return;
    }
    if (widget.registerDraft != null) {
      widget.registerDraft!.hydrateFromProperty(saved);
    }
    await ref.refresh(propertyDataProvider.future).then<void>((_) {});
    await ref
        .refresh(propertyDetailProvider(saved.propIdx).future)
        .then<void>((_) {});
    if (!mounted) return;
    widget.onSaved?.call(saved);
    widget.onEditModeChanged?.call(false);
    setState(() => _isEditing = false);
    await showAlertDialog(context, '저장되었습니다.');

    // 저장 후 데이터 새로고침
    if (mounted) {
      setState(() {});
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final fixed = widget.fixedTabIndex;

    Widget tabBody(int index) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: index == 0
            ? _BasicInfoTab(
                key: _basicInfoKey,
                property: widget.property,
                registerDraft: widget.registerDraft,
                isEditing: _editing,
              )
            : _DetailConditionsTab(
                key: _detailConditionsKey,
                property: widget.property,
                registerDraft: widget.registerDraft,
                isEditing: _editing,
              ),
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
                            isEditing: _editing,
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
                              isEditing: _editing,
                              onEnterEdit: editProperty,
                              onSave: saveProperty,
                              onCancel: cancelPropertyEdit,
                            ),
                            const SizedBox(height: 14),
                            const DetailMainTabBar(tabTitles: ['기본정보', '상세조건']),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 640,
                              child: Builder(
                                builder: (context) {
                                  final controller = DefaultTabController.of(
                                    context,
                                  );
                                  return AnimatedBuilder(
                                    animation: controller,
                                    builder: (context, _) {
                                      return IndexedStack(
                                        index: controller.index,
                                        children: [tabBody(0), tabBody(1)],
                                      );
                                    },
                                  );
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
class _BasicInfoTab extends ConsumerStatefulWidget {
  const _BasicInfoTab({
    super.key,
    required this.property,
    required this.isEditing,
    this.registerDraft,
  });

  final Property? property;
  final bool isEditing;
  final PropertyRegisterDraft? registerDraft;

  @override
  ConsumerState<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends ConsumerState<_BasicInfoTab> {
  DateTime? _surveyDate;
  DateTime? _registrationDate;
  PropertyOwnership _ownership = PropertyOwnership.leased;
  PropertyStatus _status = PropertyStatus.pending;
  String _region = _kRegionNone;
  AddressScope _addressScope = AddressScope.domestic;

  late final TextEditingController _postalCodeController;
  late final TextEditingController _addressController;
  late final TextEditingController _addressDetailController;
  late final TextEditingController _nameController;
  late final TextEditingController _surveyorController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    final draft = widget.registerDraft;
    _surveyDate = p == null ? draft?.surveyDate : _parseYmd(p.surveyDate);
    final parsedRegistration = _parseYmd(p?.registrationDate);
    // 등록 모드(property == null)에서는 기본값으로 오늘 날짜를 채운다.
    _registrationDate =
        parsedRegistration ?? (p == null ? draft?.registrationDate : null);
    _ownership = p?.ownership ?? draft?.ownership ?? PropertyOwnership.leased;
    _status = p?.status ?? draft?.status ?? PropertyStatus.pending;
    _region = p?.region ?? draft?.region ?? _kRegionNone;
    _addressScope =
        p?.addressScope ?? draft?.addressScope ?? AddressScope.domestic;
    _postalCodeController = TextEditingController(
      text: p?.postalCode ?? draft?.postalCode ?? '',
    );
    _addressController = TextEditingController(
      text: p?.address ?? draft?.address ?? '',
    );
    _addressDetailController = TextEditingController(
      text: p?.addressDetail ?? draft?.addressDetail ?? '',
    );
    _nameController = TextEditingController(text: p?.name ?? draft?.name ?? '');
    _surveyorController = TextEditingController(
      text: p?.surveyor ?? draft?.surveyor ?? '',
    );
    _notesController = TextEditingController(
      text: p?.notes ?? draft?.notes ?? '',
    );
    _postalCodeController.addListener(_syncDraft);
    _addressController.addListener(_syncDraft);
    _addressDetailController.addListener(_syncDraft);
    _nameController.addListener(_syncDraft);
    _surveyorController.addListener(_syncDraft);
    _notesController.addListener(_syncDraft);
    _syncDraft();
  }

  void _syncDraft() {
    final draft = widget.registerDraft;
    if (draft == null) return;
    draft
      ..surveyDate = _surveyDate
      ..registrationDate = _registrationDate
      ..ownership = _ownership
      ..status = _status
      ..region = _region
      ..addressScope = _addressScope
      ..postalCode = _postalCodeController.text
      ..address = _addressController.text
      ..addressDetail = _addressDetailController.text
      ..name = _nameController.text
      ..surveyor = _surveyorController.text
      ..notes = _notesController.text;
  }

  Map<String, dynamic> toPayload() {
    return {
      'propNm': _nameController.text.trim(),
      'zipCd': _postalCodeController.text.trim(),
      'address': _addressController.text.trim(),
      'addressDetail': _addressDetailController.text.trim(),
      'region': _region == _kRegionNone ? null : _region,
      'propStatus': _propertyStatusCode(_status),
      'propType': _propertyTypeCode(_ownership),
      'surveyor': _surveyorController.text.trim(),
      'surveyDt': _formatPayloadDate(_surveyDate),
      'propNotes': _notesController.text.trim(),
    };
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    _nameController.dispose();
    _surveyorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openKakaoPostcode() async {
    if (!widget.isEditing) return;
    final result = await showKakaoPostcodePicker(context);
    if (!mounted || result == null) return;
    setState(() {
      _postalCodeController.text = result.zonecode;
      _addressController.text = result.addressLine;
      _addressScope = AddressScope.domestic;
      _syncDraft();
    });
  }

  Future<void> _openSurveyorEmployeeLookup() async {
    if (!widget.isEditing) return;
    final repo = ref.read(employeeRepositoryProvider);
    final selected = await showDialog<Employee>(
      context: context,
      builder: (dialogContext) =>
          EmployeeLookupDialog(employeesFuture: repo.all()),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _surveyorController.text = selected.name.trim();
      _syncDraft();
    });
  }

  Future<void> _pickSurveyDate() async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: _surveyDate,
    );
    if (picked != null && mounted) {
      setState(() {
        _surveyDate = picked;
        _syncDraft();
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final regionOptions =
        ref.watch(propertyCodeOptionsProvider(20)).value ??
        const <CodeOption>[];
    final selectedRegion = regionOptions.any((e) => e.codeCd == _region)
        ? _region
        : _kRegionNone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRowTwo(
          left: FormFieldBlock(
            label: '등록일자',
            child: ReadonlyValue(_formatReadonlyDate(_registrationDate)),
          ),
          right: FormFieldBlock(
            label: '조사일자',
            child: DateInputWithPicker(
              value: _surveyDate,
              onPick: widget.isEditing ? _pickSurveyDate : () {},
              onChanged: widget.isEditing
                  ? (value) => setState(() {
                      _surveyDate = value;
                      _syncDraft();
                    })
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FormRowTwo(
          left: FormFieldBlock(
            label: '조사자',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _DetailTextInput(
                    controller: _surveyorController,
                    hint: '조사자를 입력하세요.',
                    enabled: widget.isEditing,
                  ),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _openSurveyorEmployeeLookup,
                    icon: const Icon(Icons.search, size: 18),
                    tooltip: '조사자 조회',
                    style: IconButton.styleFrom(
                      foregroundColor: FormStylePalette.accent,
                      side: const BorderSide(color: FormStylePalette.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          right: const FormFieldBlock(label: ' ', child: SizedBox.shrink()),
        ),
        const SizedBox(height: 14),
        LabeledFormRow(
          label: '물건명',
          requiredField: true,
          child: _DetailTextInput(
            controller: _nameController,
            hint: '물건명을 입력하세요.',
            enabled: widget.isEditing,
          ),
        ),
        const SizedBox(height: 14),
        FormRowTwo(
          left: FormFieldBlock(
            label: '구분',
            child: _PropertyStatusCheckGroup(
              value: _status,
              enabled: widget.isEditing,
              onChanged: (v) => setState(() {
                _status = v;
                _syncDraft();
              }),
            ),
          ),
          right: FormFieldBlock(
            label: '종류',
            child: _PropertyTypeCheckGroup(
              value: _ownership,
              enabled: widget.isEditing,
              onChanged: (v) => setState(() {
                _ownership = v;
                _syncDraft();
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
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
                      enabled: widget.isEditing,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AccentOutlinedButton(
                    label: '주소검색',
                    onPressed: widget.isEditing ? _openKakaoPostcode : () {},
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
                      onChanged: widget.isEditing
                          ? (v) {
                              if (v != null) {
                                setState(() {
                                  _addressScope = v;
                                  _syncDraft();
                                });
                              }
                            }
                          : null,
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
                enabled: widget.isEditing,
              ),
              const SizedBox(height: 8),
              _DetailTextInput(
                controller: _addressDetailController,
                hint: '상세 주소 (동·호 등)',
                enabled: widget.isEditing,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LabeledFormRow(
          label: '지역',
          child: DropdownButtonFormField<String>(
            initialValue: selectedRegion,
            items: [
              const DropdownMenuItem<String>(
                value: _kRegionNone,
                child: Text(_kRegionNone),
              ),
              for (final option in regionOptions)
                DropdownMenuItem<String>(
                  value: option.codeCd,
                  child: Text(option.codeNm),
                ),
            ],
            onChanged: widget.isEditing
                ? (v) {
                    if (v != null) {
                      setState(() {
                        _region = v;
                        _syncDraft();
                      });
                    }
                  }
                : null,
            style: FormStylePalette.valueStyle,
            decoration: _detailDropdownDecoration(),
          ),
        ),
        const SizedBox(height: 14),
        LabeledFormRow(
          label: '사진',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: ReadonlyValue('첨부된 사진이 없습니다.')),
              const SizedBox(width: 8),
              AccentOutlinedButton(
                label: '사진첨부',
                onPressed: widget.isEditing
                    ? () => _snack('사진 첨부는 추후 연동 예정입니다.')
                    : () {},
              ),
              const SizedBox(width: 6),
              AccentOutlinedButton(
                label: '미리보기',
                onPressed: widget.isEditing
                    ? () => _snack('첨부된 사진이 없어 미리볼 수 없습니다.')
                    : () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '특이사항',
          requiredField: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailTextInput(
                  controller: _notesController,
                  hint: '특이사항을 입력하세요.',
                  enabled: widget.isEditing,
                  minLines: 4,
                  maxLines: 8,
                ),
              ),
              const SizedBox(width: 8),
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
class _DetailConditionsTab extends StatefulWidget {
  const _DetailConditionsTab({
    super.key,
    required this.property,
    required this.isEditing,
    this.registerDraft,
  });

  final Property? property;
  final bool isEditing;
  final PropertyRegisterDraft? registerDraft;

  @override
  State<_DetailConditionsTab> createState() => _DetailConditionsTabState();
}

class _DetailConditionsTabState extends State<_DetailConditionsTab> {
  late final TextEditingController _floorController;
  late final TextEditingController _contAreaController;
  late final TextEditingController _realAreaController;
  late final TextEditingController _rentDepositController;
  late final TextEditingController _monthlyRentController;
  late final TextEditingController _premiumFeeController;
  late final TextEditingController _maintFeeController;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    final draft = widget.registerDraft;
    _floorController = TextEditingController(
      text: p?.floor == '-' ? '' : p?.floor ?? draft?.floor ?? '',
    );
    _contAreaController = TextEditingController(
      text: p == null ? draft?.contArea ?? '' : _numberText(p.areaSqm),
    );
    _realAreaController = TextEditingController(
      text: p == null ? draft?.realArea ?? '' : _numberText(p.actualAreaSqm),
    );
    _rentDepositController = TextEditingController(
      text: _detailMoneyFieldInitialText(
        property: p,
        draftMoneyStr: draft?.rentDeposit,
        amountFromProperty: (x) => x.deposit,
      ),
    );
    _monthlyRentController = TextEditingController(
      text: _detailMoneyFieldInitialText(
        property: p,
        draftMoneyStr: draft?.monthlyRent,
        amountFromProperty: (x) => x.rent,
      ),
    );
    _premiumFeeController = TextEditingController(
      text: _detailMoneyFieldInitialText(
        property: p,
        draftMoneyStr: draft?.premiumFee,
        amountFromProperty: (x) => x.keyMoney,
      ),
    );
    _maintFeeController = TextEditingController(
      text: _detailMoneyFieldInitialText(
        property: p,
        draftMoneyStr: draft?.maintFee,
        amountFromProperty: (x) => x.managementFee,
      ),
    );
    _floorController.addListener(_syncDraft);
    _contAreaController.addListener(_syncDraftAndRefreshArea);
    _realAreaController.addListener(_syncDraftAndRefreshArea);
    _rentDepositController.addListener(_syncDraft);
    _monthlyRentController.addListener(_syncDraft);
    _premiumFeeController.addListener(_syncDraft);
    _maintFeeController.addListener(_syncDraft);
    _syncDraft();
  }

  void _syncDraftAndRefreshArea() {
    _syncDraft();
    if (mounted) setState(() {});
  }

  void _syncDraft() {
    final draft = widget.registerDraft;
    if (draft == null) return;
    draft
      ..floor = _floorController.text
      ..contArea = _contAreaController.text
      ..realArea = _realAreaController.text
      ..rentDeposit = _rentDepositController.text
      ..monthlyRent = _monthlyRentController.text
      ..premiumFee = _premiumFeeController.text
      ..maintFee = _maintFeeController.text;
  }

  @override
  void dispose() {
    _floorController.dispose();
    _contAreaController.dispose();
    _realAreaController.dispose();
    _rentDepositController.dispose();
    _monthlyRentController.dispose();
    _premiumFeeController.dispose();
    _maintFeeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> toPayload() {
    return {
      'floor': int.tryParse(_floorController.text.trim()),
      'contArea': _doubleFromInput(_contAreaController.text),
      'realArea': _doubleFromInput(_realAreaController.text),
      'rentDeposit': _intFromMoney(_rentDepositController.text),
      'monthlyRent': _intFromMoney(_monthlyRentController.text),
      'premiumFee': _intFromMoney(_premiumFeeController.text),
      'maintFee': _intFromMoney(_maintFeeController.text),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('점포조건'),
        const SizedBox(height: 10),
        FormRowTwo(
          left: FormFieldBlock(
            label: '위치',
            child: ReadonlyValue(widget.property?.address ?? '-'),
          ),
          right: FormFieldBlock(
            label: '층수',
            child: _DetailTextInput(
              controller: _floorController,
              hint: '층수를 입력하세요.',
              keyboardType: TextInputType.number,
              enabled: widget.isEditing,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FormRowTwo(
          left: FormFieldBlock(
            label: '면적(계약㎡)',
            child: _AreaWithPyeongInput(
              controller: _contAreaController,
              hint: '계약 면적',
              enabled: widget.isEditing,
            ),
          ),
          right: FormFieldBlock(
            label: '면적(실㎡)',
            child: _AreaWithPyeongInput(
              controller: _realAreaController,
              hint: '실 면적',
              enabled: widget.isEditing,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('임대조건'),
        const SizedBox(height: 10),
        FormRowTwo(
          left: FormFieldBlock(
            label: '임대차 보증금',
            child: _DetailTextInput(
              controller: _rentDepositController,
              hint: '',
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              enabled: widget.isEditing,
            ),
          ),
          right: FormFieldBlock(
            label: '임차료',
            child: _DetailTextInput(
              controller: _monthlyRentController,
              hint: '',
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              enabled: widget.isEditing,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FormRowTwo(
          left: FormFieldBlock(
            label: '권리금',
            child: _DetailTextInput(
              controller: _premiumFeeController,
              hint: '',
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              enabled: widget.isEditing,
            ),
          ),
          right: FormFieldBlock(
            label: '관리비',
            child: _DetailTextInput(
              controller: _maintFeeController,
              hint: '',
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              enabled: widget.isEditing,
            ),
          ),
        ),
      ],
    );
  }

  String _numberText(num? value) {
    if (value == null || value == 0) return '';
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  int _intFromMoney(String value) {
    return _intFromMoneyText(value);
  }

  double? _doubleFromInput(String value) {
    return _doubleFromText(value);
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

class _AreaWithPyeongInput extends StatelessWidget {
  const _AreaWithPyeongInput({
    required this.controller,
    required this.hint,
    required this.enabled,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _DetailTextInput(
            controller: controller,
            hint: hint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: enabled,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '㎡',
          style: TextStyle(
            fontSize: 14,
            color: FormStylePalette.textSecondary,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: ReadonlyWithSuffix(
            value: _sqmToPyeong(controller.text),
            suffix: '평',
          ),
        ),
      ],
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatMoneyInput(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _sqmToPyeong(String? rawSqm) {
  final normalized = rawSqm?.replaceAll(',', '').trim();
  final sqm = double.tryParse(normalized ?? '');
  if (sqm == null) return '-';
  return (sqm / 3.305785).toStringAsFixed(1);
}

/// 상세조건 금액 칸: 미입력·DB 0은 화면에 `0` 표시. 빈 문자열은 [_intFromMoneyText]에서 0으로 전송됨.
String _detailMoneyFieldInitialText({
  required Property? property,
  required String? draftMoneyStr,
  required int Function(Property p) amountFromProperty,
}) {
  if (property != null) {
    final n = amountFromProperty(property);
    return n == 0 ? '0' : _formatMoneyInput(n);
  }
  final raw = (draftMoneyStr ?? '').trim();
  return raw.isEmpty ? '0' : raw;
}

String _formatMoneyInput(Object? value) {
  final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.isEmpty) return '0';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final tail = digits.length - i;
    buffer.write(digits[i]);
    if (tail > 1 && tail % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

int _intFromMoneyText(String value) {
  final normalized = value.replaceAll(',', '').trim();
  return int.tryParse(normalized) ?? 0;
}

double? _doubleFromText(String value) {
  final normalized = value.replaceAll(',', '').trim();
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

class _PropertyStatusCheckGroup extends StatelessWidget {
  const _PropertyStatusCheckGroup({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PropertyStatus value;
  final bool enabled;
  final ValueChanged<PropertyStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _CheckOption(
          label: '체결물건',
          selected: value == PropertyStatus.contracted,
          enabled: enabled,
          onTap: () => onChanged(PropertyStatus.contracted),
        ),
        _CheckOption(
          label: '보류물건',
          selected: value == PropertyStatus.pending,
          enabled: enabled,
          onTap: () => onChanged(PropertyStatus.pending),
        ),
        _CheckOption(
          label: '부적합물건',
          selected: value == PropertyStatus.unsuitable,
          enabled: enabled,
          onTap: () => onChanged(PropertyStatus.unsuitable),
        ),
      ],
    );
  }
}

class _PropertyTypeCheckGroup extends StatelessWidget {
  const _PropertyTypeCheckGroup({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PropertyOwnership value;
  final bool enabled;
  final ValueChanged<PropertyOwnership> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _CheckOption(
          label: '임대차',
          selected: value == PropertyOwnership.leased,
          enabled: enabled,
          onTap: () => onChanged(PropertyOwnership.leased),
        ),
        _CheckOption(
          label: '자가',
          selected: value == PropertyOwnership.owned,
          enabled: enabled,
          onTap: () => onChanged(PropertyOwnership.owned),
        ),
      ],
    );
  }
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: selected,
            onChanged: enabled ? (_) => onTap() : null,
            activeColor: FormStylePalette.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label, style: FormStylePalette.valueStyle),
        ],
      ),
    );
  }
}

String _propertyStatusCode(PropertyStatus status) => switch (status) {
  PropertyStatus.contracted => 'CONTRACTED', // 체결물건
  PropertyStatus.pending => 'PENDING', // 보류물건
  PropertyStatus.unsuitable => 'UNSUITABLE', // 부적합물건
};

String _propertyTypeCode(PropertyOwnership type) => switch (type) {
  PropertyOwnership.leased => 'LEASE', // 임대차
  PropertyOwnership.owned => 'OWNED', // 자가
};

String _formatReadonlyDate(DateTime? value) {
  if (value == null) return '-';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String? _formatPayloadDate(DateTime? value) {
  if (value == null) return null;
  return _formatReadonlyDate(value);
}

/// "구분없음" 라벨.
const String _kRegionNone = '구분없음';

/// 상세 화면의 편집 가능한 텍스트 입력 필드. ReadonlyInputShell 과 톤을 맞춘다.
class _DetailTextInput extends StatelessWidget {
  const _DetailTextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
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
