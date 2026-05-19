import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/menu/menu_access.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_alert_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_erp_dialog.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_register_button.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/checklist/chk_mst_write_request.dart';
import 'package:app_flutter/pages/master/mst004/mst004_api.dart';
import 'package:app_flutter/pages/master/mst004/mst004_model.dart';

class MasterChecklistManagementView extends StatefulWidget {
  const MasterChecklistManagementView({super.key});

  @override
  State<MasterChecklistManagementView> createState() =>
      _MasterChecklistManagementViewState();
}

class _MasterChecklistManagementViewState
    extends State<MasterChecklistManagementView> {
  late Future<List<MasterChecklistItem>> _rowsFuture;
  List<CodeOption> _brandOptions = const [];
  List<CodeOption> _checklistTypeOptions = const [];
  String _brandCd = '';
  String _chkType = '';

  @override
  void initState() {
    super.initState();
    _rowsFuture = _fetchRows();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final codeApi = CommonCodeApiService();
    final results = await Future.wait([
      codeApi.getCodes(40),
      codeApi.getCodes(50),
    ]);
    if (!mounted) return;
    setState(() {
      _brandOptions = results[0];
      _checklistTypeOptions = results[1];
    });
  }

  Future<List<MasterChecklistItem>> _fetchRows() {
    return MasterChecklistApiService().getChecklists(
      brandCd: _brandCd.isEmpty ? null : _brandCd,
      chkType: _chkType.isEmpty ? null : _chkType,
    );
  }

  void _refresh() {
    setState(() {
      _rowsFuture = _fetchRows();
    });
  }

  void _setBrand(String value) {
    setState(() {
      _brandCd = value;
      _rowsFuture = _fetchRows();
    });
  }

  void _setChecklistType(String value) {
    setState(() {
      _chkType = value;
      _rowsFuture = _fetchRows();
    });
  }

  Future<void> _openCreateDialog() async {
    final saved = await showMasterChecklistDialog(
      context,
      brandOptions: _brandOptions,
      checklistTypeOptions: _checklistTypeOptions,
      initialBrandCd: _brandCd,
      initialChkType: _chkType,
    );
    if (!mounted || saved != true) return;
    await showAlertDialog(context, '등록되었습니다.');
    if (!mounted) return;
    _refresh();
  }

  Future<void> _openEditDialog(MasterChecklistItem item) async {
    final saved = await showMasterChecklistDialog(
      context,
      brandOptions: _brandOptions,
      checklistTypeOptions: _checklistTypeOptions,
      initialBrandCd: _brandCd,
      initialChkType: _chkType,
      item: item,
    );
    if (!mounted || saved != true) return;
    await showAlertDialog(context, '수정되었습니다.');
    if (!mounted) return;
    _refresh();
  }

  List<ActiveFilterChip> _activeFilters() {
    final chips = <ActiveFilterChip>[];
    if (_brandCd.isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '브랜드: ${_codeName(_brandOptions, _brandCd)}',
          onClear: () => _setBrand(''),
        ),
      );
    }
    if (_chkType.isNotEmpty) {
      chips.add(
        ActiveFilterChip(
          label: '구분: ${_codeName(_checklistTypeOptions, _chkType)}',
          onClear: () => _setChecklistType(''),
        ),
      );
    }
    return chips;
  }

  List<SearchFilterItemData> _filterItems() {
    return [
      FilterDropdownSlot<String>(
        label: '브랜드',
        value: _brandCd,
        items: _codeDropdownItems(_brandOptions),
        onChanged: (value) => _setBrand(value ?? ''),
      ).toItem(),
      FilterDropdownSlot<String>(
        label: '구분',
        value: _chkType,
        items: _codeDropdownItems(_checklistTypeOptions),
        onChanged: (value) => _setChecklistType(value ?? ''),
      ).toItem(),
    ];
  }

  List<DropdownMenuItem<String?>> _codeDropdownItems(List<CodeOption> options) {
    return [
      const DropdownMenuItem<String?>(
        value: '',
        child: Text('전체', style: kSearchFilterValueTextStyle),
      ),
      for (final option in options)
        DropdownMenuItem<String?>(
          value: option.codeCd,
          child: Text(option.codeNm, style: kSearchFilterValueTextStyle),
        ),
    ];
  }

  String _codeName(List<CodeOption> options, String code) {
    for (final option in options) {
      if (option.codeCd == code) return option.codeNm;
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final filterItems = _filterItems();
    return FutureBuilder<List<MasterChecklistItem>>(
      future: _rowsFuture,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <MasterChecklistItem>[];
        final totalScore = rows.fold<int>(0, (sum, row) => sum + row.baseScore);
        return _ChecklistListShell(
          activeFilters: _activeFilters(),
          filterFields: SearchFilterStackedItems(items: filterItems),
          countText: '총 ${rows.length}건 · 총 배점 $totalScore점',
          onRefresh: _refresh,
          onRegister: _openCreateDialog,
          table: _ChecklistTable(
            rows: rows,
            loading: snapshot.connectionState != ConnectionState.done,
            onEdit: _openEditDialog,
          ),
        );
      },
    );
  }
}

