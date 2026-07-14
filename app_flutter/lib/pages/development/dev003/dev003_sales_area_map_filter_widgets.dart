import 'package:flutter/material.dart';

import 'package:app_flutter/core/api/code_option.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/development/dev003/map/sales_area_editor_view_options.dart';

String? salesAreaNormalizeBrandCode(String? raw, List<CodeOption> options) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  for (final o in options) {
    if (o.codeCd.trim() == trimmed) return o.codeCd;
  }
  final stripped = trimmed.replaceFirst(RegExp(r'^0+'), '');
  for (final o in options) {
    final code = o.codeCd.trim();
    if (code.replaceFirst(RegExp(r'^0+'), '') == stripped) return o.codeCd;
  }
  return trimmed;
}

String salesAreaBrandOptionLabel(CodeOption option) {
  final radius = SalesAreaEditorMapMath.referenceRadiusMeters(option.codeNm);
  if (RegExp(r'\d+\s*m', caseSensitive: false).hasMatch(option.codeNm)) {
    return option.codeNm;
  }
  return '${option.codeNm} - ${radius}m';
}

String salesAreaBrandDisplayLabel({
  required String? selectedBrandCd,
  required List<CodeOption> brandOptions,
  required String fallbackBrandLabel,
}) {
  final cd = selectedBrandCd?.trim();
  if (cd == null || cd.isEmpty) return '선택';
  for (final o in brandOptions) {
    if (o.codeCd == cd) return salesAreaBrandOptionLabel(o);
  }
  final name = fallbackBrandLabel.trim();
  if (name.isNotEmpty && name != '-') return name;
  return cd;
}

/// Web: 드롭다운·Dialog는 지도 iframe에 가려짐 → 가로 칩(주소 옆)으로 직접 탭.
class SalesAreaBrandOptionList extends StatelessWidget {
  const SalesAreaBrandOptionList({
    super.key,
    required this.brandOptions,
    required this.selectedBrandCd,
    required this.fallbackBrandLabel,
    required this.isLoading,
    required this.loadFailed,
    required this.onChanged,
    this.horizontal = false,
  });

  final List<CodeOption> brandOptions;
  final String? selectedBrandCd;
  final String fallbackBrandLabel;
  final bool isLoading;
  final bool loadFailed;
  final ValueChanged<String?> onChanged;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (loadFailed) {
      return Text(
        '코드 조회 실패',
        style: kSearchFilterValueTextStyle.copyWith(
          color: kSearchFilterHintColor,
        ),
      );
    }

    final cd = selectedBrandCd?.trim();
    final seen = brandOptions.map((e) => e.codeCd).toSet();
    final tiles = <Widget>[
      _brandOptionButton(
        title: '선택',
        codeCd: null,
        selected: cd == null || cd.isEmpty,
        muted: true,
        compact: horizontal,
      ),
      for (final option in brandOptions)
        _brandOptionButton(
          title: salesAreaBrandOptionLabel(option),
          codeCd: option.codeCd,
          selected: option.codeCd == cd,
          compact: horizontal,
        ),
      if (cd != null && cd.isNotEmpty && !seen.contains(cd))
        _brandOptionButton(
          title: salesAreaBrandDisplayLabel(
            selectedBrandCd: cd,
            brandOptions: brandOptions,
            fallbackBrandLabel: fallbackBrandLabel,
          ),
          codeCd: cd,
          selected: true,
          compact: horizontal,
        ),
    ];

    if (horizontal) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tiles,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tiles,
    );
  }

  Widget _brandOptionButton({
    required String title,
    required String? codeCd,
    required bool selected,
    bool muted = false,
    bool compact = false,
  }) {
    final border = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected ? AppTheme.accentRed : const Color(0xFFE5E7EB),
        width: selected ? 1.5 : 1,
      ),
      color: selected ? const Color(0xFFFFF1F2) : Colors.white,
    );

    final child = InkWell(
      onTap: () {
        if (codeCd == selectedBrandCd) return;
        onChanged(codeCd);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: border,
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: selected,
                onChanged: (_) {
                  if (codeCd == selectedBrandCd) return;
                  onChanged(codeCd);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: kSearchFilterValueTextStyle.copyWith(
                  fontSize: compact ? 12 : 13,
                  color: muted
                      ? kSearchFilterHintColor
                      : selected
                      ? AppTheme.accentRed
                      : kSearchFilterTextColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (compact) return child;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class SalesAreaViewOptionCheck extends StatelessWidget {
  const SalesAreaViewOptionCheck({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: AppTheme.accentRed,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ],
    );
  }
}

class SalesAreaMapViewOptionsBar extends StatelessWidget {
  const SalesAreaMapViewOptionsBar({
    super.key,
    required this.viewOptionChecks,
    this.horizontal = true,
  });

  final List<Widget> viewOptionChecks;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (viewOptionChecks.isEmpty) return const SizedBox.shrink();

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < viewOptionChecks.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              viewOptionChecks[i],
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: viewOptionChecks,
    );
  }
}

/// 등록·검색 지도 상단 — 주소 키워드 검색 + 보기 옵션.
class SalesAreaMapAddressFilterBar extends StatelessWidget {
  const SalesAreaMapAddressFilterBar({
    super.key,
    this.readOnly = false,
    this.showAddress = true,
    this.viewOptionsHorizontal = false,
    required this.addressController,
    required this.addressHint,
    required this.onAddressSearch,
    required this.brandOptions,
    required this.selectedBrandCd,
    required this.fallbackBrandLabel,
    required this.brandsLoading,
    required this.brandsLoadFailed,
    required this.onBrandChanged,
    required this.viewOptionChecks,
  });

  final bool readOnly;
  /// false 이면 주소 입력·검색 행을 숨김 (영업지역 검색 앱 등).
  final bool showAddress;
  /// true 이면 체크박스를 주소 아래(또는 단독) 가로 한 줄로 배치.
  final bool viewOptionsHorizontal;
  final TextEditingController addressController;
  final String addressHint;
  final VoidCallback onAddressSearch;
  final List<CodeOption> brandOptions;
  final String? selectedBrandCd;
  final String fallbackBrandLabel;
  final bool brandsLoading;
  final bool brandsLoadFailed;
  final ValueChanged<String?> onBrandChanged;
  final List<Widget> viewOptionChecks;

  Widget _buildViewOptions() {
    return SalesAreaMapViewOptionsBar(
      viewOptionChecks: viewOptionChecks,
      horizontal: viewOptionsHorizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showAddress && viewOptionChecks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAddress)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '주소',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kSearchFilterTextColor,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressController,
                      readOnly: readOnly,
                      onSubmitted: readOnly ? null : (_) => onAddressSearch(),
                      decoration: searchFilterFieldDecoration(
                        hint: addressHint,
                        borderRadius: 6,
                      ),
                      style: kSearchFilterValueTextStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: readOnly ? null : onAddressSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('검색'),
                  ),
                  if (!viewOptionsHorizontal && viewOptionChecks.isNotEmpty) ...[
                    const SizedBox(width: 30),
                    Flexible(child: _buildViewOptions()),
                  ],
                ],
              ),
            ],
          ),
        if (viewOptionsHorizontal && viewOptionChecks.isNotEmpty) ...[
          if (showAddress) const SizedBox(height: 8),
          _buildViewOptions(),
        ],
      ],
    );
  }
}
