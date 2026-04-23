// 목록에 적용된 검색 조건을 칩으로 요약해 보여준다.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/theme/form_style_palette.dart';

/// 메인 화면에 표시할 **적용 중 검색 조건** 한 칩.
class ActiveFilterChip {
  const ActiveFilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;
}

/// [ActiveFilterChip] 들을 가로 스크롤 + 삭제 가능 칩으로 나열한다.
class ActiveFilterChipsBar extends StatelessWidget {
  const ActiveFilterChipsBar({super.key, required this.chips});

  final List<ActiveFilterChip> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return Text(
        '적용된 검색 조건이 없습니다.',
        style: TextStyle(
          color: FormStylePalette.textMuted,
          fontSize: 13,
          fontFamilyFallback: AppTheme.koreanFontFallback,
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: InputChip(
                label: Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: Color.fromARGB(255, 236, 110, 110),
                    fontFamilyFallback: AppTheme.koreanFontFallback,
                  ),
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: const Color.fromARGB(
                    255,
                    236,
                    110,
                    110,
                  ).withValues(alpha: 0.9),
                ),
                onDeleted: c.onClear,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Color(0xFFFECDD3)),
                backgroundColor: const Color.fromARGB(255, 255, 241, 242),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
