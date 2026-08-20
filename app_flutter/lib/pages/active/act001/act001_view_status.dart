// 활동 현황 — 상세 레이아웃 (앱 기본 라이트 테마).

import 'package:flutter/material.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/active/act001/act001_api.dart';
import 'package:app_flutter/pages/active/act001/act001_filter.dart';
import 'package:app_flutter/pages/active/act001/act001_model.dart';

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

  /// 본문을 행마다 [Table] 로 쪼개 그리므로(가상 스크롤) 헤더·행이 위·아래 선을 둘 다
  /// 그리면 경계선이 2겹이 된다. 헤더만 네 변을 그리고 행은 위를 뺀 세 변만 그린다.
  static const BorderSide _gridSide = BorderSide(color: _outline, width: 1);
  static const TableBorder _headerGridBorder = TableBorder(
    top: _gridSide,
    bottom: _gridSide,
    left: _gridSide,
    right: _gridSide,
    verticalInside: _gridSide,
  );
  static const TableBorder _rowGridBorder = TableBorder(
    bottom: _gridSide,
    left: _gridSide,
    right: _gridSide,
    verticalInside: _gridSide,
  );

  /// 열 고정 폭 — 가상 스크롤이라 본문 폭을 미리 합산해야 한다.
  static const double _nameColWidth = 220;
  static const double _totalColWidth = 132;
  static const double _timelineColWidthDay = 50;
  static const double _timelineColWidthMonth = 58;

  late TabController _tabController;
  final ScrollController _tableHScroll = ScrollController();
  final ScrollController _tableVScroll = ScrollController();
  List<CodeOption> _brandOptions = const [];
  late Future<List<_StatusRow>> _assigneeRowsFuture;
  late Future<List<_StatusRow>> _storeRowsFuture;

  late Act001StatusFilter _f;

  @override
  void initState() {
    super.initState();
    _f = Act001StatusFilter.initial();

    final i = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: i);
    _tabController.addListener(_onTabChanged);
    _f.syncPeriod();
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
    // 공통코드 조회는 StateError 를 던진다. 잡지 않으면 아무도 받지 못한 비동기 오류로
    // 남아 브랜드 필터가 왜 비었는지 알 수 없으므로 여기서 로그만 남기고 넘어간다.
    final List<CodeOption> brands;
    try {
      brands = await CommonCodeApiService().getCodes(40);
    } catch (e) {
      debugPrint('Error fetching brand codes: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _brandOptions = brands);
  }

  /// 칩/드롭다운 표시용(코드명). API에는 [_f.brandCd] 코드를 넘긴다.
  List<String> get _brandChipLabels => <String>[
    '전체',
    ..._brandOptions.map((e) => e.codeNm),
  ];

  String get _brandChipSelectedLabel {
    if (_f.brandCd.isEmpty) return '전체';
    for (final b in _brandOptions) {
      if (b.codeCd == _f.brandCd) return b.codeNm;
    }
    return '전체';
  }

  void _onBrandChipOrDropdownSelected(String label) {
    setState(() {
      if (label == '전체') {
        _f.brandCd = '';
      } else {
        final hits = _brandOptions.where((e) => e.codeNm == label).toList();
        _f.brandCd = hits.isEmpty ? '' : hits.first.codeCd;
      }
    });
    _reloadRows();
  }

  /// 드롭다운 value가 items와 불일치하면 FormField/Web에서 런타임 오류가 날 수 있음.
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tableHScroll.dispose();
    _tableVScroll.dispose();
    super.dispose();
  }

  String _formatYmd(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  /// 보이는 탭만 다시 조회한다. 탭을 바꾸면 [_onTabChanged] 가 그쪽을 다시 조회하므로
  /// 둘 다 부르면 요청이 두 배가 되고, 화면에 붙지 않은 Future 의 실패는 아무도 받지 못한다.
  void _reloadRows() {
    setState(() {
      if (_tabController.index == 0) {
        _assigneeRowsFuture = _pullRows('by-assignee');
      } else {
        _storeRowsFuture = _pullRows('by-store');
      }
    });
  }

  Future<List<_StatusRow>> _pullRows(String type) async {
    final range = _f.selectedDateRange;
    final rows = await Act001Api().fetchStatus(
      type: type,
      startDt: _formatYmd(range.$1),
      endDt: _formatYmd(range.$2),
      brandCd: _f.brandCd.isEmpty ? null : _f.brandCd,
    );
    return type == 'by-store'
        ? _mapStoreStatusRows(rows, visitingStoresOnly: _f.visitingStoresOnly)
        : _mapAssigneeStatusRows(rows);
  }

  String _timelineHeaderLabel(int index0) {
    switch (_f.periodKind) {
      case '월':
        return '${index0 + 1}일';
      case '분기':
        final startMonth = (_f.quarter - 1) * 3 + 1;
        return '${startMonth + index0}월';
      case '반기':
        final startMonth = (_f.half - 1) * 6 + 1;
        return '${startMonth + index0}월';
      case '년':
        return '${index0 + 1}월';
      default:
        return '';
    }
  }

  int? _timelineCellValue(_StatusRow row, int index0) {
    switch (_f.periodKind) {
      case '월':
        return row.bucketValue(index0 + 1);
      case '분기':
        return row.bucketValue((_f.quarter - 1) * 3 + index0 + 1);
      case '반기':
        return row.bucketValue((_f.half - 1) * 6 + index0 + 1);
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
    final labels = _brandChipLabels;
    final chips = FilterStringOptionsSlot(
      label: '',
      value: _brandChipSelectedLabel,
      options: labels,
      onSelected: _onBrandChipOrDropdownSelected,
      forceDropdown: labels.length > kFilterStringChipMaxCount,
    ).toItem().child;

    final brandField = compact
        ? SizedBox(width: double.infinity, child: chips)
        : chips;

    if (_tabController.index != 1) {
      return Align(alignment: Alignment.centerLeft, child: brandField);
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          brandField,
          const SizedBox(height: 8),
          _storeSearchFilterCheckboxes(theme),
        ],
      );
    }

    return Row(
      children: [
        brandField,
        const SizedBox(width: 14),
        Expanded(child: _storeSearchFilterCheckboxes(theme)),
      ],
    );
  }

  Widget _periodFilterContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _ActivityPeriodFilterSlot(
        periodKind: _f.periodKind,
        onPeriodKind: (v) {
          if (v == null) return;
          setState(() {
            _f.periodKind = v;
            if (v == '분기') {
              _f.quarter = ((_f.month - 1) ~/ 3 + 1).clamp(1, 4);
            } else if (v == '반기') {
              _f.half = _f.month <= 6 ? 1 : 2;
            }
          });
          _reloadRows();
        },
        year: _f.year,
        onYear: (y) {
          setState(() => _f.year = y ?? _f.year);
          _reloadRows();
        },
        month: _f.month,
        onMonth: (m) {
          setState(() => _f.month = m ?? _f.month);
          _reloadRows();
        },
        quarter: _f.quarter,
        onQuarter: (q) {
          setState(() => _f.quarter = q ?? _f.quarter);
          _reloadRows();
        },
        half: _f.half,
        onHalf: (h) {
          setState(() => _f.half = h ?? _f.half);
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
          label: '방문가맹점만 검색',
          value: _f.visitingStoresOnly,
          onChanged: (v) {
            setState(() {
              _f.visitingStoresOnly = v ?? false;
              _storeRowsFuture = _pullRows('by-store');
            });
          },
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
    final n = _f.timelineColumnCount;
    final hasLeading = leadingHeader != null;
    final nameCol = hasLeading ? 1 : 0;
    final totalCol = hasLeading ? 2 : 1;
    final timelineStart = hasLeading ? 3 : 2;
    final timelineColWidth = _f.periodKind == '월'
        ? _timelineColWidthDay
        : _timelineColWidthMonth;
    final columnWidths = <int, TableColumnWidth>{
      if (hasLeading) 0: const FixedColumnWidth(_nameColWidth),
      nameCol: const FixedColumnWidth(_nameColWidth),
      totalCol: const FixedColumnWidth(_totalColWidth),
      for (int i = 0; i < n; i++)
        timelineStart + i: FixedColumnWidth(timelineColWidth),
    };
    // 가로 스크롤 안에서는 폭 제약이 무한이라 열 폭을 직접 합산해 SizedBox 로 고정한다.
    final tableWidth =
        (hasLeading ? _nameColWidth : 0.0) +
        _nameColWidth +
        _totalColWidth +
        n * timelineColWidth;

    return Scrollbar(
      controller: _tableHScroll,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _tableHScroll,
        primary: false,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: _headerGridBorder,
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppTheme.tableRowEven,
                    ),
                    children: [
                      if (hasLeading) _cell(theme, leadingHeader, header: true),
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
                ],
              ),
              // 가맹점 탭은 활동이 0건인 가맹점까지 내려와 행이 1,000개를 넘고, '월' 구간이면
              // 열이 33개다. 한 [Table] 로 그리면 3만 셀이 한 프레임에 build 되어 화면이 멈추므로
              // dev003 목록([ErpVirtualDataTable])과 같이 행마다 Table 을 만들어 지연 생성한다.
              Expanded(
                child: Scrollbar(
                  controller: _tableVScroll,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.vertical,
                  child: ListView.builder(
                    controller: _tableVScroll,
                    primary: false,
                    itemCount: rows.length,
                    itemBuilder: (context, i) => Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: _rowGridBorder,
                      columnWidths: columnWidths,
                      children: [
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
            ],
          ),
        ),
      ),
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
          foregroundColor: AppTheme.accentRed,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
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

  /// 방문 count 셀 — 레드 틴트 배지, 값이 클수록 배경을 진하게(02_screens.md §11).
  Widget _dayCell(ThemeData theme, int? value) {
    if (value == null) {
      return _cell(theme, '-', center: true);
    }
    final tint = (0.06 + 0.05 * (value.clamp(1, 6) - 1)).clamp(0.06, 0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withValues(alpha: tint.toDouble()),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentRed,
              fontFeatures: [FontFeature.tabularFigures()],
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
          ),
        ),
      ),
    );
  }

  /// 서버가 `startDt`~`endDt`로 이미 필터링하므로 여기서는 날짜 재검사를 하지 않는다.
  /// [visitingStoresOnly] 가 true이면 기간 내 **총 활동수가 0보다 큰** 가맹점만 남긴다.
  List<_StatusRow> _mapStoreStatusRows(
    List<ActivityStatusPivotRow> rows, {
    required bool visitingStoresOnly,
  }) {
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
        if (!visitingStoresOnly || row.total > 0)
          _StatusRow(
            row.name,
            storeName: null,
            totalDisplay: '${row.total}',
            totalIsLink: false,
            buckets: row.buckets,
          ),
    ];
  }

  String _assigneeDisplayName(ActivityStatusPivotRow row) {
    final name = row.userName.trim();
    if (name.isNotEmpty && name != '0') return name;
    final id = row.userId.trim();
    return id.isNotEmpty ? id : name;
  }

  List<_StatusRow> _mapAssigneeStatusRows(List<ActivityStatusPivotRow> rows) {
    final grouped = <String, _MutableStatusRow>{};

    // 모든 수퍼바이저를 먼저 추가
    for (final row in rows) {
      final label = _assigneeDisplayName(row);
      if (label.isEmpty) continue;
      grouped.putIfAbsent(label, () => _MutableStatusRow(label));
    }

    // 활동 데이터가 있는 경우 count 추가
    for (final row in rows) {
      final label = _assigneeDisplayName(row);
      final actDt = _parseDate(row.actDtRaw);
      final count = row.count;

      if (label.isEmpty || actDt == null || count <= 0) continue;

      final target = grouped[label];
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

  int _bucketKey(DateTime date) => _f.periodKind == '월' ? date.day : date.month;

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
  static List<int> get _years => Act001StatusFilter.yearRange;

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
