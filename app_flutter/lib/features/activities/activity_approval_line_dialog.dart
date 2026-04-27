// 결재라인 선택 — 등록·상신 화면용 모달(조직도·사원 그리드·선택 띠, [FormStylePalette] / [ErpDataTable] 톤).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';

/// 격자형 직급/결재 열 수(기안·스크린샷 기준 7).
const int kActivityApprovalLineSlotCount = 7;

class ActivityApprovalLineResult {
  const ActivityApprovalLineResult({required this.titles, required this.names});

  final List<String> titles;
  final List<String> names;
}

/// [결재라인] — 직급+이름 슬롯을 채운다.
Future<ActivityApprovalLineResult?> showActivityApprovalLineDialog(
  BuildContext context, {
  List<String> initialNames = const [],
  List<String> initialTitles = const [],
}) {
  return showDialog<ActivityApprovalLineResult?>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: _ApprovalLineDialog(
          initialNames: _padToSlots(initialNames),
          initialTitles: _padToSlots(initialTitles),
        ),
      );
    },
  );
}

List<String> _padToSlots(List<String> items) {
  return List<String>.generate(
    kActivityApprovalLineSlotCount,
    (i) => i < items.length ? items[i] : '',
  );
}

class _EmployeeRow {
  const _EmployeeRow({
    required this.id,
    required this.department,
    required this.title,
    required this.name,
  });

  final String id;
  final String department;
  final String title;
  final String name;
}

const _kDepartments = <String>[];

final _kAllEmployees = <_EmployeeRow>[];

String _titleForName(String name) {
  for (final e in _kAllEmployees) {
    if (e.name == name) return e.title;
  }
  return '';
}

class _ApprovalLineDialog extends StatefulWidget {
  const _ApprovalLineDialog({
    required this.initialNames,
    required this.initialTitles,
  });

  final List<String> initialNames;
  final List<String> initialTitles;

  @override
  State<_ApprovalLineDialog> createState() => _ApprovalLineDialogState();
}

class _ApprovalLineDialogState extends State<_ApprovalLineDialog> {
  final TextEditingController _lineName = TextEditingController();
  String? _selectedDept;
  final Set<String> _rowChecked = {};
  late List<String> _lineNames;
  late List<String> _lineTitles;

  @override
  void initState() {
    super.initState();
    _lineNames = List<String>.from(widget.initialNames);
    _lineTitles = List<String>.from(widget.initialTitles);
    for (var i = 0; i < kActivityApprovalLineSlotCount; i++) {
      if (_lineNames[i].isNotEmpty && _lineTitles[i].isEmpty) {
        _lineTitles[i] = _titleForName(_lineNames[i]);
      }
    }
    _selectedDept = '경영지원본부';
  }

  @override
  void dispose() {
    _lineName.dispose();
    super.dispose();
  }

