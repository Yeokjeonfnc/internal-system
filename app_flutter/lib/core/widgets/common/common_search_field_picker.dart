// 공통 검색 조건 시트: 구역별 제목 + 항목 토글.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/search/common_search_field_catalog.dart';
import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 필터 시트 본문 — [supported]에 있는 항목만 나열하고, [visible]에 따라 체크 상태를 표시한다.
class CommonSearchFieldPicker extends StatelessWidget {
  const CommonSearchFieldPicker({
    super.key,
    required this.supported,
    required this.visible,
    required this.onToggle,
    this.title = '검색 조건',
    this.description = '항목을 누르면 아래 본문 카드에 검색 칸이 나타납니다. 다시 누르면 제거됩니다.',
  });

  final Set<CommonSearchFieldId> supported;
  final Set<CommonSearchFieldId> visible;
  final void Function(CommonSearchFieldId id, bool nowVisible) onToggle;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 구분선은 [showListFilterEndSheet] 헤더 아래 한 줄만 둔다(이중 선 방지).
        for (final group in CommonSearchFieldGroup.values) ...[
          ..._sectionForGroup(context, group),
        ],
      ],
    );
  }

  List<Widget> _sectionForGroup(
    BuildContext context,
    CommonSearchFieldGroup group,
  ) {
    final defs = commonSearchDefsInGroup(supported, group);
    if (defs.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          commonSearchGroupTitle(group),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FormStylePalette.textMuted,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
      ),
      for (final def in defs) _tile(context, def),
    ];
  }

  Widget _tile(BuildContext context, CommonSearchFieldDef def) {
    final onMain = visible.contains(def.id);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        onMain ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
        color: onMain ? FormStylePalette.accent : FormStylePalette.textMuted,
        size: 22,
      ),
      title: Text(
        def.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: onMain ? FontWeight.w700 : FontWeight.w500,
          color: FormStylePalette.textPrimary,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      subtitle: Text(
        onMain ? '본문에서 제거하려면 다시 누르세요.' : '본문에 검색 칸을 추가합니다.',
        style: const TextStyle(
          fontSize: 11,
          color: FormStylePalette.textMuted,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      ),
      onTap: () => onToggle(def.id, !onMain),
    );
  }
}
