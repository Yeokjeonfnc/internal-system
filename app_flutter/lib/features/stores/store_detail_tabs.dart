// 가맹점 상세 화면의 탭·공통 영역·문서 UI·패널을 한 파일로 묶음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/formatting/display_date.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_detail_action_buttons.dart';
import 'package:app_flutter/core/widgets/common/form/common_accent_outline_button.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_field_block.dart';
import 'package:app_flutter/core/widgets/common/form/common_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_labeled_form_row.dart';
import 'package:app_flutter/core/widgets/common/form/common_readonly_field.dart';
import 'package:app_flutter/features/stores/store_controller.dart';
import 'package:app_flutter/features/stores/store_model.dart';

// ---------------------------------------------------------------------------
// 상세 패널 편집 모드 공통 입력칸 (지역·연락처 등)
// ---------------------------------------------------------------------------

Widget _storeDetailOutlineTextField(
  TextEditingController controller, {
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
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

Widget _storeDetailOutlineTextFieldWithSuffix(
  TextEditingController controller, {
  required String suffix,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: _storeDetailOutlineTextField(
          controller,
          keyboardType: keyboardType,
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
  });

  final Store? store;
  final bool isEditing;
  final TextEditingController storeAreaController;

  @override
  ConsumerState<CommonStoreInfoSection> createState() =>
      _CommonStoreInfoSectionState();
}

class _CommonStoreInfoSectionState
    extends ConsumerState<CommonStoreInfoSection> {
  late final TextEditingController _storeCodeController;
  late final TextEditingController _businessNumberController;
  late final TextEditingController _storeNameController;
  late String _type;
  late String _region;
  late String _brand;
  late String _status;

  @override
  void initState() {
    super.initState();
    _storeCodeController = TextEditingController();
    _businessNumberController = TextEditingController();
    _storeNameController = TextEditingController();
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
    _storeCodeController.dispose();
    _businessNumberController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  void _syncFromStore() {
    _storeCodeController.text = widget.store?.storeCd ?? '';
    _businessNumberController.text = widget.store?.businessNumber ?? '';
    _storeNameController.text = widget.store?.storeNm ?? '';
    _brand = widget.store?.brandCd ?? '';
    _status = widget.store?.storeStatus ?? '';
    _type = widget.store?.storeType ?? '';
    _region = widget.store?.regionCd ?? '';
    widget.storeAreaController.text = _region;
  }

  List<CodeOption> _optionsWithCurrentCode(
    List<CodeOption> base,
    String currentCode,
    String currentName,
  ) {
    if (currentCode.isNotEmpty &&
        currentCode != '-' &&
        !base.any((e) => e.codeCd == currentCode)) {
      return [
        CodeOption(
          codeCd: currentCode,
          codeNm: currentName.isNotEmpty ? currentName : currentCode,
        ),
        ...base,
      ];
    }
    return base;
  }

  String _selectedCode(String current, List<CodeOption> options) {
    if (options.any((e) => e.codeCd == current)) {
      return current;
    }
    return options.isNotEmpty ? options.first.codeCd : '';
  }

  String _storeTypeFallbackName(String code) {
    return switch (code) {
      'FR' => '가맹',
      'DI' => '직영',
      _ => code,
    };
  }

  void _setType(String value) {
    setState(() => _type = value);
  }

  void _setRegion(String value) {
    setState(() {
      _region = value;
      widget.storeAreaController.text = value;
    });
  }

  void _setBrand(String value) {
    setState(() => _brand = value);
  }

  void _setStatus(String value) {
    setState(() => _status = value);
  }

  Map<String, dynamic> toUpdatePayload(
    Store store, {
    required String storeTel,
  }) {
    return {
      'storeCd': store.storeCd,
      'storeNm': _storeNameController.text.trim(),
      'ownerNm': store.ownerNm,
      'regionCd': _region,
      'storeTel': storeTel,
      'address': store.address,
      'storeStatus': _status,
      'contEndDt': _emptyToNull(store.contEndDt),
      'autoRenewalYn': true,
      'storeType': _type,
      'svId': store.svId,
      'adressDetail': store.addressDetail,
      'zipCd': store.zipCd,
      'brandCd': _brand,
      'contStartDt': _emptyToNull(store.contStartDt),
      'firstContDt': _emptyToNull(store.firstContDt),
      'businessNumber': _businessNumberController.text.trim(),
      'frFee': _numberToNull(store.frFee),
      'eduFee': _numberToNull(store.eduFee),
      'insuDeposit': _numberToNull(store.insuDeposit),
      'contDeposit': _numberToNull(store.contDeposit),
      'contManager': store.contManager,
      'eduManager': store.eduManager,
      'contArea': _numberToNull(store.contArea),
      'realArea': _numberToNull(store.realArea),
      'floor': store.floor,
      'parkingCount': store.parkingCount,
      'premiumFee': store.premiumFee,
      'monthlyRent': store.monthlyRent,
      'rentDeposit': store.rentDeposit,
    };
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
      _brand,
      store?.brandNm ?? '',
    );
    final statusOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(10)).value ?? const <CodeOption>[],
      _status,
      store?.storeStatusNm ?? '',
    );
    final regionOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(20)).value ?? const <CodeOption>[],
      _region,
      store?.regionNm ?? '',
    );
    final typeOptions = _optionsWithCurrentCode(
      ref.watch(codeOptionsProvider(30)).value ?? const <CodeOption>[],
      _type,
      (store?.storeTypeNm ?? '').isNotEmpty
          ? store!.storeTypeNm
          : _storeTypeFallbackName(_type),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        FormRowTwo(
          left: FormFieldBlock(
            label: '브랜드',
            child: canEdit
                ? brandOptions.isEmpty
                      ? ReadonlyValue(store?.brandNm ?? store?.brandCd ?? '-')
                      : DropdownButtonFormField<String>(
                          key: ValueKey('brand-${store?.storeCd}-$_brand'),
                          initialValue: _selectedCode(_brand, brandOptions),
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
            label: '가맹점명',
            child: canEdit
                ? _storeDetailOutlineTextField(_storeNameController)
                : ReadonlyValue(store?.storeNm ?? '-'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '계약상태',
            child: canEdit
                ? statusOptions.isEmpty
                      ? ReadonlyValue(store?.storeStatusNm ?? '-')
                      : DropdownButtonFormField<String>(
                          key: ValueKey('status-${store?.storeCd}-$_status'),
                          initialValue: _selectedCode(_status, statusOptions),
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
            child: typeOptions.isEmpty
                ? ReadonlyValue(
                    (store?.storeTypeNm ?? '').isNotEmpty
                        ? store!.storeTypeNm
                        : _storeTypeFallbackName(store?.storeType ?? '-'),
                  )
                : DropdownButtonFormField<String>(
                    key: ValueKey('type-${store?.storeCd}-$_type'),
                    initialValue: _selectedCode(_type, typeOptions),
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
                    key: ValueKey('region-${store?.storeCd}-$_region'),
                    initialValue: _selectedCode(_region, regionOptions),
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
    return DecoratedBox(
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
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DateInputWithPicker(value: start, onPick: onPickStart),
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
          child: DateInputWithPicker(value: end, onPick: onPickEnd),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 기본정보 탭
// ---------------------------------------------------------------------------

class BasicInfoTab extends StatefulWidget {
  const BasicInfoTab({
    super.key,
    this.store,
    required this.panelEditing,
    required this.contactController,
  });

  final Store? store;

  /// [StoreDetailPanel] 헤더의 수정 모드와 동기화된다.
  final bool panelEditing;
  final TextEditingController contactController;

  @override
  State<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<BasicInfoTab> {
  late DateTime? _firstContDt;
  late DateTime? _contractExpiryDate;
  late DateTime? _leaseStartDate;
  late DateTime? _leaseEndDate;
  late TextEditingController _floorController;
  late TextEditingController _parkingController;
  late TextEditingController _contArea;
  late TextEditingController _realAreaController;
  late TextEditingController _storeNameController;
  late TextEditingController _zipCodeController;
  late TextEditingController _addressController;
  late TextEditingController _rentDepositController;
  late TextEditingController _premiumFeeController;
  late TextEditingController _monthlyRentController;

  Store? get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _floorController = TextEditingController();
    _parkingController = TextEditingController();
    _contArea = TextEditingController(text: _store?.contArea ?? '');
    _realAreaController = TextEditingController(text: _store?.realArea ?? '');
    _storeNameController = TextEditingController(text: _store?.storeNm ?? '');
    _zipCodeController = TextEditingController(text: _store?.zipCd ?? '12345');
    _addressController = TextEditingController(text: _store?.address ?? '');
    _rentDepositController = TextEditingController(
      text: _store?.rentDeposit.toString() ?? '',
    );
    _premiumFeeController = TextEditingController(
      text: _store?.insuDeposit ?? '',
    );
    _monthlyRentController = TextEditingController(
      text: _store?.monthlyRent.toString() ?? '',
    );
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
      _zipCodeController.text = _store?.zipCd ?? '12345';
      _addressController.text = _store?.address ?? '';
      _rentDepositController.text = _store?.rentDeposit.toString() ?? '';
      _premiumFeeController.text = _store?.premiumFee.toString() ?? '';
      _monthlyRentController.text = _store?.monthlyRent.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _floorController.dispose();
    _parkingController.dispose();
    _contArea.dispose();
    _realAreaController.dispose();
    _storeNameController.dispose();
    _zipCodeController.dispose();
    _addressController.dispose();
    _rentDepositController.dispose();
    _premiumFeeController.dispose();
    _monthlyRentController.dispose();
    super.dispose();
  }

  void _syncDates() {
    _firstContDt = tryParseLooseDate(widget.store?.firstContDt);
    _contractExpiryDate = tryParseLooseDate(widget.store?.contEndDt);
    if (widget.store != null) {
      _leaseStartDate = DateTime(2023, 1, 1);
      _leaseEndDate = DateTime(2028, 12, 31);
    } else {
      _leaseStartDate = null;
      _leaseEndDate = null;
    }
  }

  String _sqmToPyeong(String? rawSqm) {
    final normalized = rawSqm?.replaceAll(',', '').trim();
    final sqm = double.tryParse(normalized ?? '');
    if (sqm == null) return '-';
    return (sqm / 3.305785).toStringAsFixed(1);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              onPick: () => _pickDate(
                current: _firstContDt,
                onPicked: (d) => _firstContDt = d,
              ),
            ),
          ),
          right: FormFieldBlock(
            label: '계약 만료일자',
            child: DateInputWithPicker(
              value: _contractExpiryDate,
              onPick: () => _pickDate(
                current: _contractExpiryDate,
                onPicked: (d) => _contractExpiryDate = d,
              ),
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
                onPressed: () => _snack('물건 상세정보 조회는 추후 연결됩니다.'),
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '연락처',
            child: widget.panelEditing
                ? _storeDetailOutlineTextField(
                    widget.contactController,
                    keyboardType: TextInputType.phone,
                  )
                : ReadonlyValue(_store?.storeTel ?? '-'),
          ),
          right: FormFieldBlock(
            label: '임대차 기간',
            child: _StoreDateRangeRow(
              start: _leaseStartDate,
              end: _leaseEndDate,
              onPickStart: () => _pickDate(
                current: _leaseStartDate,
                onPicked: (d) => _leaseStartDate = d,
              ),
              onPickEnd: () => _pickDate(
                current: _leaseEndDate,
                onPicked: (d) => _leaseEndDate = d,
              ),
            ),
          ),
        ),
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
            label: '입대차 보증금',
            child: widget.panelEditing
                ? _storeDetailOutlineTextFieldWithSuffix(
                    _rentDepositController,
                    suffix: '원',
                    keyboardType: TextInputType.number,
                  )
                : ReadonlyWithSuffix(
                    value: _store?.rentDeposit.toString() ?? '-',
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
                  )
                : ReadonlyWithSuffix(
                    value: _store?.premiumFee.toString() ?? '-',
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
                  )
                : ReadonlyWithSuffix(
                    value: _store?.monthlyRent.toString() ?? '-',
                    suffix: '원',
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 계약정보 탭
// ---------------------------------------------------------------------------

class ContractInfoTab extends StatefulWidget {
  const ContractInfoTab({super.key, this.store, required this.panelEditing});

  final Store? store;
  final bool panelEditing;

  @override
  State<ContractInfoTab> createState() => _ContractInfoTabState();
}

class _ContractInfoTabState extends State<ContractInfoTab> {
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

  Map<String, dynamic> toUpdatePayload() {
    return {
      'firstContDt': _dateToYmd(_firstContDt),
      'contStartDt': _dateToYmd(_currentContractStart),
      'contEndDt': _dateToYmd(_currentContractEnd),
      'frFee': _numberToNull(_frFreeController.text),
      'eduFee': _numberToNull(_eduFeeController.text),
      'insuDeposit': _numberToNull(_insuDepositController.text),
      'contDeposit': _numberToNull(_contDepositController.text),
      'contManager': _contManagerController.text.trim(),
      'eduManager': _eduManagerController.text.trim(),
      'svId': _supervisorController.text.trim(),
    };
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

  @override
  void initState() {
    super.initState();
    _frFreeController = TextEditingController(
      text: _store?.frFee != null ? _store!.frFee : '0',
    );
    _eduFeeController = TextEditingController(
      text: _store?.eduFee != null ? _store!.eduFee : '0',
    );
    _insuDepositController = TextEditingController(
      text: _store?.insuDeposit != null ? _store!.insuDeposit : '0',
    );
    _contDepositController = TextEditingController(
      text: _store?.contDeposit != null ? _store!.contDeposit : '0',
    );
    _contManagerController = TextEditingController(
      text: _store?.contManager != null ? _store!.contManager : '',
    );
    _eduManagerController = TextEditingController(
      text: _store?.eduManager != null ? _store!.eduManager : '',
    );
    _supervisorController = TextEditingController(
      text: _store?.svId != null ? _store!.svId : '',
    );
    _syncDates();
  }

  @override
  void didUpdateWidget(covariant ContractInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        (!oldWidget.panelEditing && widget.panelEditing)) {
      setState(_syncDates);
      _frFreeController.text = _store?.frFee ?? '';
      _eduFeeController.text = _store?.eduFee ?? '';
      _insuDepositController.text = _store?.insuDeposit ?? '';
      _contDepositController.text = _store?.contDeposit ?? '';
      _contManagerController.text = _store?.contManager ?? '';
      _eduManagerController.text = _store?.eduManager ?? '';
      _supervisorController.text = _store?.svId ?? '';
    }
  }

  @override
  void dispose() {
    _frFreeController.dispose();
    _eduFeeController.dispose();
    _insuDepositController.dispose();
    _contDepositController.dispose();
    // _royaltyRateController.dispose();
    _contManagerController.dispose();
    _eduManagerController.dispose();
    _supervisorController.dispose();
    super.dispose();
  }

  void _syncDates() {
    _firstContDt = tryParseLooseDate(widget.store?.firstContDt);
    _currentContractStart = tryParseLooseDate(widget.store?.contStartDt);
    _currentContractEnd = tryParseLooseDate(widget.store?.contEndDt);
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
              onPick: () => _pickDate(
                current: _firstContDt,
                onPicked: (d) => _firstContDt = d,
              ),
            ),
          ),
          right: FormFieldBlock(
            label: '현재 가맹계약 기간',
            child: _StoreDateRangeRow(
              start: _currentContractStart,
              end: _currentContractEnd,
              onPickStart: () => _pickDate(
                current: _currentContractStart,
                onPicked: (d) => _currentContractStart = d,
              ),
              onPickEnd: () => _pickDate(
                current: _currentContractEnd,
                onPicked: (d) => _currentContractEnd = d,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '가맹비',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _frFreeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '원',
                        style: TextStyle(
                          fontSize: 14,
                          color: FormStylePalette.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ],
                  )
                : ReadonlyWithSuffix(value: _store?.frFee ?? '-', suffix: '원'),
          ),
          right: FormFieldBlock(
            label: '교육비',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _eduFeeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '원',
                        style: TextStyle(
                          fontSize: 14,
                          color: FormStylePalette.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamilyFallback: AppTheme.koreanFontFallback,
                        ),
                      ),
                    ],
                  )
                : ReadonlyWithSuffix(value: _store?.eduFee ?? '-', suffix: '원'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '보증보험금',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _insuDepositController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '원',
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
                    value: _store?.insuDeposit ?? '-',
                    suffix: '원',
                  ),
          ),
          right: FormFieldBlock(
            label: '계약보증금',
            child: widget.panelEditing
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _storeDetailOutlineTextField(
                          _contDepositController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '원',
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
                    value: _store?.contDeposit ?? '-',
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
            label: '가맹계약 담당자',
            child: widget.panelEditing
                ? _storeDetailOutlineTextField(_contManagerController)
                : ReadonlyValue(_store?.contManager ?? '-'),
          ),
          b: FormFieldBlock(
            label: '기본교육 담당자',
            child: widget.panelEditing
                ? _storeDetailOutlineTextField(_eduManagerController)
                : ReadonlyValue(_store?.eduManager ?? '-'),
          ),
          c: FormFieldBlock(
            label: '담당 수퍼바이저',
            child: widget.panelEditing
                ? _storeDetailOutlineTextField(_supervisorController)
                : ReadonlyValue(_store?.svId ?? '-'),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
    return DecoratedBox(
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
          _HistoryValueCell(text: entry.content, flex: 3),
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
  const StoreDetailPanel({super.key, required this.title, this.store});

  final String title;
  final Store? store;

  @override
  ConsumerState<StoreDetailPanel> createState() => _StoreDetailPanelState();
}

class _StoreDetailPanelState extends ConsumerState<StoreDetailPanel> {
  bool _isEditing = false;
  final _commonInfoKey = GlobalKey<_CommonStoreInfoSectionState>();
  final _contractInfoKey = GlobalKey<_ContractInfoTabState>();
  late final TextEditingController _storeAreaCtrl;
  late final TextEditingController _contactCtrl;

  @override
  void initState() {
    super.initState();
    _storeAreaCtrl = TextEditingController(text: _storeAreaFromStore());
    _contactCtrl = TextEditingController(text: _contactFromStore());
  }

  @override
  void didUpdateWidget(covariant StoreDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _storeAreaCtrl.text = _storeAreaFromStore();
      _contactCtrl.text = _contactFromStore();
    }
  }

  @override
  void dispose() {
    _storeAreaCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  String _storeAreaFromStore() => widget.store?.regionCd ?? '';

  String _contactFromStore() => widget.store?.storeTel ?? '';

  void _invalidateStoreProviders() {
    final storeCd = widget.store?.storeCd;
    final storeIdx = widget.store?.storeIdx;
    if (storeCd != null && storeCd.isNotEmpty) {
      ref.invalidate(storeDetailProvider(storeCd));
    }
    if (storeIdx != null && storeIdx > 0) {
      ref.invalidate(storeHistoriesProvider(storeIdx));
    }
    ref.invalidate(storeDataProvider);
  }

  void editStore() {
    _invalidateStoreProviders();
    setState(() {
      _isEditing = true;
      _storeAreaCtrl.text = _storeAreaFromStore();
      _contactCtrl.text = _contactFromStore();
    });
  }

  void cancelStoreEdit() {
    _invalidateStoreProviders();
    _commonInfoKey.currentState?._syncFromStore();
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
    if (store == null || commonInfo == null) {
      setState(() => _isEditing = false);
      _snack('저장할 가맹점 정보가 없습니다.');
      return;
    }

    final payload = commonInfo.toUpdatePayload(
      store,
      storeTel: _contactCtrl.text.trim(),
    );
    if (widget.title == '계약정보') {
      final contractInfo = _contractInfoKey.currentState;
      if (contractInfo == null) {
        _snack('계약정보 입력값을 확인할 수 없습니다.');
        return;
      }
      payload.addAll(contractInfo.toUpdatePayload());
    }

    final updated = await ref
        .read(storeApiServiceProvider)
        .updateStore(store.storeCd, payload);

    if (!mounted) return;
    if (updated == null) {
      _snack('저장에 실패했습니다.');
      return;
    }

    ref.invalidate(storeDataProvider);
    ref.invalidate(storeHistoriesProvider(store.storeIdx));
    final refreshed = await ref.refresh(
      storeDetailProvider(store.storeCd).future,
    );
    if (!mounted) return;
    if (refreshed == null) {
      _snack('저장 후 최신 가맹점 정보를 다시 불러오지 못했습니다.');
      return;
    }
    setState(() => _isEditing = false);
    _snack('저장되었습니다.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTabContent() {
    switch (widget.title) {
      case '기본정보':
        return BasicInfoTab(
          store: widget.store,
          panelEditing: _isEditing,
          contactController: _contactCtrl,
        );
      case '계약정보':
        return ContractInfoTab(
          key: _contractInfoKey,
          store: widget.store,
          panelEditing: _isEditing,
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
                      isEditing: _isEditing,
                      onEnterEdit: editStore,
                      onSave: saveStore,
                      onCancel: cancelStoreEdit,
                    ),
                    const SizedBox(height: 14),
                    CommonStoreInfoSection(
                      key: _commonInfoKey,
                      store: widget.store,
                      isEditing: _isEditing,
                      storeAreaController: _storeAreaCtrl,
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