class _ChecklistListShell extends StatelessWidget {
  const _ChecklistListShell({
    required this.activeFilters,
    required this.filterFields,
    required this.countText,
    required this.table,
    required this.onRefresh,
    required this.onRegister,
  });

  final List<ActiveFilterChip> activeFilters;
  final Widget filterFields;
  final String countText;
  final Widget table;
  final VoidCallback onRefresh;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.appSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.listScreenHPadding,
          0,
          AppDimensions.listScreenHPadding,
          AppDimensions.listScreenBottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.contentMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: const Color(0xFFE2E5EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.listCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ActiveFilterChipsBar(chips: activeFilters),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('새로고침'),
                          style: FilledButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            backgroundColor: const Color(0xFFD1FAE5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFA7F3D0)),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.1,
                              fontFamilyFallback: AppTheme.koreanFontFallback,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (context.menuCanCreate(kMenuMst004))
                          RegisterButton(onPressed: onRegister),
                      ],
                    ),
                    const SizedBox(height: 12),
                    filterFields,
                    const SizedBox(height: 8),
                    Text(
                      countText,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(child: table),
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

class _ChecklistTable extends StatelessWidget {
  const _ChecklistTable({
    required this.rows,
    required this.loading,
    required this.onEdit,
  });

  final List<MasterChecklistItem> rows;
  final bool loading;
  final ValueChanged<MasterChecklistItem> onEdit;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return const Center(child: Text('조회된 체크리스트 항목이 없습니다.'));
    }
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthCompact,
      tableBuilder: (context, width) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(0.6),
          3: FlexColumnWidth(0.5),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppTheme.accentRed),
            children: [
              ErpTableHeaderCell('구분'),
              ErpTableHeaderCell('체크항목'),
              ErpTableHeaderCell('사용여부'),
              ErpTableHeaderCell('배점'),
            ],
          ),
          for (final row in rows)
            TableRow(
              decoration: const BoxDecoration(color: AppTheme.tableRowOdd),
              children: [
                _DoubleTapCell(
                  onDoubleTap: () => onEdit(row),
                  child: ErpTableBodyCell(_text(row.chkTypeNm), center: true),
                ),
                _DoubleTapCell(
                  onDoubleTap: () => onEdit(row),
                  child: ErpTableBodyCell(_text(row.chkContent)),
                ),
                _DoubleTapCell(
                  onDoubleTap: () => onEdit(row),
                  child: ErpTableBodyCell(
                    _requiredText(row.useYn),
                    center: true,
                  ),
                ),
                _DoubleTapCell(
                  onDoubleTap: () => onEdit(row),
                  child: ErpTableBodyCell(
                    row.baseScore.toString(),
                    center: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _text(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _requiredText(String value) {
    return value.trim().toUpperCase() == 'Y' ? 'Y' : 'N';
  }
}

class _DoubleTapCell extends StatelessWidget {
  const _DoubleTapCell({required this.child, required this.onDoubleTap});

  final Widget child;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: child,
    );
  }
}

Future<bool?> showMasterChecklistDialog(
  BuildContext context, {
  required List<CodeOption> brandOptions,
  required List<CodeOption> checklistTypeOptions,
  String initialBrandCd = '',
  String initialChkType = '',
  MasterChecklistItem? item,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (dialogContext) {
      final compact = useCompactErpLayout(dialogContext);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(compact ? 12 : 20),
        child: _ChecklistCreateDialog(
        brandOptions: brandOptions,
        checklistTypeOptions: checklistTypeOptions,
        initialBrandCd: initialBrandCd,
        initialChkType: initialChkType,
        item: item,
        ),
      );
    },
  );
}

class _ChecklistCreateDialog extends StatefulWidget {
  const _ChecklistCreateDialog({
    required this.brandOptions,
    required this.checklistTypeOptions,
    required this.initialBrandCd,
    required this.initialChkType,
    this.item,
  });

  final List<CodeOption> brandOptions;
  final List<CodeOption> checklistTypeOptions;
  final String initialBrandCd;
  final String initialChkType;
  final MasterChecklistItem? item;

  @override
  State<_ChecklistCreateDialog> createState() => _ChecklistCreateDialogState();
}

class _ChecklistCreateDialogState extends State<_ChecklistCreateDialog> {
  final _contentCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController(text: '0');
  String _brandCd = '';
  String _chkType = '';
  bool _required = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _brandCd = _initialCode(
      widget.brandOptions,
      item?.brandCd ?? widget.initialBrandCd,
    );
    _chkType = _initialCode(
      widget.checklistTypeOptions,
      item?.chkType ?? widget.initialChkType,
    );
    if (item != null) {
      _contentCtrl.text = item.chkContent;
      _scoreCtrl.text = item.baseScore.toString();
      _required = item.useYn.trim().toUpperCase() == 'Y';
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  String _initialCode(List<CodeOption> options, String preferred) {
    if (preferred.isNotEmpty && options.any((e) => e.codeCd == preferred)) {
      return preferred;
    }
    return options.isEmpty ? '' : options.first.codeCd;
  }

  void _reset() {
    final item = widget.item;
    setState(() {
      _brandCd = _initialCode(
        widget.brandOptions,
        item?.brandCd ?? widget.initialBrandCd,
      );
      _chkType = _initialCode(
        widget.checklistTypeOptions,
        item?.chkType ?? widget.initialChkType,
      );
      _contentCtrl.text = item?.chkContent ?? '';
      _scoreCtrl.text = item?.baseScore.toString() ?? '0';
      _required = item?.useYn.trim().toUpperCase() == 'Y';
    });
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (_brandCd.isEmpty || _chkType.isEmpty || content.isEmpty) {
      _snack('브랜드, 구분, 체크항목을 입력해 주세요.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final body = ChkMstWriteRequest.fromMap({
      ChkMstWriteRequest.jsonKeyBrandCd: _brandCd,
      ChkMstWriteRequest.jsonKeyChkType: _chkType,
      ChkMstWriteRequest.jsonKeyChkContent: content,
      ChkMstWriteRequest.jsonKeyBaseScore:
          int.tryParse(_scoreCtrl.text.trim()) ?? 0,
      ChkMstWriteRequest.jsonKeyUseYn: _required ? 'Y' : 'N',
    });
    final api = MasterChecklistApiService();
    final item = widget.item;
    final saved = item == null
        ? await api.createChecklist(body)
        : await api.updateChecklist(item.chkIdx, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _snack(item == null ? '등록에 실패했습니다.' : '수정에 실패했습니다.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _snack(String message) {
    showAlertDialog(context, message);
  }

  InputDecoration _inputDeco({String? hint}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: FormStylePalette.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
      ),
    );
  }

  Widget _brandField() {
    return _DialogField(
      label: '브랜드',
      requiredMark: true,
      child: _DialogDropdown(
        value: _brandCd,
        options: widget.brandOptions,
        decoration: _inputDeco(),
        onChanged: (value) {
          if (value != null) setState(() => _brandCd = value);
        },
      ),
    );
  }

  Widget _typeField() {
    return _DialogField(
      label: '구분',
      requiredMark: true,
      child: _DialogDropdown(
        value: _chkType,
        options: widget.checklistTypeOptions,
        decoration: _inputDeco(),
        onChanged: (value) {
          if (value != null) setState(() => _chkType = value);
        },
      ),
    );
  }

  Widget _scoreField() {
    return _DialogField(
      label: '배점',
      child: TextField(
        controller: _scoreCtrl,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: kSearchFilterValueTextStyle,
        decoration: _inputDeco(),
      ),
    );
  }

  Widget _useYnField() {
    return _DialogField(
      label: '사용여부',
      requiredMark: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Checkbox(
          value: _required,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.compact,
          onChanged: (value) {
            setState(() {
              _required = value ?? false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = useCompactErpLayout(context);
    return ErpDialogFrame(
      title: widget.item == null ? '체크리스트 등록' : '체크리스트 수정',
      maxWidth: compact ? double.infinity : 620,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        14,
        compact ? 14 : 18,
        compact ? 14 : 18,
      ),
      onClose: _saving ? null : () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            _brandField(),
            const SizedBox(height: 12),
            _typeField(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _brandField()),
                const SizedBox(width: 14),
                Expanded(child: _typeField()),
              ],
            ),
          const SizedBox(height: 12),
          if (compact) ...[
            _scoreField(),
            const SizedBox(height: 12),
            _useYnField(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 160, child: _scoreField()),
                const SizedBox(width: 24),
                Expanded(child: _useYnField()),
              ],
            ),
          const SizedBox(height: 12),
          _DialogField(
            label: '체크항목',
            requiredMark: true,
            child: TextField(
              controller: _contentCtrl,
              enabled: !_saving,
              maxLines: 5,
              style: kSearchFilterValueTextStyle,
              decoration: _inputDeco(hint: '체크항목 내용을 입력하세요.'),
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_saving ? '저장 중...' : '저장'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('초기화'),
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: _saving ? null : _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('초기화'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
                  child: Text(_saving ? '저장 중...' : '저장'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.child,
    this.requiredMark = false,
  });

  final String label;
  final Widget child;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text.rich(
              TextSpan(
                children: [
                  if (requiredMark)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: AppTheme.accentRed),
                    ),
                  TextSpan(text: label),
                ],
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FormStylePalette.textPrimary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _DialogDropdown extends StatelessWidget {
  const _DialogDropdown({
    required this.value,
    required this.options,
    required this.decoration,
    required this.onChanged,
  });

  final String value;
  final List<CodeOption> options;
  final InputDecoration decoration;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = options.map((e) => e.codeCd).toSet();
    final resolved = values.contains(value)
        ? value
        : (options.isEmpty ? '' : options.first.codeCd);
    return DropdownButtonFormField<String>(
      initialValue: resolved.isEmpty ? null : resolved,
      isExpanded: true,
      isDense: true,
      style: kSearchFilterValueTextStyle,
      decoration: decoration,
      borderRadius: BorderRadius.circular(8),
      itemHeight: kMinInteractiveDimension,
      items: [
        for (final option in options)
          DropdownMenuItem<String>(
            value: option.codeCd,
            child: Text(option.codeNm, style: kSearchFilterValueTextStyle),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }
}
