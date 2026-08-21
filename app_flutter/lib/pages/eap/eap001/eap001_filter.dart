// 전자결재 문서함 — 키워드 검색.

import 'package:flutter/material.dart';

import 'package:app_flutter/core/theme/app_dimensions.dart';
import 'package:app_flutter/core/widgets/common/common_filter_bar.dart';
import 'package:app_flutter/core/widgets/common/common_search_filter_panel.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

extension EapDocumentSearchX on EapDocument {
  bool matchesKeyword(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return docNum.toLowerCase().contains(lower) ||
        title.toLowerCase().contains(lower) ||
        formCategory.toLowerCase().contains(lower) ||
        formName.toLowerCase().contains(lower) ||
        drafterName.toLowerCase().contains(lower) ||
        drafterDept.toLowerCase().contains(lower) ||
        status.label.contains(q);
  }
}

List<EapDocument> eapDocumentsMatchingKeyword(
  List<EapDocument> docs,
  String keyword,
) {
  final q = keyword.trim();
  if (q.isEmpty) return docs;
  return docs.where((d) => d.matchesKeyword(q)).toList();
}

/// 문서함 목록 상단 키워드 검색 (품의번호·제목·기안자·문서분류).
class EapDocumentSearchBar extends StatelessWidget {
  const EapDocumentSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.listScreenHPadding,
        0,
        AppDimensions.listScreenHPadding,
        8,
      ),
      child: SearchFilterStackedItems(
        items: [
          FilterTextSlot(
            label: '키워드',
            hint: '품의번호·제목·기안자·문서분류',
            controller: controller,
            onChanged: onChanged,
          ).toItem(),
        ],
      ),
    );
  }
}
