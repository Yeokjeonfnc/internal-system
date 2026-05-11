// 가맹점 상세 화면의 탭·공통 영역·문서 UI·패널을 한 파일로 묶음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/core/format/display_date.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_loading_indicator.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_field_block.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/pages/development/dev001/dev001_controller.dart';
import 'package:app_flutter/pages/development/dialogs/dev001_dialog_lookup.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';
import 'package:app_flutter/pages/master/mst001/mst001_controller.dart';
import 'package:app_flutter/pages/master/dialogs/mst001_dialog_lookup.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';
import 'package:app_flutter/pages/development/dev002/dev002_controller.dart';
import 'package:app_flutter/pages/development/dev002/dev002_model.dart';
import 'package:app_flutter/pages/franchise/str001/str001_controller.dart';
import 'package:app_flutter/pages/franchise/str001/str001_model.dart';
import 'package:app_flutter/core/store_mst/store_mst_write_payload.dart';

/// 가맹점 상세 화면(탭·스토어 로드).
class StoreDetailView extends ConsumerStatefulWidget {
  const StoreDetailView({
    super.key,
    this.storeIdx,
    this.isRegisterMode = false,
  });

  final int? storeIdx;
  final bool isRegisterMode;

  static const List<String> _tabTitles = ['기본정보', '계약정보', '문서정보', '히스토리'];

  @override
  ConsumerState<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends ConsumerState<StoreDetailView> {
  StoreRegisterDraft? _registerDraft;
  StoreRegisterDraft? _detailDraft;
  int? _detailDraftStoreIdx;
  bool _isEditing = false;
  int _editSessionEpoch = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isRegisterMode) {
      _registerDraft = StoreRegisterDraft();
    }
    Future.microtask(_reloadCurrentStore);
  }

  @override
  void didUpdateWidget(covariant StoreDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRegisterMode != widget.isRegisterMode) {
      _registerDraft?.dispose();
      _registerDraft = widget.isRegisterMode ? StoreRegisterDraft() : null;
    }
    if (oldWidget.storeIdx != widget.storeIdx ||
        oldWidget.isRegisterMode != widget.isRegisterMode) {
      Future.microtask(_reloadCurrentStore);
    }
  }

  @override
  void dispose() {
    _registerDraft?.dispose();
    _detailDraft?.dispose();
    super.dispose();
  }

  void _reloadCurrentStore() {
    if (!mounted || widget.isRegisterMode || widget.storeIdx == null) return;
    ref.invalidate(storeDetailProvider(widget.storeIdx!));
    ref.invalidate(storeDataProvider);
  }

  StoreRegisterDraft? _draftForStore(Store? store) {
    if (widget.isRegisterMode) return _registerDraft;
    if (store == null) return null;
    if (_detailDraft == null || _detailDraftStoreIdx != store.storeIdx) {
      _detailDraft?.dispose();
      _detailDraft = StoreRegisterDraft()..hydrateFromStore(store);
      _detailDraftStoreIdx = store.storeIdx;
      _isEditing = false;
    }
    return _detailDraft;
  }

  Future<void> _handleSharedCancelEditing() async {
    if (!mounted || widget.storeIdx == null) return;
    final store = ref.read(storeDetailProvider(widget.storeIdx!)).valueOrNull;
    if (store != null) {
      _detailDraft?.hydrateFromStore(store);
    }
    setState(() {
      _isEditing = false;
      _editSessionEpoch++;
    });
    await showAlertDialog(context, '취소되었습니다.');
  }

  void _onRegisterDraftChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = widget.isRegisterMode
        ? const AsyncValue<Store?>.data(null)
        : (widget.storeIdx != null
              ? ref.watch(storeDetailProvider(widget.storeIdx!))
              : const AsyncValue<Store?>.data(null));

    return storeAsync.when(
      data: (store) {
        final draft = _draftForStore(store);

        final Widget title;
        if (widget.isRegisterMode) {
          title = const SizedBox.shrink();
        } else if (store != null) {
          title = DetailScreenHeadline.leadTail(
            lead: store.storeNm,
            tail: '님 상세 정보',
          );
        } else {
          title = DetailScreenHeadline.plain(text: '가맹점 상세');
        }

        return DetailScreenWithTabs(
          title: title,
          tabTitles: StoreDetailView._tabTitles,
          tabPages: [
            for (final tabTitle in StoreDetailView._tabTitles)
              StoreDetailPanel(
                key: ValueKey(
                  '${widget.storeIdx}_${tabTitle}_$_editSessionEpoch',
                ),
                title: tabTitle,
                store: store,
                isRegisterMode: widget.isRegisterMode,
                registerDraft: draft,
                onRegisterDraftChanged: draft != null
                    ? _onRegisterDraftChanged
                    : null,
                sharedEditing: widget.isRegisterMode ? true : _isEditing,
                onEditModeChanged: widget.isRegisterMode
                    ? null
                    : (value) => setState(() => _isEditing = value),
                onSharedCancelEditing:
                    widget.isRegisterMode || widget.storeIdx == null
                    ? null
                    : _handleSharedCancelEditing,
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
    );
  }
}

// ---------------------------------------------------------------------------
// 상세 패널 편집 모드 공통 입력칸 (지역·연락처 등)
// ---------------------------------------------------------------------------

Widget _storeDetailOutlineTextField(
  TextEditingController controller, {
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  String? hintText,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    style: FormStylePalette.valueStyle,
    cursorColor: FormStylePalette.accent,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: FormStylePalette.textMuted,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
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
        borderSide: const BorderSide(
          color: FormStylePalette.accent,
          width: 1.4,
        ),
      ),
    ),
  );
}

Widget _storeDetailOutlineMultilineTextField(
  TextEditingController controller, {
  int minLines = 4,
  int maxLines = 8,
}) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.multiline,
    minLines: minLines,
    maxLines: maxLines,
    style: FormStylePalette.valueStyle,
    cursorColor: FormStylePalette.accent,
    decoration: InputDecoration(
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
        borderSide: const BorderSide(
          color: FormStylePalette.accent,
          width: 1.4,
        ),
      ),
    ),
  );
}

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

String _formatMoneyInput(Object? value) {
  final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.isEmpty) return '0';

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _formatMoneyOrDash(Object? value) {
  final formatted = _formatMoneyInput(value);
  return formatted.isEmpty ? '-' : formatted;
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatMoneyInput(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Widget _storeDetailOutlineTextFieldWithSuffix(
  TextEditingController controller, {
  required String suffix,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: _storeDetailOutlineTextField(
          controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        suffix,
        style: const TextStyle(
          fontSize: 14,
          color: FormStylePalette.textSecondary,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    ],
  );
}

/// 계약/교육 담당자 표시용 — API에 `*Nm`이 없거나 Formula가 null이면 원본 컬럼값으로 폴백.
String _contManagerDisplay(Store? s) {
  if (s == null) return '';
  final nm = s.contManagerNm.trim();
  if (nm.isNotEmpty) return nm;
  return s.contManager.trim();
}

String _eduManagerDisplay(Store? s) {
  if (s == null) return '';
  final nm = s.eduManagerNm.trim();
  if (nm.isNotEmpty) return nm;
  return s.eduManager.trim();
}

String _managerReadonlyDash(Store? s, {required bool contract}) {
  final v = contract ? _contManagerDisplay(s) : _eduManagerDisplay(s);
  return v.isEmpty ? '-' : v;
}

/// 가맹점 등록 화면에서 탭 간 입력값을 공유하기 위한 임시 상태.
class StoreRegisterDraft {
  final storeAreaController = TextEditingController();
  final storeTelController = TextEditingController();
  final storeCodeController = TextEditingController();
  final businessNumberController = TextEditingController();
  final storeNameController = TextEditingController();
  final ownerNameController = TextEditingController();

  final floorController = TextEditingController();
  final parkingController = TextEditingController();
  final contAreaController = TextEditingController();
  final realAreaController = TextEditingController();
  final propertyNameController = TextEditingController();
  final zipCodeController = TextEditingController();
  final addressController = TextEditingController();
  final addressDetailController = TextEditingController();
  final notesController = TextEditingController();
  final rentDepositController = TextEditingController(text: '0');
  final premiumFeeController = TextEditingController(text: '0');
  final monthlyRentController = TextEditingController(text: '0');

  final frFeeController = TextEditingController(text: '0');
  final eduFeeController = TextEditingController(text: '0');
  final insuDepositController = TextEditingController(text: '0');
  final contDepositController = TextEditingController(text: '0');
  final contManagerController = TextEditingController();
  final eduManagerController = TextEditingController();
  final supervisorController = TextEditingController();

  String type = '';
  String region = '';
  String brand = '';
  String status = '';
  String notes = '';
  String? latitude;
  String? longitude;

  DateTime? firstContDt;
  DateTime? contractExpiryDate;
  DateTime? leaseStartDate;
  DateTime? leaseEndDate;
  DateTime? contractFirstContDt;
  DateTime? currentContractStart;
  DateTime? currentContractEnd;

  /// 예비창업자 조회로 점주를 채운 경우, 가맹점 등록 시 partner_mst 상태 갱신용.
  int? partnerIdx;

  void hydrateFromStore(Store store) {
    storeAreaController.text = store.regionCd;
    storeTelController.text = store.storeTel;
    storeCodeController.text = store.storeCd;
    businessNumberController.text = store.businessNumber;
    storeNameController.text = store.storeNm;
    ownerNameController.text = store.ownerNm;
    floorController.text = store.floor == 0 ? '' : store.floor.toString();
    parkingController.text = store.parkingCount == 0
        ? ''
        : store.parkingCount.toString();
    contAreaController.text = store.contArea.isEmpty || store.contArea == '0'
        ? ''
        : store.contArea.toString();
    realAreaController.text = store.realArea.isEmpty || store.realArea == '0'
        ? ''
        : store.realArea.toString();
    zipCodeController.text = store.zipCd;
    addressController.text = store.address;
    addressDetailController.text = store.addressDetail;
    notesController.text = store.notes;
    rentDepositController.text = _formatMoneyInput(store.rentDeposit);
    premiumFeeController.text = _formatMoneyInput(store.premiumFee);
    monthlyRentController.text = _formatMoneyInput(store.monthlyRent);
    frFeeController.text = _formatMoneyInput(store.frFee);
    eduFeeController.text = _formatMoneyInput(store.eduFee);
    insuDepositController.text = _formatMoneyInput(store.insuDeposit);
    contDepositController.text = _formatMoneyInput(store.contDeposit);
    contManagerController.text = _contManagerDisplay(store);
    eduManagerController.text = _eduManagerDisplay(store);
    supervisorController.text = store.svId;
    type = store.storeType;
    region = store.regionCd;
    brand = store.brandCd;
    status = store.storeStatus;
    notes = store.notes;
    firstContDt = tryParseLooseDate(store.firstContDt);
    contractExpiryDate = tryParseLooseDate(store.contEndDt);
    contractFirstContDt = tryParseLooseDate(store.firstContDt);
    currentContractStart = tryParseLooseDate(store.contStartDt);
    currentContractEnd = tryParseLooseDate(store.contEndDt);
    latitude = store.latitude;
    longitude = store.longitude;
    partnerIdx = null;
  }

  void dispose() {
    storeAreaController.dispose();
    storeTelController.dispose();
    storeCodeController.dispose();
    businessNumberController.dispose();
    storeNameController.dispose();
    ownerNameController.dispose();
    floorController.dispose();
    parkingController.dispose();
    contAreaController.dispose();
    realAreaController.dispose();
    propertyNameController.dispose();
    zipCodeController.dispose();
    addressController.dispose();
    addressDetailController.dispose();
    rentDepositController.dispose();
    premiumFeeController.dispose();
    monthlyRentController.dispose();
    frFeeController.dispose();
    eduFeeController.dispose();
    insuDepositController.dispose();
    contDepositController.dispose();
    contManagerController.dispose();
    eduManagerController.dispose();
    supervisorController.dispose();
    notesController.dispose();
  }
}

// ---------------------------------------------------------------------------
// 공통 스토어 정보
// ---------------------------------------------------------------------------

InputDecoration _commonStoreDropdownDecoration() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: const BorderSide(color: FormStylePalette.panelBorder),
  );
  return InputDecoration(
    filled: true,
    fillColor: FormStylePalette.inputBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: FormStylePalette.accent, width: 1.4),
    ),
  );
}

