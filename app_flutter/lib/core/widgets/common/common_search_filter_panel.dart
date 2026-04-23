// 검색·필터 패널 공통 타이포·색 토큰.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';

/// 검색 필터 패널 내부 요소들이 공유하는 공통 텍스트 크기/색상.
///
/// 라벨 · 입력값 · placeholder · 드롭다운 값 모두 이 값을 기준으로 통일합니다.
const double kSearchFilterFontSize = 14;
const Color kSearchFilterTextColor = Color(0xFF212529);
const Color kSearchFilterHintColor = Color(0xFF9CA3AF);

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
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBC1F26), width: 1.2),
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
  });

  /// 같은 값이 다른 필드와 겹칠 때 [ValueKey] 충돌을 피하기 위한 라벨(예: `평가상태`).
  final String fieldLabel;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?>? onChanged;

  /// `true`이면 가로·세로를 줄여 **한 줄** 검색 행(활동일자 등)에 맞춘다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
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
          minWidth: compact ? 90 : 168,
          maxWidth: compact ? 116 : 260,
        ),
        child: DropdownButtonFormField<T?>(
          key: ValueKey<String>(fieldLabel),
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
            color: const Color(0xFF6B7280),
            size: compact ? 20 : 22,
          ),
          items: items,
          onChanged: onChanged,
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
/// - 가로 **900px 이상**: 한 줄에 **필드 2개**([_SearchFilterItem] 2개를 `Row`로).
/// - 좁은 화면: 기존처럼 **한 열** 세로 쌓기 ([SearchFilterPanel] 과 동일 900px 기준).
class SearchFilterStackedItems extends StatelessWidget {
  const SearchFilterStackedItems({super.key, required this.items});

  final List<SearchFilterItemData> items;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final filterTheme = _searchFilterPanelTheme(baseTheme);
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
                  _SearchFilterItem(data: items[i]),
                  if (i != items.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 8),
                if (i + 1 < items.length)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SearchFilterItem(data: items[i])),
                      const SizedBox(width: 10),
                      Expanded(child: _SearchFilterItem(data: items[i + 1])),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SearchFilterItem(data: items[i])),
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
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isPhoneNumber;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: isPhoneNumber ? _formatPhoneNumber : onChanged,
      decoration: searchFilterFieldDecoration(hint: hint),
      style: kSearchFilterValueTextStyle,
      keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
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

InputDecoration searchFilterFieldDecoration({String? hint}) => InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: const TextStyle(
    fontSize: kSearchFilterFontSize,
    color: kSearchFilterHintColor,
    fontFamilyFallback: AppTheme.koreanFontFallback,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  constraints: const BoxConstraints(minHeight: 32, maxHeight: 32),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
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
          _SearchFilterItem(data: data.left),
          const SizedBox(height: 8),
          _SearchFilterItem(data: data.right),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _SearchFilterItem(data: data.left)),
        const SizedBox(width: 10),
        Expanded(child: _SearchFilterItem(data: data.right)),
      ],
    );
  }
}

class _SearchFilterItem extends StatelessWidget {
  const _SearchFilterItem({required this.data});

  final SearchFilterItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              data.label.isEmpty ? '\u00a0' : data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: kSearchFilterFontSize,
                color: kSearchFilterTextColor,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
          ),
          Expanded(child: data.child),
        ],
      ),
    );
  }
}
