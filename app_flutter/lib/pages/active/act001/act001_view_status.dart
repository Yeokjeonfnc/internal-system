// 활동 현황 — 상세 레이아웃 (앱 기본 라이트 테마).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/active/activity_api.dart';
import 'package:app_flutter/pages/active/activity_model.dart';

/// 담당자별 / 가맹점별 탭이 있는 활동 현황 상세.
class ActivityStatusDetailView extends StatefulWidget {
  const ActivityStatusDetailView({super.key, this.initialTab = 0});

  /// 0: 담당자별, 1: 가맹점별
  final int initialTab;

  @override
  State<ActivityStatusDetailView> createState() =>
      _ActivityStatusDetailViewState();
}

class _ActivityStatusDetailViewState extends State<ActivityStatusDetailView>
    with SingleTickerProviderStateMixin {
  static const _outline = Color(0xFFE5E7EB);
  static const _tabInactiveBg = Color(0xFFF3F4F6);

  late TabController _tabController;
  final ScrollController _tableHScroll = ScrollController();
  final ScrollController _tableVScroll = ScrollController();
  String _brandCd = '';
  List<CodeOption> _brandOptions = const [];
  late Future<List<_StatusRow>> _assigneeRowsFuture;
  late Future<List<_StatusRow>> _storeRowsFuture;

  /// 월 | 분기 | 반기 | 년
  String _periodKind = '월';
  late int _year;
  late int _month;
  late int _quarter;
  late int _half;

  /// 가맹점 탭 전용 — 검색 필터에 표시
  bool _includeTerminatedStores = false;
  bool _visitingStoresOnly = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _quarter = ((now.month - 1) ~/ 3) + 1;
    _half = now.month <= 6 ? 1 : 2;

    final i = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: i);
    _tabController.addListener(_onTabChanged);
    _syncPeriod();
    _assigneeRowsFuture = _pullRows('by-assignee');
    _storeRowsFuture = _pullRows('by-store');
    _loadBrands();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
      return;
    }
    setState(() {
      if (_tabController.index == 0) {
        _assigneeRowsFuture = _pullRows('by-assignee');
      } else {
        _storeRowsFuture = _pullRows('by-store');
      }
    });
  }

  Future<void> _loadBrands() async {
    final brands = await CommonCodeApiService().getCodes(40);
    if (!mounted) return;
    setState(() => _brandOptions = brands);
  }

  /// 드롭다운 value가 items와 불일치하면 FormField/Web에서 런타임 오류가 날 수 있음.
  void _syncPeriod() {
    const kinds = {'월', '분기', '반기', '년'};
    if (!kinds.contains(_periodKind)) _periodKind = '월';
    _month = _month.clamp(1, 12);
    _quarter = _quarter.clamp(1, 4);
    _half = _half.clamp(1, 2);
    final years = _getYearRange();
    if (!years.contains(_year)) _year = DateTime.now().year;
  }

  /// 현재 연도 ± 1년 범위
  List<int> _getYearRange() {
    final now = DateTime.now().year;
    return [now - 1, now, now + 1];
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tableHScroll.dispose();
    _tableVScroll.dispose();
    super.dispose();
  }

  int get _timelineColumnCount => switch (_periodKind) {
    '월' => DateUtils.getDaysInMonth(_year, _month),
    '분기' => 3,
    '반기' => 6,
    '년' => 12,
    _ => 12,
  };

  (DateTime, DateTime) get _selectedDateRange {
    switch (_periodKind) {
      case '월':
        return (
          DateTime(_year, _month, 1),
          DateTime(_year, _month, DateUtils.getDaysInMonth(_year, _month)),
        );
      case '분기':
        final startMonth = (_quarter - 1) * 3 + 1;
        return (
          DateTime(_year, startMonth, 1),
          DateTime(_year, startMonth + 3, 0),
        );
      case '반기':
        final startMonth = _half == 1 ? 1 : 7;
        return (
          DateTime(_year, startMonth, 1),
          DateTime(_year, startMonth + 6, 0),
        );
      case '년':
        return (DateTime(_year, 1, 1), DateTime(_year, 12, 31));
      default:
        return (DateTime(_year, 1, 1), DateTime(_year, 12, 31));
    }
  }

  String _formatYmd(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  void _reloadRows() {
    setState(() {
      _assigneeRowsFuture = _pullRows('by-assignee');
      _storeRowsFuture = _pullRows('by-store');
    });
  }

  Future<List<_StatusRow>> _pullRows(String type) async {
    final range = _selectedDateRange;
    final rows = await ActivityApiService().fetchStatus(
      type: type,
      startDt: _formatYmd(range.$1),
      endDt: _formatYmd(range.$2),
      brandCd: _brandCd.isEmpty ? null : _brandCd,
    );
    return type == 'by-store'
        ? _mapStoreStatusRows(rows)
        : _mapAssigneeStatusRows(rows);
  }

  String _timelineHeaderLabel(int index0) {
    switch (_periodKind) {
      case '월':
        return '${index0 + 1}일';
      case '분기':
        final startMonth = (_quarter - 1) * 3 + 1;
        return '${startMonth + index0}월';
      case '반기':
        final startMonth = (_half - 1) * 6 + 1;
        return '${startMonth + index0}월';
      case '년':
        return '${index0 + 1}월';
      default:
        return '';
    }
  }

  int? _timelineCellValue(_StatusRow row, int index0) {
    switch (_periodKind) {
      case '월':
        return row.bucketValue(index0 + 1);
      case '분기':
        return row.bucketValue((_quarter - 1) * 3 + index0 + 1);
      case '반기':
        return row.bucketValue((_half - 1) * 6 + index0 + 1);
      case '년':
        return row.bucketValue(index0 + 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.sizeOf(context).height;

    /// 가맹점·활동관리 목록과 동일한 [MediaQuery.textScaler] 유지(별도 배율 없음).
    final tabHeight = screenH > 0
        ? (screenH * 0.48).clamp(400.0, 760.0)
        : 580.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterPanel(theme),
            const SizedBox(height: 18),
            _tabBar(theme),
            const SizedBox(height: 14),
            SizedBox(
              height: tabHeight,
              child: _tabController.index == 0
                  ? _assigneeTable(theme)
                  : _storeTable(theme),
            ),
          ],
        ),
      ),
    );
  }

  Color _mutedForeground(ThemeData theme) =>
      theme.colorScheme.onSurface.withValues(alpha: 0.62);

  Widget _filterPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 1),
            blurRadius: 8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 860;
          final children = [
            _filterSection(
              theme,
              label: '브랜드',
              child: _brandFilterContent(theme, compact: narrow),
            ),
            _filterSection(
              theme,
              label: '활동 기간',
              child: _periodFilterContent(),
            ),
          ];

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [children[0], const SizedBox(height: 12), children[1]],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 14),
              Expanded(child: children[1]),
            ],
          );
        },
      ),
    );
  }

  Widget _filterSection(
    ThemeData theme, {
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedForeground(theme),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _brandFilterContent(ThemeData theme, {required bool compact}) {
    final brandDropdown = SizedBox(
      width: compact ? double.infinity : 190,
      child: SearchFilterDropdownField<String>(
        fieldLabel: '활동현황_브랜드',
        value: _brandCd,
        items: [
          const DropdownMenuItem<String?>(
            value: '',
            child: Text('전체', style: kSearchFilterValueTextStyle),
          ),
          for (final brand in _brandOptions)
            DropdownMenuItem<String?>(
              value: brand.codeCd,
              child: Text(brand.codeNm, style: kSearchFilterValueTextStyle),
            ),
        ],
        onChanged: (v) {
          if (v == null) return;
          _brandCd = v;
          _reloadRows();
        },
      ),
    );

    if (_tabController.index != 1) {
      return Align(alignment: Alignment.centerLeft, child: brandDropdown);
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          brandDropdown,
          const SizedBox(height: 8),
          _storeSearchFilterCheckboxes(theme),
        ],
      );
    }

    return Row(
      children: [
        brandDropdown,
        const SizedBox(width: 14),
        Expanded(child: _storeSearchFilterCheckboxes(theme)),
      ],
    );
  }

  Widget _periodFilterContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _ActivityPeriodFilterSlot(
        periodKind: _periodKind,
        onPeriodKind: (v) {
          if (v == null) return;
          _periodKind = v;
          if (v == '분기') {
            _quarter = ((_month - 1) ~/ 3 + 1).clamp(1, 4);
          } else if (v == '반기') {
            _half = _month <= 6 ? 1 : 2;
          }
          _reloadRows();
        },
        year: _year,
        onYear: (y) {
          _year = y ?? _year;
          _reloadRows();
        },
        month: _month,
        onMonth: (m) {
          _month = m ?? _month;
          _reloadRows();
        },
        quarter: _quarter,
        onQuarter: (q) {
          _quarter = q ?? _quarter;
          _reloadRows();
        },
        half: _half,
        onHalf: (h) {
          _half = h ?? _half;
          _reloadRows();
        },
      ).toItem().child,
    );
  }

  /// 가맹점 탭에서만 [브랜드] 옆에 붙는 옵션.
  Widget _storeSearchFilterCheckboxes(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _filterCheckbox(
          theme,
          label: '해지가맹점 포함',
          value: _includeTerminatedStores,
          onChanged: (v) =>
              setState(() => _includeTerminatedStores = v ?? false),
        ),
        _filterCheckbox(
          theme,
          label: '방문가맹점만 검색',
          value: _visitingStoresOnly,
          onChanged: (v) => setState(() => _visitingStoresOnly = v ?? false),
        ),
      ],
    );
  }

  Widget _filterCheckbox(
    ThemeData theme, {
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: _mutedForeground(theme),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _outline)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: const BoxDecoration(),
        labelPadding: const EdgeInsets.only(right: 8),
        dividerColor: Colors.transparent,
        tabs: [
          _tabChip(theme, 0, '담당자별 활동 가맹점 개수 현황'),
          _tabChip(theme, 1, '가맹점별 활동 현황'),
        ],
      ),
    );
  }

  Widget _tabChip(ThemeData theme, int index, String label) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final active = _tabController.index == index;
        return Tab(
          height: 48,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppTheme.cardBackground : _tabInactiveBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: _outline),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active
                    ? theme.colorScheme.primary
                    : _mutedForeground(theme),
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _assigneeTable(ThemeData theme) {
    return FutureBuilder<List<_StatusRow>>(
      future: _assigneeRowsFuture,
      builder: (context, snapshot) => _statusTableBody(
        theme,
        snapshot,
        nameHeader: '담당 수퍼바이저',
        totalHeader: '총 활동 가맹점 개수',
      ),
    );
  }

  Widget _storeTable(ThemeData theme) {
    return FutureBuilder<List<_StatusRow>>(
      future: _storeRowsFuture,
      builder: (context, snapshot) => _statusTableBody(
        theme,
        snapshot,
        nameHeader: '가맹점명',
        totalHeader: '총 활동수',
      ),
    );
  }

  Widget _statusTableBody(
    ThemeData theme,
    AsyncSnapshot<List<_StatusRow>> snapshot, {
    String? leadingHeader,
    required String nameHeader,
    required String totalHeader,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Text(
          '활동현황을 불러오지 못했습니다.',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }
    final rows = snapshot.data ?? const <_StatusRow>[];
    if (rows.isEmpty) {
      return Center(
        child: Text(
          '조회된 활동현황이 없습니다.',
          style: TextStyle(
            color: _mutedForeground(theme),
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      );
    }
    return _scrollTable(
      theme,
      leadingHeader: leadingHeader,
      nameHeader: nameHeader,
      totalHeader: totalHeader,
      rows: rows,
    );
  }

  Widget _scrollTable(
    ThemeData theme, {
    String? leadingHeader,
    required String nameHeader,
    required String totalHeader,
    required List<_StatusRow> rows,
  }) {
    final n = _timelineColumnCount;
    final hasLeading = leadingHeader != null;
    final nameCol = hasLeading ? 1 : 0;
    final totalCol = hasLeading ? 2 : 1;
    final timelineStart = hasLeading ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            controller: _tableHScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _tableHScroll,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: Scrollbar(
                controller: _tableVScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _tableVScroll,
                  primary: false,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(color: _outline, width: 1),
                    columnWidths: {
                      if (hasLeading) 0: const FixedColumnWidth(220),
                      nameCol: const FixedColumnWidth(220),
                      totalCol: const FixedColumnWidth(132),
                      for (int i = 0; i < n; i++)
                        timelineStart + i: FixedColumnWidth(
                          _periodKind == '월' ? 50 : 58,
                        ),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppTheme.tableRowEven,
                        ),
                        children: [
                          if (hasLeading)
                            _cell(theme, leadingHeader, header: true),
                          _cell(theme, nameHeader, header: true),
                          _cell(theme, totalHeader, header: true, center: true),
                          for (int i = 0; i < n; i++)
                            _cell(
                              theme,
                              _timelineHeaderLabel(i),
                              header: true,
                              center: true,
                            ),
                        ],
                      ),
                      for (int i = 0; i < rows.length; i++)
                        TableRow(
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? AppTheme.tableRowOdd
                                : AppTheme.tableRowEven,
                          ),
                          children: [
                            if (hasLeading)
                              _cell(
                                theme,
                                _leadingStoreLabel(rows[i].storeName),
                              ),
                            _cell(theme, _safeTableLabel(rows[i].name)),
                            _totalCell(
                              theme,
                              rows[i].totalDisplay,
                              rows[i].totalIsLink,
                            ),
                            for (int c = 0; c < n; c++)
                              _dayCell(theme, _timelineCellValue(rows[i], c)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 담당자 탭 선행 열(가맹점명) — 비어 있으면 대시 표시.
  String _leadingStoreLabel(String? storeName) {
    final t = storeName?.trim() ?? '';
    return t.isEmpty ? '-' : t;
  }

  Widget _cell(
    ThemeData theme,
    String? text, {
    bool header = false,
    bool center = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text ?? '',
        textAlign: center ? TextAlign.center : TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          color: theme.colorScheme.onSurface,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
    );
  }

  Widget _totalCell(ThemeData theme, String? text, bool asLink) {
    if (text == null || text.isEmpty) {
      return _cell(theme, '-', center: true);
    }
    if (!asLink) {
      return _cell(theme, text, center: true);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.statusNew,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }

  /// 웹 등에서 빈/이상 문자열이 Text 경로에서 문제 되는 경우 방지.
  String _safeTableLabel(String value) {
    final t = value.trim();
    return t.isEmpty ? '\u00a0' : t;
  }

  Widget _dayCell(ThemeData theme, int? value) {
    if (value == null) {
      return _cell(theme, '-', center: true);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.statusNew,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
    );
  }

  /// 서버가 `startDt`~`endDt`로 이미 필터링하므로 여기서는 날짜 재검사를 하지 않는다.
  List<_StatusRow> _mapStoreStatusRows(List<ActivityStatusPivotRow> rows) {
    final grouped = <String, _MutableStatusRow>{};

    // 모든 가맹점을 먼저 추가
    for (final row in rows) {
      final storeNm = row.storeNm;
      if (storeNm.isEmpty) continue;
      grouped.putIfAbsent(storeNm, () => _MutableStatusRow(storeNm));
    }

    // 활동 데이터가 있는 경우 count 추가
    for (final row in rows) {
      final storeNm = row.storeNm;
      final actDt = _parseDate(row.actDtRaw);
      final count = row.count;

      if (storeNm.isEmpty || actDt == null || count <= 0) continue;

      final target = grouped[storeNm];
      if (target != null) {
        target.add(_bucketKey(actDt), count);
      }
    }

    return [
      for (final row in grouped.values)
        _StatusRow(
          row.name,
          storeName: null,
          totalDisplay: '${row.total}',
          totalIsLink: false,
          buckets: row.buckets,
        ),
    ];
  }

  List<_StatusRow> _mapAssigneeStatusRows(List<ActivityStatusPivotRow> rows) {
    final grouped = <String, _MutableStatusRow>{};

    // 모든 수퍼바이저를 먼저 추가
    for (final row in rows) {
      final userName = row.userName;
      if (userName.isEmpty) continue;
      grouped.putIfAbsent(userName, () => _MutableStatusRow(userName));
    }

    // 활동 데이터가 있는 경우 count 추가
    for (final row in rows) {
      final userName = row.userName;
      final actDt = _parseDate(row.actDtRaw);
      final count = row.count;

      if (userName.isEmpty || actDt == null || count <= 0) continue;

      final target = grouped[userName];
      if (target != null) {
        target.add(_bucketKey(actDt), count);
      }
    }

    return [
      for (final row in grouped.values)
        _StatusRow(
          row.name,
          storeName: null,
          totalDisplay: '${row.total}',
          totalIsLink: false,
          buckets: row.buckets,
        ),
    ];
  }

  int _bucketKey(DateTime date) => _periodKind == '월' ? date.day : date.month;

  DateTime? _parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class _ActivityPeriodFilterSlot extends FilterSlotConfig {
  _ActivityPeriodFilterSlot({
    required this.periodKind,
    required this.onPeriodKind,
    required this.year,
    required this.onYear,
    required this.month,
    required this.onMonth,
    required this.quarter,
    required this.onQuarter,
    required this.half,
    required this.onHalf,
  });

  final String periodKind;
  final ValueChanged<String?> onPeriodKind;
  final int year;
  final ValueChanged<int?> onYear;
  final int month;
  final ValueChanged<int?> onMonth;
  final int quarter;
  final ValueChanged<int?> onQuarter;
  final int half;
  final ValueChanged<int?> onHalf;

  static const _kinds = ['월', '분기', '반기', '년'];

  /// 현재 연도 ± 1년 범위
  static List<int> get _years {
    final now = DateTime.now().year;
    return [now - 1, now, now + 1];
  }

  /// [Expanded]로 늘리면 남는 가로가 균등 분배되어 칸이 과하게 벌어짐 — 콤팩트 폭으로 고정.
  static const _wKind = 120.0;
  static const _wYear = 120.0;
  static const _wMonth = 100.0;
  static const _wQuarter = 120.0;
  static const _wHalf = 120.0;
  static const _gap = 8.0;

  @override
  SearchFilterItemData toItem() {
    return SearchFilterItemData(
      label: '활동 기간',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _wKind,
            child: SearchFilterDropdownField<String>(
              fieldLabel: '활동기간_구분',
              value: periodKind,
              items: [
                for (final k in _kinds)
                  DropdownMenuItem<String?>(
                    value: k,
                    child: Text(k, style: kSearchFilterValueTextStyle),
                  ),
              ],
              onChanged: onPeriodKind,
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _wYear,
            child: SearchFilterDropdownField<int>(
              fieldLabel: '활동기간_연',
              value: year,
              items: [
                for (final y in _years)
                  DropdownMenuItem<int?>(
                    value: y,
                    child: Text('$y', style: kSearchFilterValueTextStyle),
                  ),
              ],
              onChanged: onYear,
            ),
          ),
          if (periodKind == '월') ...[
            const SizedBox(width: _gap),
            SizedBox(
              width: _wMonth,
              child: SearchFilterDropdownField<int>(
                fieldLabel: '활동기간_월',
                value: month,
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem<int?>(
                      value: m,
                      child: Text('$m월', style: kSearchFilterValueTextStyle),
                    ),
                ],
                onChanged: onMonth,
              ),
            ),
          ],
          if (periodKind == '분기') ...[
            const SizedBox(width: _gap),
            SizedBox(
              width: _wQuarter,
              child: SearchFilterDropdownField<int>(
                fieldLabel: '활동기간_분기',
                value: quarter,
                items: [
                  for (var q = 1; q <= 4; q++)
                    DropdownMenuItem<int?>(
                      value: q,
                      child: Text('$q분기', style: kSearchFilterValueTextStyle),
                    ),
                ],
                onChanged: onQuarter,
              ),
            ),
          ],
          if (periodKind == '반기') ...[
            const SizedBox(width: _gap),
            SizedBox(
              width: _wHalf,
              child: SearchFilterDropdownField<int>(
                fieldLabel: '활동기간_반기',
                value: half,
                items: const [
                  DropdownMenuItem<int?>(
                    value: 1,
                    child: Text('1반기', style: kSearchFilterValueTextStyle),
                  ),
                  DropdownMenuItem<int?>(
                    value: 2,
                    child: Text('2반기', style: kSearchFilterValueTextStyle),
                  ),
                ],
                onChanged: onHalf,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow {
  _StatusRow(
    this.name, {
    required this.storeName,
    required this.totalDisplay,
    required this.totalIsLink,
    required this.buckets,
  });

  final String name;

  /// 담당자 탭 첫 열(가맹점명). 가맹점 탭에서는 사용하지 않음.
  final String? storeName;
  final String? totalDisplay;
  final bool totalIsLink;
  final Map<int, int> buckets;

  int? bucketValue(int bucket) => buckets[bucket];
}

class _MutableStatusRow {
  _MutableStatusRow(this.name);

  final String name;
  final Map<int, int> buckets = {};
  int total = 0;

  void add(int bucket, int count) {
    buckets[bucket] = (buckets[bucket] ?? 0) + count;
    total += count;
  }
}
