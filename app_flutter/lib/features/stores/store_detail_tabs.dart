// 가맹점 상세 화면의 탭·공통 영역·문서 UI·패널을 한 파일로 묶음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/data/mock_options.dart';
import 'package:app_flutter/core/data/mock_data_hub.dart';
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
// 계약 상태 라벨
// ---------------------------------------------------------------------------

/// 계약 상태 → 한글 라벨 변환 헬퍼.
class StoreStatusLabel {
  StoreStatusLabel._();

  static String of(StoreStatus? status) {
    return switch (status) {
      StoreStatus.newContract => '신규계약',
      StoreStatus.renewal => '재계약',
      StoreStatus.transfer => '양수도',
      null => '-',
    };
  }
}

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
      borderSide: const BorderSide(
        color: FormStylePalette.accent,
        width: 1.4,
      ),
    ),
  );
}

/// 모든 상세 탭 상단에 공통으로 노출되는 기본 스토어 정보 영역.
///
/// **그룹·지역**은 드롭다운이며, 수정 모드일 때만 선택 가능하다.
/// [storeAreaController]에는 선택한 지역 문자열이 반영된다(API 연동 전).
class CommonStoreInfoSection extends StatefulWidget {
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
  State<CommonStoreInfoSection> createState() => _CommonStoreInfoSectionState();
}

class _CommonStoreInfoSectionState extends State<CommonStoreInfoSection> {
  static final List<String> _groupOptions =
      kMockStoreCategoryOptions.where((e) => e != '전체').toList();

  late String _group;
  late String _region;

  List<String> get _regionOptions {
    final base = kMockRegionOptions.where((e) => e != '전체').toList();
    if (_region.isNotEmpty &&
        _region != '-' &&
        !base.contains(_region)) {
      return [_region, ...base];
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    _syncFromStore();
  }

  @override
  void didUpdateWidget(covariant CommonStoreInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.storeCode != widget.store?.storeCode ||
        oldWidget.isEditing != widget.isEditing) {
      _syncFromStore();
    }
  }

  void _syncFromStore() {
    _group = _groupOptions.first;
    final area = widget.store?.storeArea ?? '';
    final opts = kMockRegionOptions.where((e) => e != '전체').toList();
    if (area.isEmpty || area == '-') {
      _region = opts.isNotEmpty ? opts.first : '서울';
    } else if (opts.contains(area)) {
      _region = area;
    } else {
      _region = area;
    }
    widget.storeAreaController.text = _region;
  }

  void _setGroup(String value) {
    setState(() => _group = value);
  }

