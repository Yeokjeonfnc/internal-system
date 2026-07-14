// ERP 스타일 가로 스크롤 테이블 래퍼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/app_dimensions.dart';

/// 앱(컴팩트)에서 목록 테이블 최소 가로 폭을 줄인다.
double erpTableMinWidth(BuildContext context, double requested) {
  if (!useCompactErpLayout(context)) return requested;
  // 요청 폭을 factor 만큼 줄이되 480px(가독 하한)~요청 폭 사이로 맞춘다.
  // 요청 폭이 480보다 작으면(예: 결재라인 표 300) 그 값을 하한으로 써
  // clamp(lower>upper) → ArgumentError(릴리즈에선 회색 ErrorWidget)를 막는다.
  final shrunk = requested * AppDimensions.tableCompactMinWidthFactor;
  final floor = requested < 480.0 ? requested : 480.0;
  return shrunk.clamp(floor, requested);
}

/// 앱(컴팩트)에서 [FixedColumnWidth] 열만 비율로 축소한다.
Map<int, TableColumnWidth> erpTableColumnWidths(
  BuildContext context,
  Map<int, TableColumnWidth> widths,
) {
  if (!useCompactErpLayout(context)) return widths;
  final scale = AppDimensions.tableCompactFixedColumnFactor;
  return {
    for (final e in widths.entries)
      e.key: e.value is FixedColumnWidth
          ? FixedColumnWidth((e.value as FixedColumnWidth).value * scale)
          : e.value,
  };
}

/// ERP 목록 테이블 **헤더 행** 공통 데코 — 라이트 헤더(01_design_system.md §4 테이블).
const BoxDecoration kErpTableHeaderRowDecoration = BoxDecoration(
  color: AppTheme.tableHeaderBackground,
  border: Border(bottom: BorderSide(color: AppTheme.tableHeaderBorder)),
);

/// ERP 목록 [Table] 셀 내부 격자(가·세) — [ErpDataTable] 본문과 동일 톤.
const TableBorder kErpTableInnerGridBorder = TableBorder(
  horizontalInside: BorderSide(color: AppTheme.tableRowBorder, width: 1),
  verticalInside: BorderSide(color: AppTheme.tableRowBorder, width: 1),
);

/// 관리 리스트 화면에서 반복적으로 사용하던 테이블 래퍼.
///
/// - 모서리 라운드 + 경계선을 가진 박스
/// - `LayoutBuilder` 로 동적 너비 계산 (좁은 화면에선 [minWidth], 넓을 때는 확장)
/// - 가로 바깥 + 세로 안쪽 `SingleChildScrollView` 2단(넓은 표·긴 표 모두 대응)
/// - 실제 테이블은 [tableBuilder] 로 주입 (column widths / header / rows 는 호출부에서 구성)
///
/// 각 화면은 이제 스크롤/프레임 로직을 복제하지 않고 컬럼 정의와 행만 제공하면 된다.
String formatPhoneNumber(String number) {
  if (number.length == 10) {
    return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
  } else if (number.length == 11) {
    return '${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
  }
  return number;
}

class ErpDataTable extends StatefulWidget {
  const ErpDataTable({
    super.key,
    required this.tableBuilder,
    this.minWidth = AppDimensions.tableMinWidthStandard,
  });

  /// 주어진 가로 폭(= 좁은 화면의 [minWidth] 또는 현재 제약의 `maxWidth`)에서
  /// 실제 `Table` 위젯을 구성하는 빌더.
  final Widget Function(BuildContext context, double width) tableBuilder;

  /// 이 테이블이 가질 최소 가로 폭. 화면이 더 넓으면 자동 확장된다.
  final double minWidth;

  @override
  State<ErpDataTable> createState() => _ErpDataTableState();
}

class _ErpDataTableState extends State<ErpDataTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 상단은 목록 카드 흰 배경과 한 덩어리처럼 보이도록 테두리 생략.
          border: const Border(
            left: BorderSide(color: AppTheme.hairline),
            right: BorderSide(color: AppTheme.hairline),
            bottom: BorderSide(color: AppTheme.hairline),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 화면보다 넓은 표는 [minWidth] 기준. 가로 스크롤을 **밖**에 두어
            // 터치/트랙패드/웹에서 세로·가로 제스처가 둘 다 동작하도록 한다.
            final maxW = constraints.maxWidth;
            final minW = erpTableMinWidth(context, widget.minWidth);
            final viewportW = maxW.isFinite ? maxW : minW;
            final width = viewportW > minW ? viewportW : minW;
            return Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  primary: false,
                  child: SizedBox(
                    width: width,
                    child: widget.tableBuilder(context, width),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

const TableBorder _kErpVirtualDataTableRowBorder = TableBorder(
  verticalInside: BorderSide(color: AppTheme.tableRowBorder, width: 1),
  bottom: BorderSide(color: AppTheme.tableRowBorder, width: 1),
);

class ErpVirtualDataTable extends StatefulWidget {
  const ErpVirtualDataTable({
    super.key,
    required this.columnWidths,
    required this.headerRow,
    required this.rowCount,
    required this.rowBuilder,
    this.minWidth = AppDimensions.tableMinWidthStandard,
  });

  final Map<int, TableColumnWidth> columnWidths;
  final TableRow headerRow;
  final int rowCount;
  final TableRow Function(BuildContext context, int index) rowBuilder;
  final double minWidth;

  @override
  State<ErpVirtualDataTable> createState() => _ErpVirtualDataTableState();
}

class _ErpVirtualDataTableState extends State<ErpVirtualDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: AppTheme.hairline),
            right: BorderSide(color: AppTheme.hairline),
            bottom: BorderSide(color: AppTheme.hairline),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final minW = erpTableMinWidth(context, widget.minWidth);
            final viewportW = maxW.isFinite ? maxW : minW;
            final width = viewportW > minW ? viewportW : minW;
            final columnWidths = erpTableColumnWidths(
              context,
              widget.columnWidths,
            );
            // 가로 [SingleChildScrollView] 안 [Expanded]는 세로 무한 제약 → 모바일에서 본문 0px.
            final tableHeight = constraints.maxHeight.isFinite &&
                    constraints.maxHeight > 0
                ? constraints.maxHeight
                : 360.0;

            return SizedBox(
              height: tableHeight,
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: SizedBox(
                    width: width,
                    height: tableHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: _kErpVirtualDataTableRowBorder,
                          columnWidths: columnWidths,
                          children: [widget.headerRow],
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            interactive: true,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.vertical,
                            child: ListView.builder(
                              controller: _verticalController,
                              primary: false,
                              itemCount: widget.rowCount,
                              itemBuilder: (context, index) {
                                return Table(
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  border: _kErpVirtualDataTableRowBorder,
                                  columnWidths: columnWidths,
                                  children: [
                                    widget.rowBuilder(context, index),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
