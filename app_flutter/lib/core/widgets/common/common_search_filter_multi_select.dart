// 검색 필터용: 드롭다운 형태 트리거 + 검색 + 체크박스 다중 선택 다이얼로그.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/theme/app_colors.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/core/widgets/common/erp_popup_list_stripes.dart';

/// 다중 선택 요약 라벨.
///
/// [formatMultiple]을 주면 2개 이상일 때 **선택 집합**으로 그 형식을 쓰고,
/// 생략 시 `'$count개'`만 표시한다.
///
/// (과거에 개수만 넘기고 옵션 목록 `take(n)`으로 찍던 방식은 선택 이름과 어긋난다.)
String searchFilterMultiSelectSummary(
  Set<String> selected, {
  String emptyLabel = '전체',
  String Function(Set<String> selected)? formatMultiple,
}) {
  if (selected.isEmpty) return emptyLabel;
  if (selected.length == 1) return selected.first;
  final n = selected.length;
  return formatMultiple?.call(selected) ?? '$n개';
}

/// 정렬 후 앞 3개까지 나열하고, 그 이상이면 `외 n건` (필터 칩과 비슷한 톤).
String searchFilterMultiSelectSummarySortedPreview(Set<String> selected) {
  if (selected.isEmpty) return '';
  final sorted = selected.toList()..sort();
  if (sorted.length <= 4) return sorted.join(', ');
  return '${sorted.take(4).join(', ')} 외 ${sorted.length - 4}건';
}

/// 드롭다운과 동일한 외형의 다중 선택 트리거.
class SearchFilterMultiSelectField extends StatelessWidget {
  const SearchFilterMultiSelectField({
    super.key,
    required this.summaryText,
    required this.onTap,
    this.minWidth = 168,
    this.maxWidth = 260,
  });

