// 검색·필터 패널 공통 타이포·색 토큰.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 검색 필터 패널 내부 요소들이 공유하는 공통 텍스트 크기/색상.
///
/// 라벨 · 입력값 · placeholder · 드롭다운 값 모두 이 값을 기준으로 통일합니다.
const double kSearchFilterFontSize = 14;
const double kSearchFilterFieldHeight = 36;
const Color kSearchFilterTextColor = AppTheme.textPrimary;
const Color kSearchFilterHintColor = AppTheme.textPlaceholder;

/// 드롭다운 `style` 파라미터에 그대로 전달해 쓰는 공통 텍스트 스타일.
const TextStyle kSearchFilterValueTextStyle = TextStyle(
  fontSize: kSearchFilterFontSize,
  color: kSearchFilterTextColor,
  fontFamilyFallback: AppTheme.koreanFontFallback,
);

/// 검색 필터 드롭다운 메뉴(둥근 모서리·단일 그림자, 바깥 테두리선 없음).
final MenuStyle kSearchFilterDropdownMenuStyle = MenuStyle(
  backgroundColor: WidgetStateProperty.all(Colors.white),
  elevation: WidgetStateProperty.all(12.0),
  shadowColor: WidgetStateProperty.all(const Color(0x30000000)),
  surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
  shape: WidgetStateProperty.all(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  side: WidgetStateProperty.all(BorderSide.none),
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
);

InputDecoration searchFilterDropdownDecoration({bool compact = false}) =>
    InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      constraints: BoxConstraints(
        minHeight: compact ? 32 : 36,
        maxHeight: compact ? 32 : 36,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.4),
      ),
    );

/// 검색 필터 한 칸 안의 드롭다운(필드·팝업 메뉴 스타일 통일, 과한 가로폭 완화).
class SearchFilterDropdownField<T> extends StatelessWidget {
  const SearchFilterDropdownField({
    super.key,
    required this.fieldLabel,
    required this.value,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.isLoading = false,
    this.loadFailed = false,
  });

  /// 같은 값이 다른 필드와 겹칠 때 [ValueKey] 충돌을 피하기 위한 라벨(예: `평가상태`).
  final String fieldLabel;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?>? onChanged;

  /// `true`이면 가로·세로를 줄여 **한 줄** 검색 행(활동일자 등)에 맞춘다.
  final bool compact;

  /// 공통코드 API 로딩 중 — 드롭다운 자리를 유지한다.
  final bool isLoading;

  /// `/codes` 등 조회 실패 — 안내 문구 표시.
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _placeholderBox(
        compact: compact,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (loadFailed) {
      return _placeholderBox(
        compact: compact,
        child: Text(
          '코드 조회 실패',
          style: kSearchFilterValueTextStyle.copyWith(
            color: kSearchFilterHintColor,
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return _placeholderBox(
        compact: compact,
        child: Text(
          '항목 없음',
          style: kSearchFilterValueTextStyle.copyWith(
            color: kSearchFilterHintColor,
          ),
        ),
      );
    }
    final allowed = items.map((DropdownMenuItem<T?> e) => e.value).toList();
    final T? resolved = allowed.contains(value) ? value : allowed.first;

    if (onChanged != null && !allowed.contains(value)) {
      final sync = resolved;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        onChanged!(sync);
      });
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: compact ? 80 : 168,
          maxWidth: compact ? 130 : 260,
        ),
        child: DropdownButtonFormField<T?>(
          key: ValueKey<String>('$fieldLabel-${items.length}-$resolved'),
          initialValue: resolved,
          isExpanded: true,
          isDense: true,
          style: kSearchFilterValueTextStyle,
          decoration: searchFilterDropdownDecoration(compact: compact),
          borderRadius: BorderRadius.circular(10),
          dropdownColor: Colors.white,
          // Material: itemHeight == null || itemHeight >= kMinInteractiveDimension (48)
          itemHeight: kMinInteractiveDimension,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textMuted,
            size: compact ? 24 : 22,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _placeholderBox({required bool compact, required Widget child}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: compact ? 80 : 168,
          maxWidth: compact ? 130 : 260,
          minHeight: compact ? 32 : 36,
          maxHeight: compact ? 32 : 36,
        ),
        child: InputDecorator(
          decoration: searchFilterDropdownDecoration(compact: compact),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
  }
}

ThemeData _searchFilterPanelTheme(ThemeData base) {
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      titleMedium: kSearchFilterValueTextStyle,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: kSearchFilterDropdownMenuStyle,
      textStyle: kSearchFilterValueTextStyle,
    ),
  );
}

class SearchFilterPanel extends StatelessWidget {
  const SearchFilterPanel({super.key, required this.rows});