  void _setRegion(String value) {
    setState(() {
      _region = value;
      widget.storeAreaController.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final canEdit = widget.isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormRowTwo(
          left: FormFieldBlock(
            label: '가맹점코드',
            child: ReadonlyValue(store?.storeCode ?? '-'),
          ),
          right: FormFieldBlock(
            label: '사업자번호',
            child: ReadonlyValue(store?.businessNumber ?? '-'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '브랜드',
            child: ReadonlyValue(store?.brand ?? '-'),
          ),
          right: FormFieldBlock(
            label: '가맹점명',
            child: ReadonlyValue(store?.storeName ?? '-'),
          ),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '계약상태',
            child: ReadonlyValue(StoreStatusLabel.of(store?.contractStatus)),
          ),
          b: FormFieldBlock(
            label: '그룹',
            child: DropdownButtonFormField<String>(
              key: ValueKey('group-${store?.storeCode}-$_group'),
              initialValue: _groupOptions.contains(_group)
                  ? _group
                  : _groupOptions.first,
              isExpanded: true,
              isDense: true,
              style: FormStylePalette.valueStyle,
              decoration: _commonStoreDropdownDecoration(),
              items: [
                for (final g in _groupOptions)
                  DropdownMenuItem<String>(
                    value: g,
                    child: Text(
                      g,
                      style: FormStylePalette.valueStyle,
                    ),
                  ),
              ],
              onChanged: canEdit
                  ? (v) {
                      if (v != null) _setGroup(v);
                    }
                  : null,
            ),
          ),
          c: FormFieldBlock(
            label: '지역',
            child: DropdownButtonFormField<String>(
              key: ValueKey('region-${store?.storeCode}-$_region'),
              initialValue: _regionOptions.contains(_region)
                  ? _region
                  : _regionOptions.first,
              isExpanded: true,
              isDense: true,
              style: FormStylePalette.valueStyle,
              decoration: _commonStoreDropdownDecoration(),
              items: [
                for (final r in _regionOptions)
                  DropdownMenuItem<String>(
                    value: r,
                    child: Text(
                      r,
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
                textAlign: columns[i].alignStart ? TextAlign.left : TextAlign.center,
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
  late DateTime? _openingDate;
  late DateTime? _contractExpiryDate;
  late DateTime? _leaseStartDate;
  late DateTime? _leaseEndDate;

  Store? get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _syncDates();
  }

  @override
  void didUpdateWidget(covariant BasicInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.storeCode != widget.store?.storeCode) {
      setState(_syncDates);
    }
  }

  void _syncDates() {
    _openingDate = tryParseLooseDate(widget.store?.openingDate);
    _contractExpiryDate = tryParseLooseDate(widget.store?.contractDate);
    if (widget.store != null) {
      _leaseStartDate = DateTime(2023, 1, 1);
      _leaseEndDate = DateTime(2028, 12, 31);
    } else {
      _leaseStartDate = null;
      _leaseEndDate = null;
    }
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
            label: '개업일자',
            child: DateInputWithPicker(
              value: _openingDate,
              onPick: () => _pickDate(
                current: _openingDate,
                onPicked: (d) => _openingDate = d,
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
                child: ReadonlyInputShell(
                  child: Text(
                    _store?.storeName ?? '-',
                    style: FormStylePalette.valueStyle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    _snack('물건 상세정보 조회는 추후 연결됩니다.'),
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
                    child: ReadonlyInputShell(
                      child: Text(
                        _store == null ? '-' : '12345',
                        style: FormStylePalette.valueStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AccentOutlinedButton(
                    label: '지도보기/영업지역',
                    onPressed: () =>
                        _snack('지도보기는 추후 연결됩니다.'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ReadonlyInputShell(
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
                : ReadonlyValue(_store?.contact ?? '-'),
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
            child: UnitPairRow(
              primary: detailMockIfLoaded(
                _store,
                kMockStoreBasicContractAreaSqm,
              ),
              primarySuffix: '㎡',
              secondary: '40.1',
              secondarySuffix: '평',
            ),
          ),
          right: FormFieldBlock(
            label: '면적(실㎡)',
            child: UnitPairRow(
              primary: detailMockIfLoaded(_store, kMockStoreBasicActualAreaSqm),
              primarySuffix: '㎡',
              secondary: '38.7',
              secondarySuffix: '평',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '층수',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreBasicFloorLabel),
              suffix: '층',
            ),
          ),
          right: FormFieldBlock(
            label: '주차가능대수',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreBasicParkingCount),
              suffix: '대',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '입대차 보증금',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreBasicLeaseDeposit),
              suffix: '원',
            ),
          ),
          b: FormFieldBlock(
            label: '권리금',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreBasicKeyMoney),
              suffix: '원',
            ),
          ),
          c: FormFieldBlock(
            label: '임차료',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreBasicMonthlyRent),
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
  const ContractInfoTab({super.key, this.store});

  final Store? store;

  @override
  State<ContractInfoTab> createState() => _ContractInfoTabState();
}

class _ContractInfoTabState extends State<ContractInfoTab> {
  late DateTime? _firstContractDate;
  late DateTime? _currentContractStart;
  late DateTime? _currentContractEnd;

  Store? get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _syncDates();
  }

  @override
  void didUpdateWidget(covariant ContractInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.storeCode != widget.store?.storeCode) {
      setState(_syncDates);
    }
  }

  void _syncDates() {
    if (widget.store == null) {
      _firstContractDate = null;
      _currentContractStart = null;
      _currentContractEnd = null;
      return;
    }
    _firstContractDate = DateTime(2020, 5, 15);
    _currentContractStart =
        tryParseLooseDate(widget.store?.openingDate) ?? DateTime(2023, 5, 15);
    _currentContractEnd =
        tryParseLooseDate(widget.store?.contractDate) ?? DateTime(2028, 5, 14);
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
              value: _firstContractDate,
              onPick: () => _pickDate(
                current: _firstContractDate,
                onPicked: (d) => _firstContractDate = d,
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
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreContractFranchiseFee),
              suffix: '원',
            ),
          ),
          right: FormFieldBlock(
            label: '교육비',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreContractEducationFee),
              suffix: '원',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '보증보험금',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(
                _store,
                kMockStoreContractGuaranteeInsurance,
              ),
              suffix: '원',
            ),
          ),
          right: FormFieldBlock(
            label: '계약보증금',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreContractDeposit),
              suffix: '원',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormRowTwo(
          left: FormFieldBlock(
            label: '로열티',
            child: ReadonlyWithSuffix(
              value: detailMockIfLoaded(_store, kMockStoreContractRoyaltyRate),
              suffix: '%',
            ),
          ),
          right: const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        FormRowThree(
          a: FormFieldBlock(
            label: '가맹계약 담당자',
            child: ReadonlyValue(
              detailMockIfLoaded(_store, kMockStoreContractManagerName),
            ),
          ),
          b: FormFieldBlock(
            label: '기본교육 담당자',
            child: ReadonlyValue(
              detailMockIfLoaded(
                _store,
                kMockStoreContractEducationManagerName,
              ),
            ),
          ),
          c: FormFieldBlock(
            label: '담당 수퍼바이저',
            child: ReadonlyValue(
              detailMockIfLoaded(_store, kMockStoreContractSupervisorName),
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

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, this.store});

  final Store? store;

  @override
  Widget build(BuildContext context) {
    final entries = store == null
        ? const <HistoryEntry>[]
        : kMockHistoryEntries;
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
          _HistoryHeaderCell(label: '등록일'),
          _HistoryHeaderCell(label: '내용', flex: 2),
          _HistoryHeaderCell(label: '등록일'),
          _HistoryHeaderCell(label: '내용', flex: 2),
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
          _HistoryValueCell(text: entry.registeredAt),
          _HistoryValueCell(text: entry.content, flex: 2),
          const _HistoryValueCell(text: ''),
          const _HistoryValueCell(text: '', flex: 2),
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
class StoreDetailPanel extends StatefulWidget {
  const StoreDetailPanel({super.key, required this.title, this.store});

  final String title;
  final Store? store;

  @override
  State<StoreDetailPanel> createState() => _StoreDetailPanelState();
}

class _StoreDetailPanelState extends State<StoreDetailPanel> {
  bool _isEditing = false;
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
    if (!_isEditing && oldWidget.store?.storeCode != widget.store?.storeCode) {
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

  String _storeAreaFromStore() => widget.store?.storeArea ?? '';

  String _contactFromStore() => widget.store?.contact ?? '';

  void editStore() {
    setState(() {
      _isEditing = true;
      _storeAreaCtrl.text = _storeAreaFromStore();
      _contactCtrl.text = _contactFromStore();
    });
  }

  void cancelStoreEdit() {
    setState(() {
      _isEditing = false;
      _storeAreaCtrl.text = _storeAreaFromStore();
      _contactCtrl.text = _contactFromStore();
    });
    _snack('취소되었습니다.');
  }

  void saveStore() {
    setState(() => _isEditing = false);
    _snack('저장되었습니다. (API 연동 예정)');
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
        return ContractInfoTab(store: widget.store);
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