/// 모든 상세 탭 상단에 공통으로 노출되는 기본 스토어 정보 영역.
///
/// 수정 모드일 때 상단 공통 컬럼을 모두 입력/선택 가능하게 전환한다.
/// [storeAreaController]에는 선택한 지역 문자열이 반영된다(API 연동 전).
class CommonStoreInfoSection extends ConsumerStatefulWidget {
  const CommonStoreInfoSection({
    super.key,
    this.store,
    required this.isEditing,
    required this.storeAreaController,
    this.registerDraft,
    this.onRegisterDraftChanged,
  });

  final Store? store;
  final bool isEditing;
  final TextEditingController storeAreaController;
  final StoreRegisterDraft? registerDraft;

  /// [registerDraft] 필드가 바뀔 때 호출해 다른 탭의 동일 영역도 같은 값으로 다시 그린다.
  final VoidCallback? onRegisterDraftChanged;

  @override
  ConsumerState<CommonStoreInfoSection> createState() =>
      _CommonStoreInfoSectionState();
}

class _CommonStoreInfoSectionState
    extends ConsumerState<CommonStoreInfoSection> {
  late final TextEditingController _storeCodeController;
  late final TextEditingController _businessNumberController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _notesController;
  late final bool _ownsControllers;
  late String _type;
  late String _region;
  late String _brand;
  late String _status;

  /// draft가 있으면 브랜드·상태·구분·지역은 항상 draft가 단일 소스(탭 간 동일 표시).
  String _effBrand() => widget.registerDraft?.brand ?? _brand;
  String _effStatus() => widget.registerDraft?.status ?? _status;
  String _effType() => widget.registerDraft?.type ?? _type;
  String _effRegion() => widget.registerDraft?.region ?? _region;

  void _notifyDraftChanged() {
    widget.onRegisterDraftChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.registerDraft;
    _ownsControllers = draft == null;
    _storeCodeController =
        draft?.storeCodeController ?? TextEditingController();
    _businessNumberController =
        draft?.businessNumberController ?? TextEditingController();
    _storeNameController =
        draft?.storeNameController ?? TextEditingController();
    _notesController = draft?.notesController ?? TextEditingController();
    _syncFromStore();
  }

  @override
  void didUpdateWidget(covariant CommonStoreInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        (!oldWidget.isEditing && widget.isEditing)) {
      _syncFromStore();
    }
  }

  @override
  void dispose() {
    if (_ownsControllers) {
      _storeCodeController.dispose();
      _businessNumberController.dispose();
      _storeNameController.dispose();
      _notesController.dispose();
    }
    super.dispose();
  }

  void _syncFromStore() {
    final draft = widget.registerDraft;
    final store = widget.store;
    if (draft != null && store == null) {
      widget.storeAreaController.text = draft.region;
      _brand = '';
      _status = '';
      _type = '';
      _region = '';
      return;
    }
    if (draft != null && store != null) {
      if (draft.brand.isEmpty) draft.brand = store.brandCd;
      if (draft.status.isEmpty) draft.status = store.storeStatus;
      if (draft.type.isEmpty) draft.type = store.storeType;
      if (draft.region.isEmpty) draft.region = store.regionCd;
      widget.storeAreaController.text = draft.region;
      _brand = store.brandCd;
      _status = store.storeStatus;
      _type = store.storeType;
      _region = store.regionCd;
      return;
    }
    _storeCodeController.text = store?.storeCd ?? '';
    _businessNumberController.text = store?.businessNumber ?? '';
    _storeNameController.text = store?.storeNm ?? '';
    _brand = store?.brandCd ?? '';
    _status = store?.storeStatus ?? '';
    _type = store?.storeType ?? '';
    _region = store?.regionCd ?? '';
    widget.storeAreaController.text = _region;
  }

  List<CodeOption> _optionsWithCurrentCode(
    List<CodeOption> base,
    String currentCode,
    String currentName,
  ) {
    final hasValidLabel =
        currentName.isNotEmpty &&
        currentName != '-' &&
        currentName != currentCode;
    if (currentCode.isNotEmpty &&
        currentCode != '-' &&
        hasValidLabel &&
        !base.any((e) => e.codeCd == currentCode)) {
      return [CodeOption(codeCd: currentCode, codeNm: currentName), ...base];
    }
    return base;
  }

  String _selectedCode(String current, List<CodeOption> options) {
    if (options.any((e) => e.codeCd == current)) {
      return current;
    }
    return options.isNotEmpty ? options.first.codeCd : '';
  }

  void _applyRegisterDefaultSelections({
    required List<CodeOption> brandOptions,
    required List<CodeOption> statusOptions,
    required List<CodeOption> regionOptions,
    required List<CodeOption> typeOptions,
  }) {
    if (widget.store != null || widget.registerDraft == null) return;

    final d = widget.registerDraft!;
    var changed = false;
    if (d.brand.isEmpty && brandOptions.isNotEmpty) {
      d.brand = brandOptions.first.codeCd;
      changed = true;
    }
    if (d.status.isEmpty && statusOptions.isNotEmpty) {
      d.status = statusOptions.first.codeCd;
      changed = true;
    }
    if (d.region.isEmpty && regionOptions.isNotEmpty) {
      d.region = regionOptions.first.codeCd;
      widget.storeAreaController.text = d.region;
      changed = true;
    }
    if (d.type.isEmpty && typeOptions.isNotEmpty) {
      d.type = typeOptions.first.codeCd;
      changed = true;
    }
    // [build] 중 부모 [StoreDetailView]의 setState를 부르면 안 되므로 다음 프레임으로 미룬다.
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyDraftChanged();
      });
    }
  }

  String _storeTypeFallbackName(String code) {
    return switch (code) {
      'FR' => '가맹',
      'DI' => '직영',
      _ => code,
    };
  }

  void _setType(String value) {
    widget.registerDraft?.type = value;
    if (widget.registerDraft != null) {
      _notifyDraftChanged();
    } else {
      setState(() => _type = value);
    }
  }

  void _setRegion(String value) {
    widget.registerDraft?.region = value;
    widget.storeAreaController.text = value;
    if (widget.registerDraft != null) {
      _notifyDraftChanged();
    } else {
      setState(() => _region = value);
    }
  }

  void applyPropertySelection(Property property) {
    _storeNameController.text = property.name;
    widget.registerDraft?.storeNameController.text = property.name;
    if (property.region.isNotEmpty) {
      widget.registerDraft?.region = property.region;
      widget.storeAreaController.text = property.region;
      _region = property.region;
    }
    if (widget.registerDraft != null) {
      _notifyDraftChanged();
    } else {
      setState(() {});
    }
  }

  void _setBrand(String value) {
    widget.registerDraft?.brand = value;
    if (widget.registerDraft != null) {
      _notifyDraftChanged();
    } else {
      setState(() => _brand = value);
    }
  }

  void _setStatus(String value) {
    widget.registerDraft?.status = value;
    if (widget.registerDraft != null) {
      _notifyDraftChanged();
    } else {
      setState(() => _status = value);
    }
  }

  StoreMstWritePayload toUpdatePayload(
    Store store, {
    required String storeTel,
  }) {
    final draft = widget.registerDraft;
    final codeFromField = draft?.storeCodeController.text.trim() ?? '';
    final storeCd = codeFromField.isNotEmpty ? codeFromField : store.storeCd;
    return StoreMstWritePayload.fromMap({
      StoreMstWritePayload.jsonKeyStoreCd: storeCd,
      StoreMstWritePayload.jsonKeyStoreNm: _storeNameController.text.trim(),
      StoreMstWritePayload.jsonKeyOwnerNm: store.ownerNm,
      StoreMstWritePayload.jsonKeyRegionCd: _effRegion(),
      StoreMstWritePayload.jsonKeyStoreTel: storeTel,
      StoreMstWritePayload.jsonKeyAddress: store.address,
      StoreMstWritePayload.jsonKeyStoreStatus: _effStatus(),
      StoreMstWritePayload.jsonKeyContEndDt: _emptyToNull(store.contEndDt),
      StoreMstWritePayload.jsonKeyAutoRenewalYn: true,
      StoreMstWritePayload.jsonKeyStoreType: _effType(),
      StoreMstWritePayload.jsonKeySvId: store.svId,
      StoreMstWritePayload.jsonKeyAdressDetail: store.addressDetail,
      StoreMstWritePayload.jsonKeyZipCd: store.zipCd,
      StoreMstWritePayload.jsonKeyBrandCd: _effBrand(),
      StoreMstWritePayload.jsonKeyContStartDt: _emptyToNull(store.contStartDt),
      StoreMstWritePayload.jsonKeyFirstContDt: _emptyToNull(store.firstContDt),
      StoreMstWritePayload.jsonKeyBusinessNumber: _businessNumberController.text
          .trim(),
      StoreMstWritePayload.jsonKeyFrFee: _numberToNull(store.frFee),
      StoreMstWritePayload.jsonKeyEduFee: _numberToNull(store.eduFee),
      StoreMstWritePayload.jsonKeyInsuDeposit: _numberToNull(store.insuDeposit),
      StoreMstWritePayload.jsonKeyContDeposit: _numberToNull(store.contDeposit),
      StoreMstWritePayload.jsonKeyContManager: store.contManager,
      StoreMstWritePayload.jsonKeyEduManager: store.eduManager,
      StoreMstWritePayload.jsonKeyContArea: _numberToNull(store.contArea),
      StoreMstWritePayload.jsonKeyRealArea: _numberToNull(store.realArea),
      StoreMstWritePayload.jsonKeyFloor: store.floor,
      StoreMstWritePayload.jsonKeyParkingCount: store.parkingCount,
      StoreMstWritePayload.jsonKeyPremiumFee: store.premiumFee,
      StoreMstWritePayload.jsonKeyMonthlyRent: store.monthlyRent,
      StoreMstWritePayload.jsonKeyRentDeposit: store.rentDeposit,
    });
  }

  StoreMstWritePayload toCreatePayload({required String storeTel}) {
    final m = <String, dynamic>{
      StoreMstWritePayload.jsonKeyStoreCd: _storeCodeController.text.trim(),
      StoreMstWritePayload.jsonKeyStoreNm: _storeNameController.text.trim(),
      StoreMstWritePayload.jsonKeyOwnerNm: null,
      StoreMstWritePayload.jsonKeyRegionCd: _emptyToNull(_effRegion()),
      StoreMstWritePayload.jsonKeyStoreTel: _emptyToNull(storeTel),
      StoreMstWritePayload.jsonKeyAddress: null,
      StoreMstWritePayload.jsonKeyStoreStatus: _emptyToNull(_effStatus()),
      StoreMstWritePayload.jsonKeyContEndDt: null,
      StoreMstWritePayload.jsonKeyAutoRenewalYn: true,
      StoreMstWritePayload.jsonKeyStoreType: _emptyToNull(_effType()),
      StoreMstWritePayload.jsonKeySvId: null,
      StoreMstWritePayload.jsonKeyAdressDetail: null,
      StoreMstWritePayload.jsonKeyZipCd: null,
      StoreMstWritePayload.jsonKeyBrandCd: _emptyToNull(_effBrand()),
      StoreMstWritePayload.jsonKeyContStartDt: null,
      StoreMstWritePayload.jsonKeyFirstContDt: null,
      StoreMstWritePayload.jsonKeyBusinessNumber: _emptyToNull(
        _businessNumberController.text,
      ),
      StoreMstWritePayload.jsonKeyFrFee: 0,
      StoreMstWritePayload.jsonKeyEduFee: 0,
      StoreMstWritePayload.jsonKeyInsuDeposit: 0,
      StoreMstWritePayload.jsonKeyContDeposit: 0,
      StoreMstWritePayload.jsonKeyContManager: null,
      StoreMstWritePayload.jsonKeyEduManager: null,
      StoreMstWritePayload.jsonKeyContArea: 0,
      StoreMstWritePayload.jsonKeyRealArea: 0,
      StoreMstWritePayload.jsonKeyFloor: 0,
      StoreMstWritePayload.jsonKeyParkingCount: 0,
      StoreMstWritePayload.jsonKeyPremiumFee: 0,
      StoreMstWritePayload.jsonKeyMonthlyRent: 0,
      StoreMstWritePayload.jsonKeyRentDeposit: 0,
    };
    final pid = widget.registerDraft?.partnerIdx;
    if (pid != null) {
      m[StoreMstWritePayload.jsonKeyPartnerIdx] = pid;
    }
    return StoreMstWritePayload.fromMap(m);
  }

  String? _emptyToNull(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }

  num? _numberToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return num.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final canEdit = widget.isEditing;
    final brandOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(40)).value ?? const <CodeOption>[],
      _effBrand(),
      store?.brandNm ?? '',
    );
    final statusOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(10)).value ?? const <CodeOption>[],
      _effStatus(),
      store?.storeStatusNm ?? '',
    );
    final regionOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(20)).value ?? const <CodeOption>[],
      _effRegion(),
      store?.regionNm ?? '',
    );
    final typeOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(30)).value ?? const <CodeOption>[],
      _effType(),
      (store?.storeTypeNm ?? '').isNotEmpty
          ? store!.storeTypeNm
          : _storeTypeFallbackName(_effType()),
    );
    _applyRegisterDefaultSelections(
      brandOptions: brandOptions,
      statusOptions: statusOptions,
      regionOptions: regionOptions,
      typeOptions: typeOptions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRowTwo(
          left: FormFieldBlock(
            requiredField: true,
            label: '브랜드',
            child: canEdit
                ? brandOptions.isEmpty
                      ? ReadonlyValue(store?.brandNm ?? store?.brandCd ?? '-')
                      : DropdownButtonFormField<String>(
                          key: ValueKey(
                            'brand-${store?.storeIdx}-${_effBrand()}',
                          ),
                          initialValue: _selectedCode(
                            _effBrand(),
                            brandOptions,
                          ),
                          isExpanded: true,
                          isDense: true,
                          style: FormStylePalette.valueStyle,
                          decoration: _commonStoreDropdownDecoration(),
                          items: [
                            for (final brand in brandOptions)
                              DropdownMenuItem<String>(
                                value: brand.codeCd,
                                child: Text(
                                  brand.codeNm,
                                  style: FormStylePalette.valueStyle,
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) _setBrand(v);
                          },
                        )
                : ReadonlyValue(store?.brandNm ?? store?.brandCd ?? '-'),
          ),
          right: FormFieldBlock(
            requiredField: true,
            label: '가맹점명',
            child: canEdit
                ? _storeDetailOutlineTextField(_storeNameController)
                : ReadonlyValue(store?.storeNm ?? '-'),
          ),
        ),

        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '가맹점코드',
            child: canEdit
                ? _storeDetailOutlineTextField(_storeCodeController)
                : ReadonlyValue(store?.storeCd ?? ''),
          ),
          right: FormFieldBlock(
            label: '사업자번호',
            child: canEdit
                ? _storeDetailOutlineTextField(_businessNumberController)
                : ReadonlyValue(store?.businessNumber ?? '-'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '계약상태',
            requiredField: true,
            child: canEdit
                ? statusOptions.isEmpty
                      ? ReadonlyValue(store?.storeStatusNm ?? '-')
                      : DropdownButtonFormField<String>(
                          key: ValueKey(
                            'status-${store?.storeIdx}-${_effStatus()}',
                          ),
                          initialValue: _selectedCode(
                            _effStatus(),
                            statusOptions,
                          ),
                          isExpanded: true,
                          isDense: true,
                          style: FormStylePalette.valueStyle,
                          decoration: _commonStoreDropdownDecoration(),
                          items: [
                            for (final status in statusOptions)
                              DropdownMenuItem<String>(
                                value: status.codeCd,
                                child: Text(
                                  status.codeNm,
                                  style: FormStylePalette.valueStyle,
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) _setStatus(v);
                          },
                        )
                : ReadonlyValue(store?.storeStatusNm ?? '-'),
          ),
          b: FormFieldBlock(
            label: '그룹',
            requiredField: true,
            child: typeOptions.isEmpty
                ? ReadonlyValue(
                    (store?.storeTypeNm ?? '').isNotEmpty
                        ? store!.storeTypeNm
                        : _storeTypeFallbackName(store?.storeType ?? '-'),
                  )
                : DropdownButtonFormField<String>(
                    key: ValueKey('type-${store?.storeCd}-${_effType()}'),
                    initialValue: _selectedCode(_effType(), typeOptions),
                    isExpanded: true,
                    isDense: true,
                    style: FormStylePalette.valueStyle,
                    decoration: _commonStoreDropdownDecoration(),
                    items: [
                      for (final t in typeOptions)
                        DropdownMenuItem<String>(
                          value: t.codeCd,
                          child: Text(
                            t.codeNm,
                            style: FormStylePalette.valueStyle,
                          ),
                        ),
                    ],
                    onChanged: canEdit
                        ? (v) {
                            if (v != null) _setType(v);
                          }
                        : null,
                  ),
          ),
          c: FormFieldBlock(
            label: '지역',
            child: regionOptions.isEmpty
                ? ReadonlyValue(store?.regionNm ?? store?.regionCd ?? '-')
                : DropdownButtonFormField<String>(
                    key: ValueKey('region-${store?.storeCd}-${_effRegion()}'),
                    initialValue: _selectedCode(_effRegion(), regionOptions),
                    isExpanded: true,
                    isDense: true,
                    style: FormStylePalette.valueStyle,
                    decoration: _commonStoreDropdownDecoration(),
                    items: [
                      for (final r in regionOptions)
                        DropdownMenuItem<String>(
                          value: r.codeCd,
                          child: Text(
                            r.codeNm,
                            style: FormStylePalette.valueStyle,
                          ),
                        ),
                    ],
                    onChanged: canEdit
                        ? (v) {
                            if (v != null) _setRegion(v);
                          }
                        : null,
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 미구현 탭
// ---------------------------------------------------------------------------

/// 아직 별도 폼이 준비되지 않은 탭의 기본 안내 플레이스홀더.
class PlaceholderTabContent extends StatelessWidget {
  const PlaceholderTabContent({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '$title 영역은 준비 중입니다.',
        style: const TextStyle(
          color: FormStylePalette.textMuted,
          fontSize: 14,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 문서 테이블
// ---------------------------------------------------------------------------

/// 문서 목록 테이블의 한 컬럼 정의.
class DocumentColumn {
  const DocumentColumn({
    required this.label,
    required this.flex,
    this.alignStart = false,
  });

  final String label;
  final int flex;
  final bool alignStart;
}

const List<DocumentColumn> kDocumentColumns = [
  DocumentColumn(label: '파일명', flex: 5, alignStart: true),
  DocumentColumn(label: '수정일자', flex: 2),
  DocumentColumn(label: '수정자', flex: 1),
  DocumentColumn(label: '문서 첨부', flex: 1),
  DocumentColumn(label: '첨부 기준일', flex: 2),
  DocumentColumn(label: '첨부일', flex: 2),
];

class DocumentsTable extends StatelessWidget {
  const DocumentsTable({
    super.key,
    required this.rows,
    required this.selectedIndex,
    required this.onRowTap,
  });

  final List<Document> rows;
  final int? selectedIndex;
  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    return _AlwaysVisibleHorizontalScroll(
      minWidth: 1120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FormStylePalette.panelBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FormStylePalette.panelBorder),
        ),
        child: Column(
          children: [
            const _DocumentsTableHeader(columns: kDocumentColumns),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '표시할 문서가 없습니다.',
                  style: TextStyle(
                    color: FormStylePalette.textMuted,
                    fontSize: 13,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++)
                _DocumentsTableRow(
                  row: rows[i],
                  columns: kDocumentColumns,
                  selected: selectedIndex == i,
                  onTap: () => onRowTap(i),
                ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsTableHeader extends StatelessWidget {
  const _DocumentsTableHeader({required this.columns});

  final List<DocumentColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FormStylePalette.tableHeaderBg,
        border: Border(
          bottom: BorderSide(color: FormStylePalette.panelBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2E5EB),
              ),
            Expanded(
              flex: columns[i].flex,
              child: Text(
                columns[i].label,
                textAlign: columns[i].alignStart
                    ? TextAlign.left
                    : TextAlign.center,
                style: const TextStyle(
                  color: FormStylePalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsTableRow extends StatelessWidget {
  const _DocumentsTableRow({
    required this.row,
    required this.columns,
    required this.selected,
    required this.onTap,
  });

  final Document row;
  final List<DocumentColumn> columns;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? FormStylePalette.accent.withValues(alpha: 0.18)
        : Colors.transparent;
    final values = <String>[
      row.fileName,
      row.modifiedAt,
      row.modifiedBy,
      row.attached ? 'O' : 'X',
      row.attachmentBaseDate,
      row.attachedAt,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: FormStylePalette.accent.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: const Border(
              bottom: BorderSide(color: FormStylePalette.rowDivider, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0)
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFE2E5EB),
                  ),
                Expanded(
                  flex: columns[i].flex,
                  child: Text(
                    values[i],
                    textAlign: columns[i].alignStart
                        ? TextAlign.left
                        : TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: columns[i].label == '문서 첨부' && !row.attached
                          ? FormStylePalette.danger
                          : FormStylePalette.textPrimary,
                      fontSize: 13,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlwaysVisibleHorizontalScroll extends StatefulWidget {
  const _AlwaysVisibleHorizontalScroll({
    required this.child,
    required this.minWidth,
  });

  final Widget child;
  final double minWidth;

  @override
  State<_AlwaysVisibleHorizontalScroll> createState() =>
      _AlwaysVisibleHorizontalScrollState();
}

class _AlwaysVisibleHorizontalScrollState
    extends State<_AlwaysVisibleHorizontalScroll> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width = maxWidth.isFinite && maxWidth > widget.minWidth
            ? maxWidth
            : widget.minWidth;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: width, child: widget.child),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 문서 필터 / 선택 바 / 상단 바
// ---------------------------------------------------------------------------

/// 문서 탭의 필터 행 (유형 드롭다운 + 파일명 검색 + 검색 버튼).
class DocumentsFilterRow extends StatelessWidget {
  const DocumentsFilterRow({
    super.key,
    required this.typeValue,
    required this.typeOptions,
    required this.onTypeChanged,
    required this.searchController,
    required this.onSearch,
  });

  final String typeValue;
  final List<String> typeOptions;
  final ValueChanged<String?> onTypeChanged;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _DocumentsFieldLabel('유형'),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: ReadonlyInputShell(
            child: DropdownButton<String>(
              value: typeValue,
              isExpanded: true,
              isDense: true,
              dropdownColor: Colors.white,
              underline: const SizedBox.shrink(),
              iconEnabledColor: FormStylePalette.textSecondary,
              style: FormStylePalette.valueStyle,
              items: typeOptions
                  .map(
                    (o) => DropdownMenuItem<String>(value: o, child: Text(o)),
                  )
                  .toList(),
              onChanged: onTypeChanged,
            ),
          ),
        ),
        const SizedBox(width: 24),
        const _DocumentsFieldLabel('파일명'),
        const SizedBox(width: 8),
        Expanded(
          child: _DocumentsTextField(
            controller: searchController,
            hintText: '',
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onSearch,
          style: FilledButton.styleFrom(
            backgroundColor: FormStylePalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            '검색',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsFieldLabel extends StatelessWidget {
  const _DocumentsFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: FormStylePalette.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}

class _DocumentsTextField extends StatelessWidget {
  const _DocumentsTextField({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        style: FormStylePalette.valueStyle,
        cursorColor: FormStylePalette.accent,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: FormStylePalette.textMuted),
          filled: true,
          fillColor: FormStylePalette.inputBg,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: FormStylePalette.panelBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FormStylePalette.panelBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: FormStylePalette.accent,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

/// 선택된 문서 파일명 + 미리보기/다운로드/문서이력 액션 버튼.
class DocumentsSelectedRowBar extends StatelessWidget {
  const DocumentsSelectedRowBar({
    super.key,
    required this.selectedFileName,
    required this.onPreview,
    required this.onDownload,
    required this.onHistory,
  });

  final String selectedFileName;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ReadonlyInputShell(
            child: Text(
              selectedFileName,
              style: FormStylePalette.valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _DocumentsActionButton(label: '미리보기', onPressed: onPreview),
        const SizedBox(width: 6),
        _DocumentsActionButton(label: '다운로드', onPressed: onDownload),
        const SizedBox(width: 6),
        _DocumentsActionButton(label: '문서이력', onPressed: onHistory),
      ],
    );
  }
}

class _DocumentsActionButton extends StatelessWidget {
  const _DocumentsActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: accentOutlineButtonStyle(iconOnly: false),
      child: Text(
        label,
        style: const TextStyle(
          color: FormStylePalette.accent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

/// 문서 업로드 버튼 + 안내 텍스트로 구성된 최상단 바.
class DocumentsTopBar extends StatelessWidget {
  const DocumentsTopBar({super.key, required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text(
            '문서 업로드',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: FormStylePalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '• 문서 업로드 파일 크기는 50MB까지 가능합니다.',
          style: TextStyle(
            color: FormStylePalette.textSecondary,
            fontSize: 12,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 기간(시작–종료) 한 행 — 기본/계약 탭 공용
// ---------------------------------------------------------------------------

class _StoreDateRangeRow extends StatelessWidget {
  const _StoreDateRangeRow({
    required this.start,
    required this.end,
    this.onPickStart,
    this.onPickEnd,
    this.onChangedStart,
    this.onChangedEnd,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback? onPickStart;
  final VoidCallback? onPickEnd;
  final ValueChanged<DateTime?>? onChangedStart;
  final ValueChanged<DateTime?>? onChangedEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DateInputWithPicker(
            value: start,
            onPick: onPickStart,
            onChanged: onChangedStart,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
          child: Text(
            '-',
            style: TextStyle(
              color: FormStylePalette.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: DateInputWithPicker(
            value: end,
            onPick: onPickEnd,
            onChanged: onChangedEnd,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 기본정보 탭
// ---------------------------------------------------------------------------

class BasicInfoTab extends ConsumerStatefulWidget {
  const BasicInfoTab({
    super.key,
    this.store,
    required this.panelEditing,
    required this.storeTelController,
    this.registerDraft,
    this.onPropertySelected,
  });

  final Store? store;

  /// [StoreDetailPanel] 헤더의 수정 모드와 동기화된다.
  final bool panelEditing;
  final TextEditingController storeTelController;
  final StoreRegisterDraft? registerDraft;
  final ValueChanged<Property>? onPropertySelected;

  @override
  ConsumerState<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends ConsumerState<BasicInfoTab> {
  late DateTime? _firstContDt;
  late DateTime? _contractExpiryDate;
  late TextEditingController _floorController;
  late TextEditingController _parkingController;
  late TextEditingController _contArea;
  late TextEditingController _realAreaController;
  late TextEditingController _notesController;
  late TextEditingController _storeNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _zipCodeController;
  late TextEditingController _addressController;
  late TextEditingController _addressDetailController;
  late TextEditingController _rentDepositController;
  late TextEditingController _premiumFeeController;
  late TextEditingController _monthlyRentController;
  String? _latitude;
  String? _longitude;

  Store? get _store => widget.store;

  @override
  void initState() {
    super.initState();
    final draft = widget.registerDraft;
    _floorController = draft?.floorController ?? TextEditingController();
    _parkingController = draft?.parkingController ?? TextEditingController();
    _contArea =
        draft?.contAreaController ??
        TextEditingController(text: _store?.contArea ?? '');
    _realAreaController =
        draft?.realAreaController ??
        TextEditingController(text: _store?.realArea ?? '');
    _storeNameController =
        draft?.propertyNameController ??
        TextEditingController(text: _store?.storeNm ?? '');
    _ownerNameController =
        draft?.ownerNameController ??
        TextEditingController(text: _store?.ownerNm ?? '');
    _zipCodeController =
        draft?.zipCodeController ??
        TextEditingController(text: _store?.zipCd ?? '');
    _addressController =
        draft?.addressController ??
        TextEditingController(text: _store?.address ?? '');
    _addressDetailController =
        draft?.addressDetailController ??
        TextEditingController(text: _store?.addressDetail ?? '');
    _latitude = draft?.latitude ?? _store?.latitude;
    _longitude = draft?.longitude ?? _store?.longitude;
    _notesController =
        draft?.notesController ??
        TextEditingController(text: _store?.notes ?? '');
    _rentDepositController =
        draft?.rentDepositController ??
        TextEditingController(text: _formatMoneyInput(_store?.rentDeposit));
    _premiumFeeController =
        draft?.premiumFeeController ??
        TextEditingController(text: _formatMoneyInput(_store?.premiumFee));
    _monthlyRentController =
        draft?.monthlyRentController ??
        TextEditingController(text: _formatMoneyInput(_store?.monthlyRent));
    _syncDates();
  }

  @override
  void didUpdateWidget(covariant BasicInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        (!oldWidget.panelEditing && widget.panelEditing)) {
      setState(_syncDates);
      _floorController.text = _store?.floor.toString() ?? '';
      _parkingController.text = _store?.parkingCount.toString() ?? '';
      _contArea.text = _store?.contArea ?? '';
      _realAreaController.text = _store?.realArea ?? '';
      _storeNameController.text = _store?.storeNm ?? '';
      _ownerNameController.text = _store?.ownerNm ?? '';
      _zipCodeController.text = _store?.zipCd ?? '';
      _addressController.text = _store?.address ?? '';
      _addressDetailController.text = _store?.addressDetail ?? '';
      _rentDepositController.text = _store?.rentDeposit.toString() ?? '0';
      _premiumFeeController.text = _store?.premiumFee.toString() ?? '0';
      _monthlyRentController.text = _store?.monthlyRent.toString() ?? '0';
      _notesController.text = _store?.notes ?? '';
      final d = widget.registerDraft;
      if (d == null) {
        _latitude = _store?.latitude;
        _longitude = _store?.longitude;
      } else {
        _latitude = d.latitude;
        _longitude = d.longitude;
      }
    }
  }

  @override
  void dispose() {
    if (widget.registerDraft == null) {
      _floorController.dispose();
      _parkingController.dispose();
      _contArea.dispose();
      _realAreaController.dispose();
      _notesController.dispose();
      _storeNameController.dispose();
      _ownerNameController.dispose();
      _zipCodeController.dispose();
      _addressController.dispose();
      _addressDetailController.dispose();
      _rentDepositController.dispose();
      _premiumFeeController.dispose();
      _monthlyRentController.dispose();
    }
    super.dispose();
  }

  void _syncDates() {
    final draft = widget.registerDraft;
    if (draft != null && widget.store == null) {
      _firstContDt = draft.firstContDt;
      _contractExpiryDate = draft.contractExpiryDate;
      return;
    }
    _firstContDt = tryParseLooseDate(widget.store?.firstContDt);
    _contractExpiryDate = tryParseLooseDate(widget.store?.contEndDt);
  }

  /// 계약정보 탭만 저장할 때도 요청에 포함되도록 분리.
  StoreMstWritePayload toGeoUpdatePayload() => StoreMstWritePayload.fromMap({
    StoreMstWritePayload.jsonKeyLatitude: _decimalToNull(_latitude),
    StoreMstWritePayload.jsonKeyLongitude: _decimalToNull(_longitude),
  });

  StoreMstWritePayload toUpdatePayload() {
    return StoreMstWritePayload.fromMap({
      ...toGeoUpdatePayload().toRequestBody(),
      StoreMstWritePayload.jsonKeyFirstContDt: _dateToYmd(_firstContDt),
      StoreMstWritePayload.jsonKeyContEndDt: _dateToYmd(_contractExpiryDate),
      StoreMstWritePayload.jsonKeyOwnerNm: _ownerNameController.text.trim(),
      StoreMstWritePayload.jsonKeyZipCd: _emptyToNull(_zipCodeController.text),
      StoreMstWritePayload.jsonKeyAddress: _emptyToNull(
        _addressController.text,
      ),
      StoreMstWritePayload.jsonKeyAdressDetail: _emptyToNull(
        _addressDetailController.text,
      ),
      StoreMstWritePayload.jsonKeyContArea: _numberToNull(_contArea.text),
      StoreMstWritePayload.jsonKeyRealArea: _numberToNull(
        _realAreaController.text,
      ),
      StoreMstWritePayload.jsonKeyFloor: _intToNull(_floorController.text),
      StoreMstWritePayload.jsonKeyParkingCount: _intToNull(
        _parkingController.text,
      ),
      StoreMstWritePayload.jsonKeyRentDeposit: _intToNull(
        _rentDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyPremiumFee: _intToNull(
        _premiumFeeController.text,
      ),
      StoreMstWritePayload.jsonKeyMonthlyRent: _intToNull(
        _monthlyRentController.text,
      ),
      StoreMstWritePayload.jsonKeyNotes: _notesController.text.trim(),
    });
  }

  String? _dateToYmd(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  num? _numberToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return num.tryParse(normalized);
  }

  int? _intToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return int.tryParse(normalized);
  }

  num? _decimalToNull(String? value) {
    final normalized = value?.replaceAll(',', '').trim() ?? '';
    if (normalized.isEmpty || normalized == '-') return null;
    return num.tryParse(normalized);
  }

  String _sqmToPyeong(String? rawSqm) {
    final normalized = rawSqm?.replaceAll(',', '').trim();
    final sqm = double.tryParse(normalized ?? '');
    if (sqm == null) return '-';
    return (sqm / 3.305785).toStringAsFixed(1);
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  Future<void> _openPropertyLookup() async {
    if (!widget.panelEditing) {
      _snack('수정 모드에서 물건 정보를 선택할 수 있습니다.');
      return;
    }

    final selected = await showDialog<Property>(
      context: context,
      builder: (dialogContext) => _PropertyLookupDialog(
        // 캐시된 빈 목록·구형 파싱 실패를 피하고, 열 때마다 API에서 다시 받는다.
        propertiesFuture: ref.read(propertyRepositoryProvider).all(),
      ),
    );
    if (selected == null || !mounted) return;

    final detail =
        await ref
            .read(propertyApiServiceProvider)
            .getProperty(selected.propIdx) ??
        selected;
    if (!mounted) return;
    _applyProperty(detail);
  }

  Future<void> _openPartnerLookup() async {
    if (!widget.panelEditing) {
      _snack('수정 모드에서 예비창업자를 선택할 수 있습니다.');
      return;
    }

    final selected = await showDialog<Partner>(
      context: context,
      builder: (dialogContext) => PartnerLookupDialog(
        partnersFuture: ref.read(partnerDataProvider.future),
      ),
    );
    if (selected == null || !mounted) return;

    final detail =
        await ref
            .read(partnerApiServiceProvider)
            .fetchOne(selected.partnerIdx) ??
        selected;
    if (!mounted) return;
    _applyPartner(detail);
  }

  void _applyPartner(Partner partner) {
    final formattedTel = _formatPhoneNumber(partner.partnerTel);
    setState(() {
      _ownerNameController.text = partner.partnerNm;
      widget.storeTelController.text = formattedTel;
    });

    final draft = widget.registerDraft;
    if (draft != null) {
      draft.ownerNameController.text = partner.partnerNm;
      draft.storeTelController.text = formattedTel;
      draft.partnerIdx = partner.partnerIdx;
    }
  }

  void _applyProperty(Property property) {
    setState(() {
      _storeNameController.text = property.name;
      _zipCodeController.text = property.postalCode;
      _addressController.text = property.address;
      _addressDetailController.text = property.addressDetail;
      _contArea.text = _numberText(property.areaSqm);
      _realAreaController.text = _numberText(property.actualAreaSqm);
      _floorController.text = property.floor == '-' ? '' : property.floor;
      _rentDepositController.text = property.deposit == 0
          ? ''
          : property.deposit.toString();
      _premiumFeeController.text = property.keyMoney == 0
          ? ''
          : property.keyMoney.toString();
      _monthlyRentController.text = property.rent == 0
          ? ''
          : property.rent.toString();
      _latitude = property.latitude;
      _longitude = property.longitude;
      // 물건의 특이사항을 가맹점 특이사항으로 복사
      _notesController.text = property.notes;
    });

    final draft = widget.registerDraft;
    if (draft != null) {
      draft.storeNameController.text = property.name;
      draft.propertyNameController.text = property.name;
      draft.zipCodeController.text = property.postalCode;
      draft.addressController.text = property.address;
      draft.addressDetailController.text = property.addressDetail;
      draft.contAreaController.text = _numberText(property.areaSqm);
      draft.realAreaController.text = _numberText(property.actualAreaSqm);
      draft.floorController.text = property.floor == '-' ? '' : property.floor;
      draft.rentDepositController.text = property.deposit == 0
          ? ''
          : _formatMoneyInput(property.deposit);
      draft.premiumFeeController.text = property.keyMoney == 0
          ? ''
          : _formatMoneyInput(property.keyMoney);
      draft.monthlyRentController.text = property.rent == 0
          ? ''
          : _formatMoneyInput(property.rent);
      draft.latitude = property.latitude;
      draft.longitude = property.longitude;
      // draft의 notes도 업데이트
      draft.notesController.text = property.notes;
    }

    widget.onPropertySelected?.call(property);
    _snack('물건 정보가 입력되었습니다.');
  }

  String _numberText(num value) {
    if (value == 0) return '';
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRowTwo(
          left: FormFieldBlock(
            requiredField: true,
            label: '가맹점 사업자 성명',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: widget.panelEditing
                      ? _storeDetailOutlineTextField(
                          _ownerNameController,
                          keyboardType: TextInputType.text,
                        )
                      : ReadonlyValue(_store?.ownerNm ?? '-'),
                ),
                if (widget.panelEditing) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _openPartnerLookup,
                    icon: const Icon(Icons.search, size: 18),
                    tooltip: '예비창업자 조회',
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
          right: FormFieldBlock(
            requiredField: true,
            label: '연락처',
            child: widget.panelEditing
                ? _storeDetailOutlineTextField(
                    widget.storeTelController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneNumberTextInputFormatter()],
                  )
                : ReadonlyValue(
                    _formatPhoneNumberOrDash(_store?.storeTel ?? ''),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '물건명',
          requiredField: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.panelEditing
                    ? _storeDetailOutlineTextField(_storeNameController)
                    : ReadonlyInputShell(
                        child: Text(
                          _store?.storeNm ?? '-',
                          style: FormStylePalette.valueStyle,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _openPropertyLookup,
                style: accentOutlineButtonStyle(iconOnly: false),
                child: const Text(
                  '물건 상세정보 조회',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LabeledFormRow(
          label: '주소',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: widget.panelEditing
                        ? _storeDetailOutlineTextField(_zipCodeController)
                        : ReadonlyInputShell(
                            child: Text(
                              _store == null ? '-' : '12345',
                              style: FormStylePalette.valueStyle,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  AccentOutlinedButton(
                    label: '지도보기/영업지역',
                    onPressed: () => _snack('지도보기는 추후 연결됩니다.'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              widget.panelEditing
                  ? _storeDetailOutlineTextField(_addressController)
                  : ReadonlyInputShell(
                      child: Text(
                        _store?.address ?? '-',
                        style: FormStylePalette.valueStyle,
                      ),
                    ),
              const SizedBox(height: 8),
              widget.panelEditing
                  ? _storeDetailOutlineTextField(_addressDetailController)
                  : ReadonlyInputShell(
                      child: Text(
                        _store?.addressDetail ?? '-',
                        style: FormStylePalette.valueStyle,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // FormRowTwo(
        //   left: FormFieldBlock(
        //     label: '연락처',
        //     child: widget.panelEditing
        //         ? _storeDetailOutlineTextField(
        //             widget.storeTelController,
        //             keyboardType: TextInputType.phone,
        //             inputFormatters: [_PhoneNumberTextInputFormatter()],
        //           )
        //         : ReadonlyValue(
        //             _formatPhoneNumberOrDash(_store?.storeTel ?? ''),
        //           ),
        //   ),
        //   right: const FormFieldBlock(label: ' ', child: SizedBox.shrink()),
        // right: FormFieldBlock(
        //   label: '임대차 기간',
        //   child: _StoreDateRangeRow(
        //     start: _leaseStartDate,
        //     end: _leaseEndDate,
        //     onPickStart: widget.panelEditing
        //         ? () => _pickDate(
        //             current: _leaseStartDate,
        //             onPicked: _setLeaseStartDate,
        //           )
        //         : null,
        //     onPickEnd: widget.panelEditing
        //         ? () => _pickDate(
        //             current: _leaseEndDate,
        //             onPicked: _setLeaseEndDate,
        //           )
        //         : null,
        //     onChangedStart: widget.panelEditing
        //         ? (value) {
        //             if (value != null) {
        //               setState(() => _setLeaseStartDate(value));
        //             }
        //           }
        //         : null,
        //     onChangedEnd: widget.panelEditing
        //         ? (value) {
        //             if (value != null) {
        //               setState(() => _setLeaseEndDate(value));
        //             }
        //           }
        //         : null,
        //   ),
        // ),
        // ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '면적(계약㎡)',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _contArea,
                          keyboardType: TextInputType.number,
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
                    ],
                  )
                : UnitPairRow(
                    primary: _store?.contArea ?? '-',
                    primarySuffix: '㎡',
                    secondary: _sqmToPyeong(_store?.contArea),
                    secondarySuffix: '평',
                  ),
          ),
          right: FormFieldBlock(
            label: '면적(실㎡)',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _realAreaController,
                          keyboardType: TextInputType.number,
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
                    ],
                  )
                : UnitPairRow(
                    primary: _store?.realArea ?? '-',
                    primarySuffix: '㎡',
                    secondary: _sqmToPyeong(_store?.realArea),
                    secondarySuffix: '평',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '층수',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _floorController,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '층',
                        style: TextStyle(
                          fontSize: 14,
                          color: FormStylePalette.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ],
                  )
                : ReadonlyWithSuffix(
                    value: _store?.floor.toString() ?? '-',
                    suffix: '층',
                  ),
          ),
          right: FormFieldBlock(
            label: '주차가능대수',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _parkingController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '대',
                        style: TextStyle(
                          fontSize: 14,
                          color: FormStylePalette.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ],
                  )
                : ReadonlyWithSuffix(
                    value: _store?.parkingCount.toString() ?? '-',
                    suffix: '대',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '임대차 보증금',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _rentDepositController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.rentDeposit),
                    suffix: '원',
                  ),
          ),
          b: FormFieldBlock(
            label: '권리금',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _premiumFeeController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.premiumFee),
                    suffix: '원',
                  ),
          ),
          c: FormFieldBlock(
            label: '임차료',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _monthlyRentController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.monthlyRent),
                    suffix: '원',
                  ),
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
                child: widget.panelEditing
                    ? _storeDetailOutlineMultilineTextField(_notesController)
                    : ReadonlyInputShell(
                        child: Text(
                          _store?.notes ?? '-',
                          style: FormStylePalette.valueStyle,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _lookupSearchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: FormStylePalette.textMuted,
      fontSize: 13,
      fontFamilyFallback: AppTheme.koreanFontFallback,
    ),
    isDense: true,
    filled: true,
    fillColor: FormStylePalette.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    prefixIcon: const Icon(
      Icons.search_rounded,
      size: 20,
      color: FormStylePalette.textSecondary,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
    ),
  );
}

class _PropertyLookupDialog extends StatefulWidget {
  const _PropertyLookupDialog({required this.propertiesFuture});

  final Future<List<Property>> propertiesFuture;

  @override
  State<_PropertyLookupDialog> createState() => _PropertyLookupDialogState();
}

class _PropertyLookupDialogState extends State<_PropertyLookupDialog> {
  final _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Property> _filter(List<Property> rows) {
    final q = _keywordController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((property) {
      final address = _propertyAddress(property);
      return property.name.toLowerCase().contains(q) ||
          address.toLowerCase().contains(q) ||
          property.propIdx.toString().contains(q);
    }).toList();
  }

  String _propertyAddress(Property property) {
    final detail = property.addressDetail.trim();
    if (detail.isEmpty) return property.address;
    return '${property.address} $detail';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ErpDialogFrame(
        title: '물건 상세정보 조회',
        maxWidth: 860,
        maxHeight: 640,
        child: SizedBox(
          height: 520,
          child: FutureBuilder<List<Property>>(
            future: widget.propertiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CommonLoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '물건 목록을 불러오지 못했습니다.',
                    style: FormStylePalette.valueStyle,
                  ),
                );
              }

              final properties = _filter(snapshot.data ?? const <Property>[]);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _keywordController,
                    onChanged: (_) => setState(() {}),
                    style: FormStylePalette.valueStyle,
                    decoration: _lookupSearchDecoration('물건명, 주소, 번호 검색'),
                  ),
                  const SizedBox(height: 12),
                  const _PropertyLookupHeader(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: properties.isEmpty
                        ? Center(
                            child: Text(
                              '조회된 물건이 없습니다.',
                              style: FormStylePalette.valueStyle,
                            ),
                          )
                        : ListView.separated(
                            itemCount: properties.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFE5E7EB),
                            ),
                            itemBuilder: (context, index) {
                              final property = properties[index];
                              return _PropertyLookupRow(
                                stripeIndex: index,
                                property: property,
                                displayNo: index + 1,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PropertyLookupHeader extends StatelessWidget {
  const _PropertyLookupHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: FormStylePalette.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          SizedBox(width: 70, child: _PropertyLookupHeaderText('NO')),
          Expanded(flex: 2, child: _PropertyLookupHeaderText('물건명')),
          Expanded(flex: 3, child: _PropertyLookupHeaderText('주소')),
          SizedBox(width: 100, child: _PropertyLookupHeaderText('보증금')),
          SizedBox(width: 100, child: _PropertyLookupHeaderText('임차료')),
          SizedBox(width: 100, child: _PropertyLookupHeaderText('권리금')),
        ],
      ),
    );
  }
}

class _PropertyLookupHeaderText extends StatelessWidget {
  const _PropertyLookupHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}

class _PropertyLookupRow extends StatelessWidget {
  const _PropertyLookupRow({
    required this.stripeIndex,
    required this.property,
    required this.displayNo,
  });

  final int stripeIndex;
  final Property property;
  final int displayNo;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: erpPopupListRowBackground(stripeIndex),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(property),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 30, child: _PropertyLookupCell('$displayNo')),
              Expanded(flex: 2, child: _PropertyLookupCell(property.name)),
              Expanded(
                flex: 3,
                child: _PropertyLookupCell(_propertyAddress(property)),
              ),
              SizedBox(
                width: 100,
                child: _PropertyLookupCell(property.surveyor),
              ),
              SizedBox(
                width: 100,
                child: _PropertyLookupCell(_formatWon(property.rent)),
              ),
              SizedBox(
                width: 100,
                child: _PropertyLookupCell(_formatWon(property.keyMoney)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _propertyAddress(Property property) {
    final detail = property.addressDetail.trim();
    if (detail.isEmpty) return property.address;
    return '${property.address} $detail';
  }

  String _formatWon(int value) {
    if (value == 0) return '-';
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _PropertyLookupCell extends StatelessWidget {
  const _PropertyLookupCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      textAlign: TextAlign.center,
      text.isEmpty ? '-' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: FormStylePalette.valueStyle,
    );
  }
}

// ---------------------------------------------------------------------------
// 계약정보 탭
// ---------------------------------------------------------------------------

class ContractInfoTab extends ConsumerStatefulWidget {
  const ContractInfoTab({
    super.key,
    this.store,
    required this.panelEditing,
    this.registerDraft,
  });

  final Store? store;
  final bool panelEditing;
  final StoreRegisterDraft? registerDraft;

  @override
  ConsumerState<ContractInfoTab> createState() => _ContractInfoTabState();
}

class _ContractInfoTabState extends ConsumerState<ContractInfoTab> {
  late DateTime? _firstContDt;
  late DateTime? _currentContractStart;
  late DateTime? _currentContractEnd;
  late TextEditingController _frFreeController;
  late TextEditingController _eduFeeController;
  late TextEditingController _insuDepositController;
  late TextEditingController _contDepositController;
  // late TextEditingController _royaltyRateController;
  late TextEditingController _contManagerController;
  late TextEditingController _eduManagerController;
  late TextEditingController _supervisorController;

  Store? get _store => widget.store;

  StoreMstWritePayload toUpdatePayload() {
    return StoreMstWritePayload.fromMap({
      StoreMstWritePayload.jsonKeyFirstContDt: _dateToYmd(_firstContDt),
      StoreMstWritePayload.jsonKeyContStartDt: _dateToYmd(
        _currentContractStart,
      ),
      StoreMstWritePayload.jsonKeyContEndDt: _dateToYmd(_currentContractEnd),
      StoreMstWritePayload.jsonKeyFrFee: _numberToNull(_frFreeController.text),
      StoreMstWritePayload.jsonKeyEduFee: _numberToNull(_eduFeeController.text),
      StoreMstWritePayload.jsonKeyInsuDeposit: _numberToNull(
        _insuDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyContDeposit: _numberToNull(
        _contDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyContManager: _contManagerController.text
          .trim(),
      StoreMstWritePayload.jsonKeyEduManager: _eduManagerController.text.trim(),
      StoreMstWritePayload.jsonKeySvId: _supervisorController.text.trim(),
    });
  }

  String? _dateToYmd(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  num? _numberToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return num.tryParse(normalized);
  }

  Future<void> _openUserLookup(
    TextEditingController target, {
    required bool preferUserIdForSvField,
  }) async {
    if (!widget.panelEditing) return;
    final selected = await showDialog<User>(
      context: context,
      builder: (dialogCtx) =>
          UserLookupDialog(usersFuture: ref.read(userRepositoryProvider).all()),
    );
    if (!mounted || selected == null) return;
    final text = preferUserIdForSvField && selected.userId.trim().isNotEmpty
        ? selected.userId.trim()
        : selected.name.trim();
    setState(() => target.text = text);
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.registerDraft;
    _frFreeController =
        draft?.frFeeController ??
        TextEditingController(text: _formatMoneyInput(_store?.frFee ?? '0'));
    _eduFeeController =
        draft?.eduFeeController ??
        TextEditingController(text: _formatMoneyInput(_store?.eduFee ?? '0'));
    _insuDepositController =
        draft?.insuDepositController ??
        TextEditingController(
          text: _formatMoneyInput(_store?.insuDeposit ?? '0'),
        );
    _contDepositController =
        draft?.contDepositController ??
        TextEditingController(
          text: _formatMoneyInput(_store?.contDeposit ?? '0'),
        );
    _contManagerController =
        draft?.contManagerController ??
        TextEditingController(text: _store?.contManager ?? '');
    _eduManagerController =
        draft?.eduManagerController ??
        TextEditingController(text: _store?.eduManager ?? '');
    _supervisorController =
        draft?.supervisorController ??
        TextEditingController(text: _store?.svId ?? '');
    _syncDates();
  }

  @override
  void didUpdateWidget(covariant ContractInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        (!oldWidget.panelEditing && widget.panelEditing)) {
      setState(_syncDates);
      _frFreeController.text = _formatMoneyInput(_store?.frFee);
      _eduFeeController.text = _formatMoneyInput(_store?.eduFee);
      _insuDepositController.text = _formatMoneyInput(_store?.insuDeposit);
      _contDepositController.text = _formatMoneyInput(_store?.contDeposit);
      _contManagerController.text = _store?.contManager ?? '';
      _eduManagerController.text = _store?.eduManager ?? '';
      _supervisorController.text = _store?.svId ?? '';
    }
  }

  @override
  void dispose() {
    if (widget.registerDraft == null) {
      _frFreeController.dispose();
      _eduFeeController.dispose();
      _insuDepositController.dispose();
      _contDepositController.dispose();
      // _royaltyRateController.dispose();
      _contManagerController.dispose();
      _eduManagerController.dispose();
      _supervisorController.dispose();
    }
    super.dispose();
  }

  void _syncDates() {
    final draft = widget.registerDraft;
    if (draft != null && widget.store == null) {
      _firstContDt = draft.contractFirstContDt;
      _currentContractStart = draft.currentContractStart;
      _currentContractEnd = draft.currentContractEnd;
      return;
    }
    _firstContDt = tryParseLooseDate(widget.store?.firstContDt);
    _currentContractStart = tryParseLooseDate(widget.store?.contStartDt);
    _currentContractEnd = tryParseLooseDate(widget.store?.contEndDt);
  }

  void _setFirstContDt(DateTime value) {
    _firstContDt = value;
    widget.registerDraft?.contractFirstContDt = value;
  }

  void _setCurrentContractStart(DateTime value) {
    _currentContractStart = value;
    widget.registerDraft?.currentContractStart = value;
  }

  void _setCurrentContractEnd(DateTime value) {
    _currentContractEnd = value;
    widget.registerDraft?.currentContractEnd = value;
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showAccentDatePicker(
      context: context,
      initialDate: current,
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRowTwo(
          left: FormFieldBlock(
            label: '최초 가맹계약 체결일자',
            child: DateInputWithPicker(
              value: _firstContDt,
              onPick: widget.panelEditing
                  ? () => _pickDate(
                      current: _firstContDt,
                      onPicked: _setFirstContDt,
                    )
                  : null,
              onChanged: widget.panelEditing
                  ? (value) {
                      if (value != null) setState(() => _setFirstContDt(value));
                    }
                  : null,
            ),
          ),
          right: FormFieldBlock(
            label: '현재 가맹계약 기간',
            child: _StoreDateRangeRow(
              start: _currentContractStart,
              end: _currentContractEnd,
              onPickStart: widget.panelEditing
                  ? () => _pickDate(
                      current: _currentContractStart,
                      onPicked: _setCurrentContractStart,
                    )
                  : null,
              onPickEnd: widget.panelEditing
                  ? () => _pickDate(
                      current: _currentContractEnd,
                      onPicked: _setCurrentContractEnd,
                    )
                  : null,
              onChangedStart: widget.panelEditing
                  ? (value) {
                      if (value != null) {
                        setState(() => _setCurrentContractStart(value));
                      }
                    }
                  : null,
              onChangedEnd: widget.panelEditing
                  ? (value) {
                      if (value != null) {
                        setState(() => _setCurrentContractEnd(value));
                      }
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '가맹비',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _frFreeController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.frFee),
                    suffix: '원',
                  ),
          ),
          right: FormFieldBlock(
            label: '교육비',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _eduFeeController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.eduFee),
                    suffix: '원',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '보증보험금',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _insuDepositController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.insuDeposit),
                    suffix: '원',
                  ),
          ),
          right: FormFieldBlock(
            label: '계약보증금',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _contDepositController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorInputFormatter()],
                  )
                : ReadonlyWithSuffix(
                    value: _formatMoneyOrDash(_store?.contDeposit),
                    suffix: '원',
                  ),
          ),
        ),
        // const SizedBox(height: 12),
        // FormRowTwo(
        //   left: FormFieldBlock(
        //     label: '로열티',
        //     child: widget.panelEditing
        //         ? Row(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Expanded(
        //                 child: _storeDetailOutlineTextField(
        //                   _royaltyRateController,
        //                   keyboardType: TextInputType.number,
        //                 ),
        //               ),
        //               const SizedBox(width: 6),
        //               const Text(
        //                 '%',
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   color: FormStylePalette.textSecondary,
        //                   fontWeight: FontWeight.w500,
        //                   fontFamilyFallback: AppTheme.koreanFontFallback,
        //                 ),
        //               ),
        //             ],
        //           )
        //         : ReadonlyWithSuffix(
        //             value: _store?.royaltyRate ?? '-',
        //             suffix: '%',
        //           ),
        //   ),
        //   right: const SizedBox.shrink(),
        // ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            requiredField: true,
            label: '가맹계약 담당자',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _contManagerController,
                          hintText: '사원 검색',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () => _openUserLookup(
                          _contManagerController,
                          preferUserIdForSvField: false,
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        tooltip: '가맹계약 담당자 조회',
                        style: IconButton.styleFrom(
                          foregroundColor: FormStylePalette.accent,
                          side: const BorderSide(
                            color: FormStylePalette.accent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  )
                : ReadonlyValue(_managerReadonlyDash(_store, contract: true)),
          ),
          b: FormFieldBlock(
            label: '기본교육 담당자',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _eduManagerController,
                          hintText: '사원 검색',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () => _openUserLookup(
                          _eduManagerController,
                          preferUserIdForSvField: false,
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        tooltip: '기본교육 담당자 조회',
                        style: IconButton.styleFrom(
                          foregroundColor: FormStylePalette.accent,
                          side: const BorderSide(
                            color: FormStylePalette.accent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  )
                : ReadonlyValue(_managerReadonlyDash(_store, contract: false)),
          ),
          c: FormFieldBlock(
            requiredField: true,
            label: '담당 수퍼바이저',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _supervisorController,
                          hintText: '사원 검색',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () => _openUserLookup(
                          _supervisorController,
                          preferUserIdForSvField: true,
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        tooltip: '담당 수퍼바이저 조회',
                        style: IconButton.styleFrom(
                          foregroundColor: FormStylePalette.accent,
                          side: const BorderSide(
                            color: FormStylePalette.accent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  )
                : ReadonlyValue(
                    _store?.svNm.isNotEmpty == true
                        ? _store!.svNm
                        : (_store?.svId ?? '-'),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 문서 탭
// ---------------------------------------------------------------------------

class DocumentsTab extends ConsumerStatefulWidget {
  const DocumentsTab({super.key, this.store});

  final Store? store;

  @override
  ConsumerState<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = '전체';
  String _committedQuery = '';
  int? _selectedIndex;
  Document? _selectedRow;

  static const List<String> _typeOptions = ['전체', '이미지', '문서'];
  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
  };

  List<Document> get _allRows => widget.store == null
      ? const <Document>[]
      : ref.read(documentRepositoryProvider).docs(widget.store!);

  String _inferDocType(String fileName) {
    final lower = fileName.toLowerCase();
    for (final ext in _imageExtensions) {
      if (lower.endsWith(ext)) return '이미지';
    }
    return '문서';
  }

  List<Document> get _filteredRows {
    final query = _committedQuery.trim().toLowerCase();
    return _allRows.where((row) {
      if (_typeFilter != '전체' && _inferDocType(row.fileName) != _typeFilter) {
        return false;
      }
      if (query.isNotEmpty && !row.fileName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _applyFilter() {
    setState(() {
      _committedQuery = _searchController.text;
      _recomputeSelection();
    });
  }

  void _applyTypeFilter(String? value) {
    if (value == null) return;
    setState(() {
      _typeFilter = value;
      _recomputeSelection();
    });
  }

  void _recomputeSelection() {
    final rows = _filteredRows;
    if (_selectedRow == null) {
      _selectedIndex = null;
      return;
    }
    final idx = rows.indexWhere((r) => r.fileName == _selectedRow!.fileName);
    if (idx == -1) {
      _selectedIndex = null;
      _selectedRow = null;
    } else {
      _selectedIndex = idx;
    }
  }

  void _onRowTap(int i, List<Document> rows) {
    setState(() {
      if (_selectedIndex == i) {
        _selectedIndex = null;
        _selectedRow = null;
      } else {
        _selectedIndex = i;
        _selectedRow = rows[i];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  /// 선택된 문서가 없으면 가이드 스낵바, 있으면 실제 액션 스낵바.
  VoidCallback _guardedAction(Document? selected, String readyMessage) {
    return () =>
        selected == null ? _snack('문서를 먼저 선택해주세요.') : _snack(readyMessage);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    final selected = (_selectedIndex != null && _selectedIndex! < rows.length)
        ? rows[_selectedIndex!]
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentsTopBar(onUpload: () => _snack('문서 업로드는 추후 연결됩니다.')),
        const SizedBox(height: 12),
        DocumentsFilterRow(
          typeValue: _typeFilter,
          typeOptions: _typeOptions,
          onTypeChanged: _applyTypeFilter,
          searchController: _searchController,
          onSearch: _applyFilter,
        ),
        const SizedBox(height: 10),
        DocumentsSelectedRowBar(
          selectedFileName: selected?.fileName ?? '',
          onPreview: _guardedAction(selected, '미리보기는 추후 연결됩니다.'),
          onDownload: _guardedAction(selected, '다운로드는 추후 연결됩니다.'),
          onHistory: _guardedAction(selected, '문서 이력은 추후 연결됩니다.'),
        ),
        const SizedBox(height: 12),
        DocumentsTable(
          rows: rows,
          selectedIndex: _selectedIndex,
          onRowTap: (i) => _onRowTap(i, rows),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 히스토리 탭
// ---------------------------------------------------------------------------

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key, this.store});

  final Store? store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = store == null
        ? const AsyncValue<List<HistoryEntry>>.data(<HistoryEntry>[])
        : ref.watch(storeHistoriesProvider(store!.storeIdx));

    return entriesAsync.when(
      data: (entries) => _HistoryTable(entries: entries),
      loading: () => const CommonLoadingIndicator(),
      error: (error, stack) =>
          Center(child: Text('히스토리 조회 중 오류가 발생했습니다: $error')),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _AlwaysVisibleHorizontalScroll(
      minWidth: 900,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FormStylePalette.panelBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FormStylePalette.panelBorder),
        ),
        child: Column(
          children: [
            const _HistoryTableHeader(),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '표시할 히스토리가 없습니다.',
                  style: TextStyle(
                    color: FormStylePalette.textMuted,
                    fontSize: 13,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              )
            else
              for (final entry in entries) _HistoryTableRow(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _HistoryTableHeader extends StatelessWidget {
  const _HistoryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FormStylePalette.tableHeaderBg,
        border: Border(
          bottom: BorderSide(color: FormStylePalette.panelBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          _HistoryHeaderCell(label: '변경일'),
          _HistoryHeaderCell(label: '내용', flex: 3),
          _HistoryHeaderCell(label: '수정자'),
        ],
      ),
    );
  }
}

class _HistoryHeaderCell extends StatelessWidget {
  const _HistoryHeaderCell({required this.label, this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: FormStylePalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

class _HistoryTableRow extends StatelessWidget {
  const _HistoryTableRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FormStylePalette.rowDivider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          _HistoryValueCell(text: entry.chgDt),
          _HistoryValueCell(text: '${entry.content} 정보가 수정되었습니다.', flex: 3),
          _HistoryValueCell(text: entry.chgUserId),
        ],
      ),
    );
  }
}

class _HistoryValueCell extends StatelessWidget {
  const _HistoryValueCell({required this.text, this.flex = 1});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: FormStylePalette.textPrimary,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 상세 패널 (탭 뼈대)
// ---------------------------------------------------------------------------

/// 상세 화면의 모든 탭에서 공통 뼈대를 제공하는 패널.
///
/// - 상단: 탭 타이틀 + 수정/저장/취소 액션
/// - 중단: 공통 스토어 정보
/// - 하단: 탭별 컨텐츠 (title 기반 디스패치)
class StoreDetailPanel extends ConsumerStatefulWidget {
  const StoreDetailPanel({
    super.key,
    required this.title,
    this.store,
    this.isRegisterMode = false,
    this.registerDraft,
    this.onRegisterDraftChanged,
    this.sharedEditing,
    this.onEditModeChanged,
    this.onSharedCancelEditing,
  });

  final String title;
  final Store? store;
  final bool isRegisterMode;
  final StoreRegisterDraft? registerDraft;

  /// [registerDraft] 변경 시 부모가 [setState]로 모든 탭 패널을 갱신할 때 호출한다.
  final VoidCallback? onRegisterDraftChanged;
  final bool? sharedEditing;
  final ValueChanged<bool>? onEditModeChanged;

  /// 상세 수정 모드에서 어느 탭에서 취소를 눌러도 부모가 공통 초깃값(드래프트 재동기화·폼 재빌드)을 처리한다.
  final VoidCallback? onSharedCancelEditing;

  @override
  ConsumerState<StoreDetailPanel> createState() => _StoreDetailPanelState();
}

class _StoreDetailPanelState extends ConsumerState<StoreDetailPanel> {
  bool _isEditing = false;
  final _commonInfoKey = GlobalKey<_CommonStoreInfoSectionState>();
  final _basicInfoKey = GlobalKey<_BasicInfoTabState>();
  final _contractInfoKey = GlobalKey<_ContractInfoTabState>();
  late final TextEditingController _storeAreaCtrl;
  late final TextEditingController _contactCtrl;

  bool get _editing => widget.sharedEditing ?? _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isRegisterMode;
    _storeAreaCtrl =
        widget.registerDraft?.storeAreaController ??
        TextEditingController(text: _storeAreaFromStore());
    _contactCtrl =
        widget.registerDraft?.storeTelController ??
        TextEditingController(text: _contactFromStore());
  }

  @override
  void didUpdateWidget(covariant StoreDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRegisterMode != widget.isRegisterMode) {
      _isEditing = widget.isRegisterMode;
    }
    if (oldWidget.store != widget.store) {
      final d = widget.registerDraft;
      if (d != null && d.region.isNotEmpty) {
        _storeAreaCtrl.text = d.region;
      } else {
        _storeAreaCtrl.text = _storeAreaFromStore();
      }
      _contactCtrl.text = _contactFromStore();
    }
  }

  @override
  void dispose() {
    if (widget.registerDraft == null) {
      _storeAreaCtrl.dispose();
      _contactCtrl.dispose();
    }
    super.dispose();
  }

  String _storeAreaFromStore() => widget.store?.regionCd ?? '';

  String _contactFromStore() =>
      _formatPhoneNumber(widget.store?.storeTel ?? '');

  void _invalidateStoreProviders() {
    final storeIdx = widget.store?.storeIdx;
    if (storeIdx != null && storeIdx > 0) {
      ref.invalidate(storeDetailProvider(storeIdx));
      ref.invalidate(storeHistoriesProvider(storeIdx));
    }
    ref.invalidate(storeDataProvider);
  }

  void editStore() {
    _invalidateStoreProviders();
    widget.onEditModeChanged?.call(true);
    setState(() {
      _isEditing = true;
    });
  }

  void cancelStoreEdit() {
    if (widget.isRegisterMode) {
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.onSharedCancelEditing != null) {
      widget.onSharedCancelEditing!();
      return;
    }
    _invalidateStoreProviders();
    _commonInfoKey.currentState?._syncFromStore();
    widget.onEditModeChanged?.call(false);
    setState(() {
      _isEditing = false;
      _storeAreaCtrl.text = _storeAreaFromStore();
      _contactCtrl.text = _contactFromStore();
    });
    _snack('취소되었습니다.');
  }

  Future<void> saveStore() async {
    final store = widget.store;
    final commonInfo = _commonInfoKey.currentState;
    if (commonInfo == null) {
      setState(() => _isEditing = widget.isRegisterMode);
      _snack('저장할 가맹점 정보가 없습니다.');
      return;
    }

    if (widget.isRegisterMode) {
      await _createStore(commonInfo);
      return;
    }

    if (store == null) {
      setState(() => _isEditing = false);
      _snack('저장할 가맹점 정보가 없습니다.');
      return;
    }

    var payload = commonInfo.toUpdatePayload(
      store,
      storeTel: _contactCtrl.text.trim(),
    );
    final draft = widget.registerDraft;
    var mergedFullBasic = false;
    if (draft != null) {
      payload = payload
          .merge(_basicDraftPayload(draft))
          .merge(_contractDraftPayload(draft));
      mergedFullBasic = true;
    } else if (widget.title == '기본정보') {
      final basicInfo = _basicInfoKey.currentState;
      if (basicInfo == null) {
        _snack('기본정보 입력값을 확인할 수 없습니다.');
        return;
      }
      payload = payload.merge(basicInfo.toUpdatePayload());
      mergedFullBasic = true;
    } else if (widget.title == '계약정보') {
      final contractInfo = _contractInfoKey.currentState;
      if (contractInfo == null) {
        _snack('계약정보 입력값을 확인할 수 없습니다.');
        return;
      }
      payload = payload.merge(contractInfo.toUpdatePayload());
    }
    if (!mergedFullBasic) {
      final basicInfo = _basicInfoKey.currentState;
      if (basicInfo != null) {
        payload = payload.merge(basicInfo.toGeoUpdatePayload());
      }
    }

    final updated = await ref
        .read(storeApiServiceProvider)
        .updateStore(store.storeIdx, payload, onServerMessage: _snack);

    if (!mounted) return;
    if (updated == null) {
      return;
    }

    ref.invalidate(storeDataProvider);
    ref.invalidate(storeHistoriesProvider(store.storeIdx));
    final refreshed = await ref.refresh(
      storeDetailProvider(store.storeIdx).future,
    );
    if (!mounted) return;
    if (refreshed == null) {
      _snack('저장 후 최신 가맹점 정보를 다시 불러오지 못했습니다.');
      return;
    }
    draft?.hydrateFromStore(refreshed);
    widget.onEditModeChanged?.call(false);
    setState(() => _isEditing = false);
    await showAlertDialog(context, '저장되었습니다.');

    // 저장 후 데이터 새로고침
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createStore(_CommonStoreInfoSectionState commonInfo) async {
    var payload = commonInfo.toCreatePayload(storeTel: _contactCtrl.text);
    final draft = widget.registerDraft;
    var mergedFullBasic = false;
    if (draft != null) {
      payload = payload
          .merge(_basicDraftPayload(draft))
          .merge(_contractDraftPayload(draft));
      mergedFullBasic = true;
    } else if (widget.title == '기본정보') {
      final basicInfo = _basicInfoKey.currentState;
      if (basicInfo == null) {
        _snack('기본정보 입력값을 확인할 수 없습니다.');
        return;
      }
      payload = payload.merge(basicInfo.toUpdatePayload());
      mergedFullBasic = true;
    } else if (widget.title == '계약정보') {
      final contractInfo = _contractInfoKey.currentState;
      if (contractInfo == null) {
        _snack('계약정보 입력값을 확인할 수 없습니다.');
        return;
      }
      payload = payload.merge(contractInfo.toUpdatePayload());
    }
    if (!mergedFullBasic) {
      final basicInfo = _basicInfoKey.currentState;
      if (basicInfo != null) {
        payload = payload.merge(basicInfo.toGeoUpdatePayload());
      }
    }

    if (payload.isStoreNmBlank) {
      _snack('가맹점명은 필수입니다.');
      return;
    }

    final created = await ref
        .read(storeApiServiceProvider)
        .createStore(payload, onServerMessage: _snack);
    if (!mounted) return;
    if (created == null) {
      return;
    }

    ref.invalidate(storeDataProvider);
    await showAlertDialog(context, '저장되었습니다.');
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  StoreMstWritePayload _basicDraftPayload(StoreRegisterDraft draft) {
    return StoreMstWritePayload.fromMap({
      StoreMstWritePayload.jsonKeyFirstContDt: _dateToYmd(draft.firstContDt),
      StoreMstWritePayload.jsonKeyContEndDt: _dateToYmd(
        draft.contractExpiryDate,
      ),
      StoreMstWritePayload.jsonKeyOwnerNm: draft.ownerNameController.text
          .trim(),
      StoreMstWritePayload.jsonKeyZipCd: _emptyToNull(
        draft.zipCodeController.text,
      ),
      StoreMstWritePayload.jsonKeyAddress: _emptyToNull(
        draft.addressController.text,
      ),
      StoreMstWritePayload.jsonKeyAdressDetail: _emptyToNull(
        draft.addressDetailController.text,
      ),
      StoreMstWritePayload.jsonKeyLatitude: _optionalCoordPayload(
        draft.latitude,
      ),
      StoreMstWritePayload.jsonKeyLongitude: _optionalCoordPayload(
        draft.longitude,
      ),
      StoreMstWritePayload.jsonKeyContArea: _numberToNull(
        draft.contAreaController.text,
      ),
      StoreMstWritePayload.jsonKeyRealArea: _numberToNull(
        draft.realAreaController.text,
      ),
      StoreMstWritePayload.jsonKeyFloor: _intToNull(draft.floorController.text),
      StoreMstWritePayload.jsonKeyParkingCount: _intToNull(
        draft.parkingController.text,
      ),
      StoreMstWritePayload.jsonKeyRentDeposit: _intToNull(
        draft.rentDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyPremiumFee: _intToNull(
        draft.premiumFeeController.text,
      ),
      StoreMstWritePayload.jsonKeyMonthlyRent: _intToNull(
        draft.monthlyRentController.text,
      ),
      StoreMstWritePayload.jsonKeyNotes: draft.notesController.text.trim(),
    });
  }

  StoreMstWritePayload _contractDraftPayload(StoreRegisterDraft draft) {
    return StoreMstWritePayload.fromMap({
      StoreMstWritePayload.jsonKeyFirstContDt:
          _dateToYmd(draft.contractFirstContDt) ??
          _dateToYmd(draft.firstContDt),
      StoreMstWritePayload.jsonKeyContStartDt: _dateToYmd(
        draft.currentContractStart,
      ),
      StoreMstWritePayload.jsonKeyContEndDt:
          _dateToYmd(draft.currentContractEnd) ??
          _dateToYmd(draft.contractExpiryDate),
      StoreMstWritePayload.jsonKeyFrFee: _numberToNull(
        draft.frFeeController.text,
      ),
      StoreMstWritePayload.jsonKeyEduFee: _numberToNull(
        draft.eduFeeController.text,
      ),
      StoreMstWritePayload.jsonKeyInsuDeposit: _numberToNull(
        draft.insuDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyContDeposit: _numberToNull(
        draft.contDepositController.text,
      ),
      StoreMstWritePayload.jsonKeyContManager: _emptyToNull(
        draft.contManagerController.text,
      ),
      StoreMstWritePayload.jsonKeyEduManager: _emptyToNull(
        draft.eduManagerController.text,
      ),
      StoreMstWritePayload.jsonKeySvId: _emptyToNull(
        draft.supervisorController.text,
      ),
    });
  }

  String? _dateToYmd(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  num? _numberToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return num.tryParse(normalized);
  }

  /// 위도·경도: 미설정이면 null을 두어 백엔드가 필드를 무시하고 기존 DB 값을 유지한다.
  num? _optionalCoordPayload(String? value) {
    final normalized = value?.replaceAll(',', '').trim() ?? '';
    if (normalized.isEmpty || normalized == '-') return null;
    return num.tryParse(normalized);
  }

  int? _intToNull(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty || normalized == '-') return 0;
    return int.tryParse(normalized);
  }

  void _snack(String message) {
    if (!mounted) return;
    showAlertDialog(context, message);
  }

  Widget _buildTabContent() {
    switch (widget.title) {
      case '기본정보':
        return BasicInfoTab(
          key: _basicInfoKey,
          store: widget.store,
          panelEditing: _editing,
          storeTelController: _contactCtrl,
          registerDraft: widget.registerDraft,
          onPropertySelected: (property) =>
              _commonInfoKey.currentState?.applyPropertySelection(property),
        );
      case '계약정보':
        return ContractInfoTab(
          key: _contractInfoKey,
          store: widget.store,
          panelEditing: _editing,
          registerDraft: widget.registerDraft,
        );
      case '문서정보':
        return DocumentsTab(store: widget.store);
      case '히스토리':
        return HistoryTab(store: widget.store);
      default:
        return PlaceholderTabContent(title: widget.title);
    }
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
                      title: widget.title,
                      isEditing: _editing,
                      onEnterEdit: editStore,
                      onSave: saveStore,
                      onCancel: cancelStoreEdit,
                    ),
                    const SizedBox(height: 14),
                    CommonStoreInfoSection(
                      key: _commonInfoKey,
                      store: widget.store,
                      isEditing: _editing,
                      storeAreaController: _storeAreaCtrl,
                      registerDraft: widget.registerDraft,
                      onRegisterDraftChanged: widget.onRegisterDraftChanged,
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      color: FormStylePalette.panelBorder,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    _buildTabContent(),
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
