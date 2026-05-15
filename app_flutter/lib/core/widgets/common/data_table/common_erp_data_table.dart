// ERP 스타일 가로 스크롤 테이블 래퍼.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_dimensions.dart';

/// ERP 목록 [Table] 셀 내부 격자(가·세) — [ErpDataTable] 본문과 동일 톤.
const TableBorder kErpTableInnerGridBorder = TableBorder(
  horizontalInside: BorderSide(color: Color(0xFFE2E5EB), width: 1),
  verticalInside: BorderSide(color: Color(0xFFE2E5EB), width: 1),
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
    this.minWidth = AppDimensions.tableMinWidthDefault,
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
            left: BorderSide(color: Color(0xFFE2E5EB)),
            right: BorderSide(color: Color(0xFFE2E5EB)),
            bottom: BorderSide(color: Color(0xFFE2E5EB)),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.tableRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 화면보다 넓은 표는 [minWidth] 기준. 가로 스크롤을 **밖**에 두어
            // 터치/트랙패드/웹에서 세로·가로 제스처가 둘 다 동작하도록 한다.
            final maxW = constraints.maxWidth;
            final viewportW = maxW.isFinite ? maxW : widget.minWidth;
            final width = viewportW > widget.minWidth
                ? viewportW
                : widget.minWidth;
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