  List<_EmployeeRow> get _visibleEmployees {
    var list = _kAllEmployees;
    final q = _lineName.text.trim();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.name.contains(q) ||
                e.department.contains(q) ||
                e.title.contains(q),
          )
          .toList();
    }
    final d = _selectedDept;
    if (d == null) return list;
    if (d == '역전F&C' || d == '경영지원본부') {
      return list;
    }
    return list.where((e) => e.department == d).toList();
  }

  void _onAddApprovers() {
    final ids = _rowChecked.toList()..sort();
    final toAdd = <_EmployeeRow>[];
    for (final id in ids) {
      final m = _kAllEmployees.firstWhere(
        (e) => e.id == id,
        orElse: () => _kAllEmployees.first,
      );
      if (m.id == id) toAdd.add(m);
    }
    setState(() {
      for (final m in toAdd) {
        if (_lineNames.contains(m.name)) continue;
        final i = _lineNames.indexWhere((e) => e.isEmpty);
        if (i >= 0) {
          _lineNames[i] = m.name;
          _lineTitles[i] = m.title;
        }
      }
      _rowChecked.clear();
    });
  }

  void _onReset() {
    setState(() {
      _lineNames = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _lineTitles = List<String>.filled(kActivityApprovalLineSlotCount, '');
      _rowChecked.clear();
    });
  }

  void _onApply() {
    Navigator.of(context).pop(
      ActivityApprovalLineResult(
        names: _padToSlots(_lineNames),
        titles: _padToSlots(_lineTitles),
      ),
    );
  }

  InputDecoration _searchDeco() {
    return InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.86;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1000,
        maxHeight: h.clamp(420.0, 760.0),
      ),
      child: Material(
        color: FormStylePalette.panelBg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
              child: Row(
                children: [
                  const Text(
                    '결재라인 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: FormStylePalette.textPrimary,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: FormStylePalette.inputBg,
                      foregroundColor: FormStylePalette.textSecondary,
                    ),
                    icon: const Icon(Icons.close, size: 24),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: FormStylePalette.panelBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text(
                      '결재라인명',
                      style: TextStyle(
                        fontSize: kSearchFilterFontSize,
                        fontWeight: FontWeight.w600,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _lineName,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: kSearchFilterFontSize,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                      decoration: _searchDeco().copyWith(
                        hintText: '검색',
                        hintStyle: const TextStyle(
                          fontSize: kSearchFilterFontSize,
                          color: FormStylePalette.textMuted,
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: FormStylePalette.textSecondary,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OrgTreePanel(
                        selectedDept: _selectedDept,
                        onSelect: (d) {
                          setState(() => _selectedDept = d);
                        },
                        departments: _kDepartments,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _EmployeeTablePanel(
                        employees: _visibleEmployees,
                        checked: _rowChecked,
                        onToggle: (id, v) {
                          setState(() {
                            if (v) {
                              _rowChecked.add(id);
                            } else {
                              _rowChecked.remove(id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton(
                onPressed: _onAddApprovers,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('결재자 추가'),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SelectedStrip(
                lineNames: _lineNames,
                lineTitles: _lineTitles,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('결재라인 설정'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _onReset,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('결재라인 초기화'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgTreePanel extends StatelessWidget {
  const _OrgTreePanel({
    required this.selectedDept,
    required this.onSelect,
    required this.departments,
  });

  final String? selectedDept;
  final void Function(String?) onSelect;
  final List<String> departments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.inputBg,
        border: Border.all(color: FormStylePalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Text(
              '조직도',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FormStylePalette.textPrimary,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const Divider(height: 1, color: FormStylePalette.panelBorder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              children: [
                _TreeTile(
                  label: '역전F&C',
                  isSelected: selectedDept == '역전F&C',
                  onTap: () => onSelect('역전F&C'),
                  children: [
                    _TreeTile(
                      label: '경영지원본부',
                      isSelected: selectedDept == '경영지원본부',
                      onTap: () => onSelect('경영지원본부'),
                      depth: 1,
                      children: [
                        for (final d in departments)
                          _TreeTile(
                            label: d,
                            isSelected: selectedDept == d,
                            onTap: () => onSelect(d),
                            depth: 2,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeTile extends StatefulWidget {
  const _TreeTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.children = const [],
    this.depth = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Widget> children;
  final int depth;

  @override
  State<_TreeTile> createState() => _TreeTileState();
}

class _TreeTileState extends State<_TreeTile> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;
    const padL = 8.0;
    final left = widget.depth * 12.0 + padL;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasChildren) setState(() => _open = !_open);
              widget.onTap();
            },
            child: Container(
              padding: EdgeInsets.only(left: left, right: 8, top: 6, bottom: 6),
              color: widget.isSelected
                  ? const Color(0xFFFFE4E4)
                  : Colors.transparent,
              child: Row(
                children: [
                  if (hasChildren) ...[
                    Icon(
                      _open ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                      color: FormStylePalette.textSecondary,
                    ),
                    const SizedBox(width: 2),
                  ] else
                    const SizedBox(width: 22),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: FormStylePalette.textPrimary,
                        fontFamilyFallback: AppTheme.koreanFontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && _open) ...widget.children,
      ],
    );
  }
}

class _EmployeeTablePanel extends StatelessWidget {
  const _EmployeeTablePanel({
    required this.employees,
    required this.checked,
    required this.onToggle,
  });

  final List<_EmployeeRow> employees;
  final Set<String> checked;
  final void Function(String id, bool isChecked) onToggle;

  @override
  Widget build(BuildContext context) {
    // [ErpDataTable] 기본 1300px minWidth 는 다이얼로그 2분할 본문보다 커서
    // 가로 스크롤이 생기고 첫 열만 보이는 것처럼 보인다(직급·사원명이 화면 밖).
    // 모달용으로 좁은 최소 폭을 쓰면 사용 가능한 너비에 4열이 맞게 분배된다.
    return ErpDataTable(
      minWidth: 480,
      tableBuilder: (context, width) {
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: kErpTableInnerGridBorder,
          // 부서명은 flex 비율을 낮춰 열을 좁히고, 직급·사원명에 가로를 맞긴다.
          columnWidths: {
            0: const FixedColumnWidth(48),
            1: const FlexColumnWidth(1.05),
            2: const FlexColumnWidth(0.78),
            3: const FlexColumnWidth(1.05),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppTheme.accentRed),
              children: [
                ErpTableHeaderCell(' '),
                ErpTableHeaderCell('부서명'),
                ErpTableHeaderCell('직급(직책)'),
                ErpTableHeaderCell('사원명'),
              ],
            ),
            for (var i = 0; i < employees.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i.isEven
                      ? AppTheme.tableRowOdd
                      : AppTheme.tableRowEven,
                ),
                children: [
                  _CheckboxTableCell(
                    isChecked: checked.contains(employees[i].id),
                    onChanged: (v) => onToggle(employees[i].id, v ?? false),
                  ),
                  ErpTableBodyCell(employees[i].department),
                  ErpTableBodyCell(employees[i].title, center: true),
                  ErpTableBodyCell(employees[i].name, center: true),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CheckboxTableCell extends StatelessWidget {
  const _CheckboxTableCell({required this.isChecked, required this.onChanged});

  final bool isChecked;
  final void Function(bool? v) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: SizedBox(
          width: 40,
          height: kMinInteractiveDimension,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: AppTheme.accentRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

class _SelectedStrip extends StatelessWidget {
  const _SelectedStrip({required this.lineNames, required this.lineTitles});

  final List<String> lineNames;
  final List<String> lineTitles;

  @override
  Widget build(BuildContext context) {
    final cells = <({String t, String n})>[];
    for (var i = 0; i < kActivityApprovalLineSlotCount; i++) {
      final n = i < lineNames.length ? lineNames[i] : '';
      if (n.isEmpty) continue;
      final t = i < lineTitles.length ? lineTitles[i] : '';
      cells.add((t: t, n: n));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FormStylePalette.inputBg,
        border: Border.all(color: FormStylePalette.panelBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FormStylePalette.panelBg,
                          border: Border.all(
                            color: FormStylePalette.panelBorder,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cells[i].t.isNotEmpty
                              ? '${cells[i].t} / ${cells[i].n}'
                              : cells[i].n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FormStylePalette.textPrimary,
                            fontFamilyFallback: AppTheme.koreanFontFallback,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