  final String summaryText;
  final VoidCallback onTap;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: searchFilterDropdownDecoration(compact: false)
                  .copyWith(
                    suffixIcon: const Icon(
                      Icons.search_rounded,
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

/// 검색 + 체크 목록 본문 (`AlertDialog`의 `content` 등에 넣어 사용).
class SearchFilterMultiPickDialogBody extends StatefulWidget {
  const SearchFilterMultiPickDialogBody({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.searchHint = '검색해주세요',
    this.emptyOptionsMessage = '등록된 항목이 없습니다.',
    this.emptySearchMessage = '검색 결과가 없습니다.',
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String searchHint;
  final String emptyOptionsMessage;
  final String emptySearchMessage;

  @override
  State<SearchFilterMultiPickDialogBody> createState() =>
      _SearchFilterMultiPickDialogBodyState();
}

class _SearchFilterMultiPickDialogBodyState
    extends State<SearchFilterMultiPickDialogBody> {
  late final TextEditingController _queryCtrl;
  late final ScrollController _listScrollCtrl;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _queryCtrl.addListener(() => setState(() {}));
    _listScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _listScrollCtrl.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _queryCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((e) => e.toLowerCase().contains(q)).toList();
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
            hintText: widget.searchHint,
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
              borderSide: const BorderSide(
                color: Color(0xFFBC1F26),
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    widget.options.isEmpty
                        ? widget.emptyOptionsMessage
                        : widget.emptySearchMessage,
                    style: TextStyle(
                      fontSize: kSearchFilterFontSize,
                      color: kSearchFilterHintColor,
                      fontFamilyFallback: AppTheme.koreanFontFallback,
                    ),
                  ),
                )
              : Scrollbar(
                  controller: _listScrollCtrl,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _listScrollCtrl,
                    primary: false,
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

/// [WidgetRef]로 [selected]·[onToggle]을 만들 때 쓰는 묶음 (지역 다중 선택 등).
class SearchFilterMultiPickBindings {
  const SearchFilterMultiPickBindings({
    required this.selected,
    required this.onToggle,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
}

/// [SearchFilterMultiPickDialog]를 [ref] 구독과 함께 빌드한다.
///
/// [showSearchFilterMultiPickDialogWithRef]에서 쓰거나, 직접 `showDialog`의 `builder`에 넣어도 된다.
class SearchFilterMultiPickDialogScope extends ConsumerWidget {
  const SearchFilterMultiPickDialogScope({
    super.key,
    required this.options,
    required this.bindings,
    this.title = '검색',
    this.searchHint = '검색해주세요',
    this.emptyOptionsMessage = '등록된 항목이 없습니다.',
    this.emptySearchMessage = '검색 결과가 없습니다.',
    this.closeLabel = '닫기',
    this.contentWidth = 360,
    this.contentHeight = 420,
  });

  final List<String> options;
  final SearchFilterMultiPickBindings Function(WidgetRef ref) bindings;
  final String title;
  final String searchHint;
  final String emptyOptionsMessage;
  final String emptySearchMessage;
  final String closeLabel;
  final double contentWidth;
  final double contentHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bindings(ref);
    return SearchFilterMultiPickDialog(
      options: options,
      selected: b.selected,
      onToggle: b.onToggle,
      title: title,
      searchHint: searchHint,
      emptyOptionsMessage: emptyOptionsMessage,
      emptySearchMessage: emptySearchMessage,
      closeLabel: closeLabel,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    );
  }
}

/// 체크박스 테마가 적용된 `AlertDialog` 래퍼.
///
/// 선택 상태가 바깥(예: Riverpod)과 즉시 동기되게 하려면 [showSearchFilterMultiPickDialogWithRef] 또는
/// [SearchFilterMultiPickDialogScope]를 쓴다.
class SearchFilterMultiPickDialog extends StatelessWidget {
  const SearchFilterMultiPickDialog({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.title = '검색',
    this.searchHint = '검색해주세요',
    this.emptyOptionsMessage = '등록된 항목이 없습니다.',
    this.emptySearchMessage = '검색 결과가 없습니다.',
    this.closeLabel = '닫기',
    this.contentWidth = 360,
    this.contentHeight = 420,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String title;
  final String searchHint;
  final String emptyOptionsMessage;
  final String emptySearchMessage;
  final String closeLabel;
  final double contentWidth;
  final double contentHeight;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          side: const BorderSide(color: Color(0xFF9CA3AF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: AlertDialog(
        title: Text(
          textAlign: TextAlign.center,
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: AppTheme.koreanFontFallback,
          ),
        ),
        content: SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: SearchFilterMultiPickDialogBody(
            options: options,
            selected: selected,
            onToggle: onToggle,
            searchHint: searchHint,
            emptyOptionsMessage: emptyOptionsMessage,
            emptySearchMessage: emptySearchMessage,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}

/// [SearchFilterMultiPickDialog]를 띄운다.
///
/// [selected]가 고정이면 이 함수로 충분하고, Riverpod 등으로 매 프레임 갱신되면
/// [showSearchFilterMultiPickDialogWithRef]를 쓴다.
Future<void> showSearchFilterMultiPickDialog({
  required BuildContext context,
  required List<String> options,
  required Set<String> selected,
  required ValueChanged<String> onToggle,
  String title = '검색',
  String searchHint = '검색해주세요',
  String emptyOptionsMessage = '등록된 항목이 없습니다.',
  String emptySearchMessage = '검색 결과가 없습니다.',
  String closeLabel = '닫기',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => SearchFilterMultiPickDialog(
      options: options,
      selected: selected,
      onToggle: onToggle,
      title: title,
      searchHint: searchHint,
      emptyOptionsMessage: emptyOptionsMessage,
      emptySearchMessage: emptySearchMessage,
      closeLabel: closeLabel,
    ),
  );
}

/// [SearchFilterMultiPickDialogScope]로 다이얼로그를 띄운다 (선택·토글이 [Ref]와 동기).
Future<void> showDialogWithRef({
  required BuildContext context,
  required List<String> options,
  required SearchFilterMultiPickBindings Function(WidgetRef ref) bindings,
  String title = '검색',
  String searchHint = '검색해주세요',
  String emptyOptionsMessage = '등록된 항목이 없습니다.',
  String emptySearchMessage = '검색 결과가 없습니다.',
  String closeLabel = '닫기',
  double contentWidth = 360,
  double contentHeight = 420,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => SearchFilterMultiPickDialogScope(
      options: options,
      bindings: bindings,
      title: title,
      searchHint: searchHint,
      emptyOptionsMessage: emptyOptionsMessage,
      emptySearchMessage: emptySearchMessage,
      closeLabel: closeLabel,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    ),
  );
}
