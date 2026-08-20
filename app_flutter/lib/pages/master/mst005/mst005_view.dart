import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/usage_log/usage_log_api.dart';
import 'package:app_flutter/core/widgets/common/common_active_filter_chips.dart';
import 'package:app_flutter/core/widgets/common/common_list_page_template.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/common_status_badge.dart';
import 'package:app_flutter/core/widgets/common/data_table/common_erp_data_table.dart'
    show
        ErpDataTable,
        erpTableColumnWidths,
        kErpTableInnerGridBorder,
        kErpTableHeaderRowDecoration;
import 'package:app_flutter/core/widgets/common/data_table/common_erp_table_cells.dart';
import 'package:app_flutter/core/widgets/common/form/common_date_input_with_picker.dart'
    show showAccentDatePicker;

const _kTabs = ['전체내역', '사용자로그인', '공용사용자'];
const _kTabApiValues = ['ALL', 'LOGIN', 'PUBLIC'];
const _kUseTypeOptions = ['전체', '메뉴사용', '로그인'];
const _kUseTypeApiValues = ['', 'MENU', 'LOGIN'];
const _kDatePresets = ['오늘', '최근1개월', '최근3개월', '직접 설정'];

/// 서버 `UsageLogMapper.selectList` 의 `LIMIT` 과 같은 값.
///
/// 사용기록은 감사 자료라 "총 N건"이 실제 총계인지 잘린 값인지 반드시 구분돼야 한다.
/// 응답에 '더 있음' 표시가 없으므로 받은 건수가 상한과 같으면 잘린 것으로 본다.
/// (서버 LIMIT 을 바꾸면 이 값도 같이 바꿀 것)
const int _kServerRowLimit = 2000;

class UsageLogInquiryView extends StatefulWidget {
  const UsageLogInquiryView({super.key});

  @override
  State<UsageLogInquiryView> createState() => _UsageLogInquiryViewState();
}

