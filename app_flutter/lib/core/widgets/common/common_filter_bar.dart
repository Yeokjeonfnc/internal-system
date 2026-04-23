// 목록 상단 2열 검색·드롭다운 필터 슬롯 — [CommonFilterBar] 및 Filter* 슬롯.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';

/// 이 개수 이하의 문자열 옵션이면 드롭다운 대신 가로 칩(클릭 선택)으로 표시한다.
const int kFilterStringChipMaxCount = 5;

/// 검색 필터 한 칸(라벨 + 필드)을 [SearchFilterItemData]로 변환한다.
abstract class FilterSlotConfig {
  SearchFilterItemData toItem();
}

/// 공통 스타일 텍스트 검색.
class FilterTextSlot extends FilterSlotConfig {
  FilterTextSlot({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.isPhoneNumber = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isPhoneNumber;

  @override
  SearchFilterItemData toItem() => SearchFilterItemData(
    label: label,
    child: SearchFilterTextField(
      controller: controller,
      hint: hint,
      onChanged: onChanged,
      isPhoneNumber: isPhoneNumber,
    ),
  );
}

/// 문자열 목록 드롭다운 (지역·브랜드 등).
class FilterStringOptionsSlot extends FilterSlotConfig {
  FilterStringOptionsSlot({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.forceDropdown = false,
  });

  final String label;
  final String value;
  final List<String> options;
  final void Function(String value) onSelected;

  /// true이면 옵션 개수와 관계없이 항상 드롭다운(예: 지역).
  final bool forceDropdown;

  @override
  SearchFilterItemData toItem() {
    if (!forceDropdown && options.length <= kFilterStringChipMaxCount) {
      return SearchFilterItemData(
        label: label,
        child: _StringChoiceChipsRow(
          options: options,
          selected: value,
          onSelected: onSelected,
        ),
      );
    }
    return SearchFilterItemData(
      label: label,
      child: SearchFilterDropdownField<String>(
        fieldLabel: label,
        value: value,
        items: [
          for (final e in options)
            DropdownMenuItem<String?>(
              value: e,
              child: Text(e, style: kSearchFilterValueTextStyle),
            ),
        ],
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
      ),
    );
  }
}

/// 임의 타입 드롭다운 (`null` = 전체 등).
class FilterDropdownSlot<T> extends FilterSlotConfig {
  FilterDropdownSlot({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;

  @override
  SearchFilterItemData toItem() => SearchFilterItemData(
    label: label,
    child: SearchFilterDropdownField<T>(
      fieldLabel: label,
      value: value,
      items: items,
      onChanged: onChanged,
    ),
  );
}

/// 우측/좌측 빈 칸.
class FilterEmptySlot extends FilterSlotConfig {
  @override
  SearchFilterItemData toItem() =>
      const SearchFilterItemData(label: '', child: SizedBox.shrink());
}

/// 한 줄 = 좌·우 두 칸 설정.
class FilterRowConfig {
  const FilterRowConfig({required this.left, required this.right});

  final FilterSlotConfig left;
  final FilterSlotConfig right;
}

class _StringChoiceChipsRow extends StatelessWidget {
  const _StringChoiceChipsRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final void Function(String value) onSelected;

  static const Color _selBg = Color(0xFFFFF1F2);
  static const Color _selBorder = AppTheme.accentRed;
  static const Color _unBorder = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(
              o,
              style: TextStyle(
                fontSize: kSearchFilterFontSize,
                fontWeight: selected == o ? FontWeight.w700 : FontWeight.w500,
                color: selected == o
                    ? AppTheme.accentRed
                    : kSearchFilterTextColor,
                fontFamilyFallback: AppTheme.koreanFontFallback,
              ),
            ),
            selected: selected == o,
            onSelected: (_) => onSelected(o),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            selectedColor: _selBg,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected == o ? _selBorder : _unBorder,
              width: selected == o ? 1.4 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          ),
      ],
    );
  }
}

/// 목록 화면 상단 검색조건 공통 바 ([SearchFilterPanel] 래퍼).
class CommonFilterBar extends StatelessWidget {
  const CommonFilterBar({super.key, required this.rows});

  final List<FilterRowConfig> rows;

  @override
  Widget build(BuildContext context) {
    return SearchFilterPanel(
      rows: [
        for (final r in rows)
          SearchFilterRowData(left: r.left.toItem(), right: r.right.toItem()),
      ],
    );
  }
}
