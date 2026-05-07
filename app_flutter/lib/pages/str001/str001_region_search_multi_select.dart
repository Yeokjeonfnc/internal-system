// 가맹점 목록 — 지역 필터: 검색 + 체크박스 다중 선택.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';
import 'package:app_flutter/pages/str001/str001_controller.dart';

/// 요약 라벨 (비어 있으면 전체).
String storeRegionFilterSummary(Set<String> regionNms) {
  if (regionNms.isEmpty) return '전체';
  if (regionNms.length == 1) return regionNms.first;
  return '${regionNms.length}개 지역';
}

/// 드롭다운과 동일한 외형의 트리거.
class StoreRegionSearchMultiSelectField extends StatelessWidget {
  const StoreRegionSearchMultiSelectField({
    super.key,
    required this.summaryText,
    required this.onTap,
  });

  final String summaryText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 168, maxWidth: 260),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: searchFilterDropdownDecoration(compact: false).copyWith(
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                  size: 22,
                ),
              ),
              child: Text(
                summaryText,
                style: kSearchFilterValueTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showStoreRegionPickDialog({
  required BuildContext context,
  required List<String> regionOptions,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref2, _) {
          final selected = ref2.watch(storeProvider).regionNms;
          final notifier = ref2.read(storeProvider.notifier);
          return Theme(
            data: Theme.of(ctx).copyWith(
              checkboxTheme: CheckboxThemeData(
                side: const BorderSide(color: Color(0xFF9CA3AF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            child: AlertDialog(
              title: const Text(
                '지역',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.koreanFontFallback,
                ),
              ),
              content: SizedBox(
                width: 360,
                height: 420,
                child: _RegionPickDialogBody(
                  options: regionOptions,
                  selected: selected,
                  onToggle: notifier.toggleRegion,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _RegionPickDialogBody extends StatefulWidget {
  const _RegionPickDialogBody({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<_RegionPickDialogBody> createState() => _RegionPickDialogBodyState();
}

class _RegionPickDialogBodyState extends State<_RegionPickDialogBody> {
  late final TextEditingController _queryCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _queryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _queryCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((e) => e.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _queryCtrl,
          style: kSearchFilterValueTextStyle,
          decoration: InputDecoration(
            isDense: true,
            hintText: '검색...',
            hintStyle: TextStyle(
              fontSize: kSearchFilterFontSize,
              color: kSearchFilterHintColor,
              fontFamilyFallback: AppTheme.koreanFontFallback,
            ),
            suffixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade600,
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    widget.options.isEmpty
                        ? '등록된 지역이 없습니다.'
                        : '검색 결과가 없습니다.',
                    style: TextStyle(
                      fontSize: kSearchFilterFontSize,
                      color: kSearchFilterHintColor,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemExtent: kMinInteractiveDimension,
                    itemBuilder: (context, i) {
                      final name = filtered[i];
                      final checked = widget.selected.contains(name);
                      return CheckboxListTile(
                        tileColor: erpPopupListRowBackground(i),
                        value: checked,
                        onChanged: (_) => widget.onToggle(name),
                        title: Text(
                          name,
                          style: kSearchFilterValueTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
