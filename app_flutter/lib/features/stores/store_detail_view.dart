// 가맹점 상세 화면(탭·스토어 로드).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/features/stores/store_detail_tabs.dart';
import 'package:app_flutter/features/stores/store_controller.dart';

/// 가맹점 상세 화면.
///
/// 화면 골격은 [DetailScreenWithTabs] 로 통일하고, 탭별 내용은
/// [StoreDetailPanel] 이 담당합니다.
///
/// [isRegisterMode] 가 true이면 API 연동 전까지 데이터 없이 빈 상태로 연다.
/// 존재하지 않는 [storeCode] 로 열었을 때도 동일하게 빈 상태다.
class StoreDetailView extends ConsumerWidget {
  const StoreDetailView({
    super.key,
    this.storeCode = '',
    this.isRegisterMode = false,
  });

  final String storeCode;
  final bool isRegisterMode;

  static const List<String> _tabTitles = [
    '기본정보',
    '계약정보',
    '매출정보',
    '문서정보',
    '히스토리',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = isRegisterMode
        ? null
        : ref.watch(storeRepositoryProvider).find(storeCode);

    /// 등록 모드는 셸 [MainFrameLayout] 상단 배너에 제목이 있으므로 본문 제목(중복 띠)을 생략한다.
    final Widget title;
    if (isRegisterMode) {
      title = const SizedBox.shrink();
    } else if (store != null) {
      title = DetailScreenHeadline.leadTail(
        lead: store.storeName,
        tail: '님 상세 정보',
      );
    } else {
      title = DetailScreenHeadline.plain(text: '가맹점 상세');
    }

    return DetailScreenWithTabs(
      title: title,
      tabTitles: _tabTitles,
      tabPages: [
        for (final title in _tabTitles)
          StoreDetailPanel(title: title, store: store),
      ],
    );
  }
}
