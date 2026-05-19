// 조회(Lookup) 다이얼로그 공통 — 모바일 inset·가로 스크롤·열 폭.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/layout/app_compact_layout.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';

/// NO 열 기본 폭.
const double kErpLookupNoWidth = 40;

/// `010-1234-5678` 등 휴대전화 열 고정 폭.
const double kErpLookupTelWidth = 124;

/// 금액·코드 등 좁은 고정 열.
const double kErpLookupMoneyColWidth = 88;

/// 사원 조회 등 중간 테이블 최소 가로.
const double kErpLookupTableMinWidthUser = 520;

/// 예비창업자·짧은 4열 테이블.
const double kErpLookupTableMinWidthPartner = 400;

/// 물건 조회(6열).
const double kErpLookupTableMinWidthProperty = 680;

/// 가맹점 조회(6열: NO 포함).
const double kErpLookupTableMinWidthStore = 720;

/// 물건 조회 — 물건명·주소 열.
const double kErpLookupPropertyNameWidth = 120;
const double kErpLookupPropertyAddressWidth = 220;

/// 가맹점 조회 — NO 제외 데이터 열.
const double kErpLookupStoreBrandWidth = 100;
const double kErpLookupStoreCodeWidth = 120;
const double kErpLookupStoreOwnerWidth = 100;
const double kErpLookupStoreSvWidth = 120;

EdgeInsets erpLookupDialogInset(BuildContext context) {
  return EdgeInsets.all(useCompactErpLayout(context) ? 12 : 28);
}

InputDecoration erpLookupSearchDecoration(String hint) {
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    prefixIcon: const Icon(
      Icons.search_rounded,
      size: 20,
      color: FormStylePalette.textSecondary,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: FormStylePalette.panelBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
    ),
  );
}

/// 조회 다이얼로그 하단 「닫기」.
Widget erpLookupDialogCloseFooter(BuildContext context) {
  return Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('닫기'),
    ),
  );
}

/// [minTableWidth] 미만이면 [child](Row)를 가로 스크롤한다.
class ErpLookupTableBand extends StatelessWidget {
  const ErpLookupTableBand({
    super.key,
    required this.minTableWidth,
    required this.child,
  });

  final double minTableWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth ||
            constraints.maxWidth >= minTableWidth) {
          return child;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minTableWidth, child: child),
        );
      },
    );
  }
}

/// 빨간 헤더 띠 + (필요 시) 가로 스크롤.
class ErpLookupHeaderBar extends StatelessWidget {
  const ErpLookupHeaderBar({
    super.key,
    required this.minTableWidth,
    required this.children,
  });

  final double minTableWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: FormStylePalette.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ErpLookupTableBand(
        minTableWidth: minTableWidth,
        child: Row(children: children),
      ),
    );
  }
}

class ErpLookupHeaderText extends StatelessWidget {
  const ErpLookupHeaderText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: AppTheme.koreanFontFallback,
      ),
    );
  }
}

class ErpLookupBodyText extends StatelessWidget {
  const ErpLookupBodyText(
    this.text, {
    super.key,
    this.textAlign = TextAlign.center,
    this.style,
    this.fontWeight,
  });

  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final base = style ?? FormStylePalette.valueStyle.copyWith(fontSize: 13);
    final resolved = fontWeight != null ? base.copyWith(fontWeight: fontWeight) : base;
    return Text(
      text.isEmpty ? '-' : text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: resolved,
    );
  }
}

/// 줄무늬 배경 + 탭 선택 행.
class ErpLookupListRow extends StatelessWidget {
  const ErpLookupListRow({
    super.key,
    required this.stripeIndex,
    required this.minTableWidth,
    required this.onTap,
    required this.children,
    this.selected = false,
    this.onDoubleTap,
  });

  final int stripeIndex;
  final double minTableWidth;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final bool selected;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? erpPopupListRowBackgroundSelectable(stripeIndex, selected: true)
          : erpPopupListRowBackground(stripeIndex),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ErpLookupTableBand(
            minTableWidth: minTableWidth,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }
}