class _UsageLogInquiryViewState extends State<UsageLogInquiryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _userNmCtrl = TextEditingController();
  final _api = UsageLogApiService();

  String _useTypeLabel = '전체';
  String _datePreset = '오늘';
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late Future<List<UsageLogRow>> _rowsFuture;
  int _reloadEpoch = 0;

  /// Web IME 조합 중 텍스트 초기화 시 발생하는 TextInput range assertion 방지.
  void _setUserNameSafely(String text) {
    if (_userNmCtrl.text == text) return;
    _userNmCtrl.value = _userNmCtrl.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    final today = _today();
    _rangeStart = today;
    _rangeEnd = today;
    _rowsFuture = _fetchRows();
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _reload();
  }

  String get _tabParam => _kTabApiValues[_tabController.index.clamp(0, 2)];

  String? get _useTypeParam {
    final idx = _kUseTypeOptions.indexOf(_useTypeLabel);
    if (idx < 0) return null;
    final v = _kUseTypeApiValues[idx];
    return v.isEmpty ? null : v;
  }

  Future<List<UsageLogRow>> _fetchRows() async {
    final _ = _reloadEpoch;
    return _api.fetchList(
      userNm: _userNmCtrl.text.trim(),
      useType: _useTypeParam,
      tab: _tabParam,
      startDt: _rangeStart,
      endDt: _rangeEnd,
    );
  }

  void _reload() {
    setState(() {
      _reloadEpoch++;
      _rowsFuture = _fetchRows();
    });
  }

  void _applyDatePreset(String preset) {
    final today = _today();
    setState(() {
      _datePreset = preset;
      switch (preset) {
        case '오늘':
          _rangeStart = today;
          _rangeEnd = today;
        case '최근1개월':
          _rangeStart = today.subtract(const Duration(days: 30));
          _rangeEnd = today;
        case '최근3개월':
          _rangeStart = today.subtract(const Duration(days: 90));
          _rangeEnd = today;
        default:
          break;
      }
    });
    _reload();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _rangeStart : _rangeEnd;
    final d = await showAccentDatePicker(context: context, initialDate: initial);
    if (!mounted || d == null) return;
    final picked = DateTime(d.year, d.month, d.day);
    setState(() {
      _datePreset = '직접 설정';
      if (isStart) {
        _rangeStart = picked;
        if (_rangeEnd.isBefore(_rangeStart)) _rangeEnd = _rangeStart;
      } else {
        _rangeEnd = picked;
        if (_rangeEnd.isBefore(_rangeStart)) _rangeStart = _rangeEnd;
      }
    });
    _reload();
  }

  List<ActiveFilterChip> _activeChips() {
    final chips = <ActiveFilterChip>[];
    final name = _userNmCtrl.text.trim();
    if (name.isNotEmpty) {
      chips.add(ActiveFilterChip(
        label: '사원명: $name',
        onClear: () {
          _setUserNameSafely('');
          _reload();
        },
      ));
    }
    if (_useTypeLabel != '전체') {
      chips.add(ActiveFilterChip(
        label: '사용구분: $_useTypeLabel',
        onClear: () {
          setState(() => _useTypeLabel = '전체');
          _reload();
        },
      ));
    }
    chips.add(ActiveFilterChip(
      label: '사용기간: ${_fmtDay(_rangeStart)} ~ ${_fmtDay(_rangeEnd)}',
      onClear: () {
        final t = _today();
        setState(() {
          _datePreset = '오늘';
          _rangeStart = t;
          _rangeEnd = t;
        });
        _reload();
      },
    ));
    return chips;
  }

  String _fmtDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildSearchFields() {
    return SearchFilterStackedItems(
      items: [
        SearchFilterItemData(
          label: '사원명',
          child: SearchFilterTextField(
            controller: _userNmCtrl,
            hint: '이름 검색',
            onChanged: (_) => _reload(),
          ),
        ),
        SearchFilterItemData(
          label: '사용구분',
          child: SearchFilterDropdownField<String>(
            fieldLabel: '사용구분',
            value: _useTypeLabel,
            items: [
              for (final e in _kUseTypeOptions)
                DropdownMenuItem<String?>(
                  value: e,
                  child: Text(e, style: kSearchFilterValueTextStyle),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _useTypeLabel = v);
              _reload();
            },
          ),
        ),
        SearchFilterItemData(
          label: '사용기간',
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: SearchFilterDropdownField<String>(
                  fieldLabel: '사용기간',
                  value: _datePreset,
                  compact: true,
                  items: [
                    for (final e in _kDatePresets)
                      DropdownMenuItem<String?>(
                        value: e,
                        child: Text(e, style: kSearchFilterValueTextStyle),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null || v == '직접 설정') return;
                    _applyDatePreset(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _dateChip(_rangeStart, () => _pickDate(true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('~', style: kSearchFilterValueTextStyle),
              ),
              _dateChip(_rangeEnd, () => _pickDate(false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateChip(DateTime d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: FormStylePalette.panelBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(_fmtDay(d), style: kSearchFilterValueTextStyle),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _userNmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.hairline)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.accentRed,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            tabs: _kTabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<UsageLogRow>>(
            future: _rowsFuture,
            builder: (context, snap) {
              final rows = snap.data ?? const <UsageLogRow>[];
              final loading = snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData;
              final truncated = rows.length >= _kServerRowLimit;
              return ListPageTemplate(
                activeFilters: _activeChips(),
                mainSearchFields: _buildSearchFields(),
                countText: loading
                    ? '조회 중…'
                    : truncated
                        ? '최근 ${rows.length}건 (조회 상한에 걸림 · 전체 건수 아님)'
                        : '총 ${rows.length}건',
                onRefresh: _reload,
                table: loading
                    ? const Center(child: CircularProgressIndicator())
                    : snap.hasError
                        ? Center(child: Text('조회 실패: ${snap.error}'))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (truncated) ...[
                                const _TruncatedNotice(),
                                const SizedBox(height: 6),
                              ],
                              Expanded(child: _UsageLogTable(rows: rows)),
                            ],
                          ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 조회가 서버 상한에서 잘렸음을 알린다.
///
/// 잘린 사실을 숨기면 "그 이전 기록은 없다"로 오인해 감사 자료로 잘못 쓰게 된다.
class _TruncatedNotice extends StatelessWidget {
  const _TruncatedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: Color(0xFFB45309),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '최신 $_kServerRowLimit건만 조회됩니다. 이보다 이전 기록은 표에 나오지 않으니 '
              '사용기간을 좁혀 다시 조회하세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF92400E),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatUsedAt(DateTime dt) {
  final local = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

class _UsageLogTable extends StatelessWidget {
  const _UsageLogTable({required this.rows});

  final List<UsageLogRow> rows;

  @override
  Widget build(BuildContext context) {
    return ErpDataTable(
      minWidth: AppDimensions.tableMinWidthStandard,
      tableBuilder: (context, width) => Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: kErpTableInnerGridBorder,
        columnWidths: erpTableColumnWidths(context, {
          0: const FixedColumnWidth(170),
          1: const FixedColumnWidth(90),
          2: const FixedColumnWidth(110),
          3: const FixedColumnWidth(100),
          4: const FixedColumnWidth(90),
          5: const FlexColumnWidth(1.6),
        }),
        children: [
          const TableRow(
            decoration: kErpTableHeaderRowDecoration,
            children: [
              ErpTableHeaderCell('사용일자'),
              ErpTableHeaderCell('이름'),
              ErpTableHeaderCell('부서'),
              ErpTableHeaderCell('직급(직책)'),
              ErpTableHeaderCell('사용구분'),
              ErpTableHeaderCell('사용내역'),
            ],
          ),
          for (final r in rows)
            TableRow(
              children: [
                ErpTableBodyCell(_formatUsedAt(r.usedAt), center: true),
                ErpTableBodyCell(r.userNm, center: true),
                ErpTableBodyCell(r.deptNm ?? '', center: true),
                ErpTableBodyCell(r.positionNm ?? '', center: true),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: StatusBadge(
                      r.useTypeNm,
                      showDot: false,
                      color: r.useTypeNm.contains('로그인')
                          ? AppTheme.statusRenewal
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
                ErpTableBodyCell(r.useDetail),
              ],
            ),
        ],
      ),
    );
  }
}
