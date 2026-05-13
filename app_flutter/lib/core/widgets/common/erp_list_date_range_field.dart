// 목록·필터용 구간 날짜(프리셋 + 시작/끝) — 활동·영업지역 등 공통.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/date/erp_list_date_presets.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart'
    show showAccentDatePicker;

/// 본문 검색 — 활동일자·설정일자 등 구간 + 프리셋.
class ErpListDateRangeField extends StatefulWidget {
  const ErpListDateRangeField({
    super.key,
    this.initialPresetLabel,
    required this.start,
    required this.end,
    required this.onRangeChanged,
  });

  /// null이면 `'최근1개월'` — 화면별 기본 프리셋과 맞출 때 사용(예: 영업지역 `'전체'`).
  final String? initialPresetLabel;

  final DateTime start;
  final DateTime end;
  final void Function(DateTime start, DateTime end) onRangeChanged;

  @override
  State<ErpListDateRangeField> createState() => _ErpListDateRangeFieldState();
}

class _ErpListDateRangeFieldState extends State<ErpListDateRangeField> {
  static const _opts = [
    '최근1개월',
    '최근2개월',
    '최근3개월',
    '최근6개월',
    '최근1년',
    '전체',
    '직접 설정',
  ];

  static const _dateFieldWidth = 120.0;

  late String _preset;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPresetLabel;
    _preset = (seed != null && _opts.contains(seed)) ? seed : '최근1개월';
  }

  Future<void> _pickStart() async {
    final d = await showAccentDatePicker(
      context: context,
      initialDate: widget.start,
    );
    if (!mounted || d == null) return;
    var s = DateTime(d.year, d.month, d.day);
    var e = DateTime(widget.end.year, widget.end.month, widget.end.day);
    if (e.isBefore(s)) e = s;
    setState(() => _preset = '직접 설정');
    widget.onRangeChanged(s, e);
  }

  Future<void> _pickEnd() async {
    final d = await showAccentDatePicker(
      context: context,
      initialDate: widget.end,
    );
    if (!mounted || d == null) return;
    var e = DateTime(d.year, d.month, d.day);
    var s = DateTime(widget.start.year, widget.start.month, widget.start.day);
    if (e.isBefore(s)) e = s;
    setState(() => _preset = '직접 설정');
    widget.onRangeChanged(s, e);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SearchFilterDropdownField<String>(
              compact: true,
              fieldLabel: '활동일자_프리셋',
              value: _opts.contains(_preset) ? _preset : '직접 설정',
              items: [
                for (final o in _opts)
                  DropdownMenuItem<String?>(
                    value: o,
                    child: Text(o, style: kSearchFilterValueTextStyle),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                if (v == '직접 설정') {
                  setState(() => _preset = v);
                  return;
                }
                setState(() => _preset = v);
                final p = erpPresetDateRange(v);
                widget.onRangeChanged(p.$1, p.$2);
              },
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: _dateFieldWidth,
              child: ErpListCompactDateButton(
                date: widget.start,
                onPressed: _pickStart,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Text('—', style: kSearchFilterValueTextStyle),
            ),
            SizedBox(
              width: _dateFieldWidth,
              child: ErpListCompactDateButton(
                date: widget.end,
                onPressed: _pickEnd,
              ),
            ),
          ],
        );
        if (c.maxWidth < 420) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 400),
              child: row,
            ),
          );
        }
        return row;
      },
    );
  }
}

class ErpListCompactDateButton extends StatelessWidget {
  const ErpListCompactDateButton({
    super.key,
    required this.date,
    required this.onPressed,
  });

  final DateTime date;
  final VoidCallback onPressed;

  static String _ymd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32, maxHeight: 34),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _ymd(date),
                    style: kSearchFilterValueTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
