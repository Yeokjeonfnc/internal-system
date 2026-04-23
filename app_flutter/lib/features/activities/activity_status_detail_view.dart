// 활동 현황 — 스크린샷 기준 목업 데이터·상세 레이아웃 (앱 기본 라이트 테마).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

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
  String _brand = '전체';
  final List<String> _brands = const ['전체', '역전할머니맥주', '지미존스'];

  /// 월 | 분기 | 반기 | 년
  String _periodKind = '월';
  int _year = 2026;
  int _month = 1;
  int _quarter = 1;
  int _half = 1;

  /// 가맹점 탭 전용 — 검색 필터에 표시
  bool _includeTerminatedStores = false;
  bool _visitingStoresOnly = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: i);
    _tabController.addListener(() => setState(() {}));
    _normalizePeriodFields();
  }

  /// 드롭다운 value가 items와 불일치하면 FormField/Web에서 런타임 오류가 날 수 있음.
  void _normalizePeriodFields() {
    const kinds = {'월', '분기', '반기', '년'};
    if (!kinds.contains(_periodKind)) _periodKind = '월';
    _month = _month.clamp(1, 12);
    _quarter = _quarter.clamp(1, 4);
    _half = _half.clamp(1, 2);
    const years = [2025, 2026, 2027];
    if (!years.contains(_year)) _year = 2026;
  }

  @override
  void dispose() {
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
    if (_periodKind != '월') return null;
    return row.dayValue(index0 + 1);
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
            SearchFilterStackedItems(
              items: [
                _brandFilterRowItem(theme),
                _ActivityPeriodFilterSlot(
                  periodKind: _periodKind,
                  onPeriodKind: (v) {
                    if (v == null) return;
                    setState(() {
                      _periodKind = v;
                      if (v == '분기') {
                        _quarter = ((_month - 1) ~/ 3 + 1).clamp(1, 4);
                      } else if (v == '반기') {
                        _half = _month <= 6 ? 1 : 2;
                      }
                    });
                  },
                  year: _year,
                  onYear: (y) => setState(() => _year = y ?? _year),
                  month: _month,
                  onMonth: (m) => setState(() => _month = m ?? _month),
                  quarter: _quarter,
                  onQuarter: (q) => setState(() => _quarter = q ?? _quarter),
                  half: _half,
                  onHalf: (h) => setState(() => _half = h ?? _half),
                ).toItem(),
              ],
            ),
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

  /// 브랜드 한 줄. 가맹점 탭(1)이면 체크박스를 브랜드 필드 오른쪽에 둔다.
  SearchFilterItemData _brandFilterRowItem(ThemeData theme) {
    final brand = FilterStringOptionsSlot(
      label: '브랜드',
      value: _brand,
      options: _brands,
      onSelected: (v) => setState(() => _brand = v),
    ).toItem();

    return SearchFilterItemData(
      label: '브랜드',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: brand.child),
          const SizedBox(width: 12),
          _storeSearchFilterCheckboxes(theme),
        ],
      ),
    );
  }

  /// 가맹점 탭에서만 [브랜드] 옆에 붙는 옵션.
  Widget _storeSearchFilterCheckboxes(ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _includeTerminatedStores,
              onChanged: (v) =>
                  setState(() => _includeTerminatedStores = v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              '해지가맹점 포함',
              style: TextStyle(
                color: _mutedForeground(theme),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _visitingStoresOnly,
              onChanged: (v) =>
                  setState(() => _visitingStoresOnly = v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              '방문가맹점만 검색',
              style: TextStyle(
                color: _mutedForeground(theme),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ],
        ),
      ],
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
    return _scrollTable(
      theme,
      leadingHeader: '가맹점명',
      nameHeader: '담당 슈퍼바이저',
      totalHeader: '활동 가맹점 개수',
      rows: _assigneeRows,
    );
  }

  Widget _storeTable(ThemeData theme) {
    return _scrollTable(
      theme,
      nameHeader: '가맹점명',
      totalHeader: '총 활동수',
      rows: _storeRows,
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
          foregroundColor: AppTheme.statusPreparing,
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
          foregroundColor: AppTheme.statusPreparing,
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

  /// 스크린샷 1 — 담당자별
  List<_StatusRow> get _assigneeRows => [
    _StatusRow(
      '강동우',
      storeName: '서울강남서초타운점',
      totalDisplay: '56',
      totalIsLink: true,
      days: const {},
    ),
    _StatusRow('관리자', totalDisplay: null, totalIsLink: false, days: const {}),
    _StatusRow(
      '김땡땡',
      storeName: '서울독산역점',
      totalDisplay: '63',
      totalIsLink: true,
      days: const {2: 2, 5: 4, 6: 5, 8: 4},
    ),
    _StatusRow(
      '김똥똥',
      storeName: '서울송리단길석촌역점',
      totalDisplay: '52',
      totalIsLink: true,
      days: const {2: 1, 6: 5, 7: 5, 8: 6, 9: 1},
    ),
    _StatusRow(
      '김뿡뿡',
      storeName: '서울여의도점',
      totalDisplay: '53',
      totalIsLink: true,
      days: const {5: 1, 6: 4, 7: 5, 8: 3},
    ),
    _StatusRow(
      '노준호',
      storeName: '파주LG디스플레이점',
      totalDisplay: '56',
      totalIsLink: true,
      days: const {7: 7, 8: 6},
    ),
    _StatusRow('박경팔', totalDisplay: null, totalIsLink: false, days: const {}),
    _StatusRow('박현수', totalDisplay: null, totalIsLink: false, days: const {}),
    _StatusRow(
      '서영인',
      storeName: '할맥 울산천곡점',
      totalDisplay: '52',
      totalIsLink: true,
      days: const {7: 4, 8: 8, 9: 5},
    ),
    _StatusRow(
      '성화정',
      storeName: '할맥 가평 현리점(소)',
      totalDisplay: '35',
      totalIsLink: true,
      days: const {5: 1, 6: 4, 7: 5, 8: 3, 9: 1},
    ),
    _StatusRow(
      '순현진',
      storeName: '할맥 강릉 교동점',
      totalDisplay: '47',
      totalIsLink: true,
      days: const {5: 1, 6: 4, 7: 4},
    ),
    _StatusRow(
      '안기주',
      storeName: '할맥 강원 홍천점',
      totalDisplay: '54',
      totalIsLink: true,
      days: const {5: 1, 6: 4, 7: 5, 8: 5, 9: 5},
    ),
    _StatusRow(
      '역전F&C공용',
      storeName: '본사',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
  ];

  /// 스크린샷 2 — 가맹점별 (일별은 모두 '-', 총합만 일부 표기)
  List<_StatusRow> get _storeRows => [
    _StatusRow('본사', totalDisplay: null, totalIsLink: false, days: const {}),
    _StatusRow(
      '서울강남서초타운점',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '서울독산역점',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '서울송리단길석촌역점',
      totalDisplay: '1',
      totalIsLink: true,
      days: const {},
    ),
    _StatusRow(
      '서울여의도점',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '안동 옥동점 - 사용안함',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '역전할머니맥주(충북 혁신점)',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '파주LG디스플레이점',
      totalDisplay: '1',
      totalIsLink: true,
      days: const {},
    ),
    _StatusRow(
      '할맥 울산천곡점',
      totalDisplay: '1',
      totalIsLink: true,
      days: const {},
    ),
    _StatusRow(
      '할맥 가평 현리점(소)',
      totalDisplay: null,
      totalIsLink: false,
      days: const {},
    ),
    _StatusRow(
      '할맥 강릉 교동점',
      totalDisplay: '1',
      totalIsLink: true,
      days: const {},
    ),
    _StatusRow(
      '할맥 강원 홍천점',
      totalDisplay: '1',
      totalIsLink: true,
      days: const {},
    ),
  ];
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

  static const _years = [2025, 2026, 2027];
  static const _kinds = ['월', '분기', '반기', '년'];

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
    this.storeName,
    required this.totalDisplay,
    required this.totalIsLink,
    required this.days,
  });

  final String name;

  /// 담당자 탭 첫 열(가맹점명). 가맹점 탭에서는 사용하지 않음.
  final String? storeName;
  final String? totalDisplay;
  final bool totalIsLink;
  final Map<int, int> days;

  int? dayValue(int day) => days[day];
}