  final List<SearchFilterRowData> rows;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final filterTheme = _searchFilterPanelTheme(baseTheme);
    return Theme(
      data: filterTheme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 900;
          return Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _SearchFilterRow(data: rows[i], narrow: narrow),
                if (i != rows.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 본문 인라인 검색 필드 목록.
///
/// - 가로 **900px 이상**: 한 줄에 [columnsPerRow]개씩 [SearchFilterLabeledItem]을 `Row`로.
/// - 좁은 화면: 기존처럼 **한 열** 세로 쌓기 ([SearchFilterPanel] 과 동일 900px 기준).
class SearchFilterStackedItems extends StatelessWidget {
  const SearchFilterStackedItems({
    super.key,
    required this.items,
    this.columnsPerRow = 2,
  });

  final List<SearchFilterItemData> items;

  /// 넓은 화면에서 한 줄에 배치할 필드 수(기본 2).
  final int columnsPerRow;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final filterTheme = _searchFilterPanelTheme(baseTheme);
    final cols = columnsPerRow < 1 ? 1 : columnsPerRow;
    return Theme(
      data: filterTheme,
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 900;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  SearchFilterLabeledItem(data: items[i]),
                  if (i != items.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i += cols) ...[
                if (i > 0) const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < cols; j++) ...[
                      if (j > 0) const SizedBox(width: 10),
                      if (i + j < items.length)
                        Expanded(
                          child: SearchFilterLabeledItem(data: items[i + j]),
                        )
                      else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SearchFilterRowData {
  const SearchFilterRowData({required this.left, required this.right});

  final SearchFilterItemData left;
  final SearchFilterItemData right;
}

class SearchFilterItemData {
  const SearchFilterItemData({required this.label, required this.child});

  final String label;
  final Widget child;
}

class SearchFilterTextField extends StatelessWidget {
  const SearchFilterTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.isPhoneNumber = false,
    this.prefixIcon,
    this.borderRadius = 4,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isPhoneNumber;
  final Widget? prefixIcon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kSearchFilterFieldHeight,
      child: TextField(
        controller: controller,
        onChanged: isPhoneNumber ? _formatPhoneNumber : onChanged,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.center,
        decoration: searchFilterFieldDecoration(
          hint: hint,
          prefixIcon: prefixIcon,
          borderRadius: borderRadius,
        ),
        style: kSearchFilterValueTextStyle.copyWith(height: 1.0),
        keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
      ),
    );
  }

  void _formatPhoneNumber(String value) {
    // 숫자만 추출
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted;
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      // 8자리 이상: 000-0000-0000 (최대 11자리)
      final mid = digits.length >= 7 ? digits.substring(3, 7) : '';
      final last = digits.length > 7
          ? digits.substring(7, digits.length > 11 ? 11 : digits.length)
          : '';
      formatted = '${digits.substring(0, 3)}-$mid';
      if (last.isNotEmpty) {
        formatted += '-$last';
      }
    }
    // 커서 위치 조정
    final controller = this.controller;
    controller.text = formatted;
    // 커서 위치를 끝으로 이동
    controller.selection = TextSelection.collapsed(offset: formatted.length);
    onChanged(formatted);
  }
}

InputDecoration searchFilterFieldDecoration({
  String? hint,
  Widget? prefixIcon,
  double borderRadius = 4,
}) => InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: const TextStyle(
    fontSize: kSearchFilterFontSize,
    height: 1.0,
    color: kSearchFilterHintColor,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  ),
  prefixIcon: prefixIcon,
  prefixIconConstraints: prefixIcon != null
      ? const BoxConstraints(minWidth: 40, maxHeight: kSearchFilterFieldHeight)
      : null,
  contentPadding: EdgeInsets.symmetric(
    horizontal: prefixIcon != null ? 4 : 8,
    vertical: 0,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadius),
    borderSide: const BorderSide(color: AppTheme.inputBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadius),
    borderSide: const BorderSide(color: AppTheme.inputBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadius),
    borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.4),
  ),
);

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({required this.data, required this.narrow});

  final SearchFilterRowData data;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    if (narrow) {
      return Column(
        children: [
          SearchFilterLabeledItem(data: data.left),
          const SizedBox(height: 8),
          SearchFilterLabeledItem(data: data.right),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: SearchFilterLabeledItem(data: data.left)),
        const SizedBox(width: 10),
        Expanded(child: SearchFilterLabeledItem(data: data.right)),
      ],
    );
  }
}

/// 라벨(140) + 입력 한 칸 — [SearchFilterStackedItems]·커스텀 행에서 재사용.
class SearchFilterLabeledItem extends StatelessWidget {
  const SearchFilterLabeledItem({super.key, required this.data});

  final SearchFilterItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: SizedBox(
        height: kSearchFilterFieldHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  data.label.isEmpty ? '\u00a0' : data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: kSearchFilterFontSize,
                    height: 1.0,
                    color: kSearchFilterTextColor,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
              ),
            ),
            Expanded(child: data.child),
          ],
        ),
      ),
    );
  }
}

/// 본문 인라인 체크박스 — 라벨 오른쪽(영업지역 목록 등).
class SearchFilterInlineCheck extends StatelessWidget {
  const SearchFilterInlineCheck({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: kSearchFilterValueTextStyle.copyWith(
                color: kSearchFilterTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
