// 가맹점 상세 화면(탭·스토어 로드).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/layout/detail_screen_scaffold.dart';
import 'package:app_flutter/features/stores/store_detail_tabs.dart';
import 'package:app_flutter/features/stores/store_controller.dart';
import 'package:app_flutter/features/stores/store_model.dart';

/// 가맹점 상세 화면.
///
/// 화면 골격은 [DetailScreenWithTabs] 로 통일하고, 탭별 내용은
/// [StoreDetailPanel] 이 담당합니다.
///
/// [isRegisterMode] 가 true이면 API 연동 전까지 데이터 없이 빈 상태로 연다.
/// 존재하지 않는 [storeIdx] 로 열었을 때도 동일하게 빈 상태다.
class StoreDetailView extends ConsumerStatefulWidget {
  const StoreDetailView({
    super.key,
    this.storeIdx,
    this.isRegisterMode = false,
  });

  final int? storeIdx;
  final bool isRegisterMode;

  static const List<String> _tabTitles = [
    '기본정보',
    '계약정보',
    // '매출정보',
    '문서정보',
    '히스토리',
  ];

  @override
  ConsumerState<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends ConsumerState<StoreDetailView> {
  StoreRegisterDraft? _registerDraft;
  StoreRegisterDraft? _detailDraft;
  int? _detailDraftStoreIdx;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRegisterMode) {
      _registerDraft = StoreRegisterDraft();
    }
    Future.microtask(_reloadCurrentStore);
  }

  @override
  void didUpdateWidget(covariant StoreDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRegisterMode != widget.isRegisterMode) {
      _registerDraft?.dispose();
      _registerDraft = widget.isRegisterMode ? StoreRegisterDraft() : null;
    }
    if (oldWidget.storeIdx != widget.storeIdx ||
        oldWidget.isRegisterMode != widget.isRegisterMode) {
      Future.microtask(_reloadCurrentStore);
    }
  }

  @override
  void dispose() {
    _registerDraft?.dispose();
    _detailDraft?.dispose();
    super.dispose();
  }

  void _reloadCurrentStore() {
    if (!mounted || widget.isRegisterMode || widget.storeIdx == null) return;
    ref.invalidate(storeDetailProvider(widget.storeIdx!));
    ref.invalidate(storeDataProvider);
  }

  StoreRegisterDraft? _draftForStore(Store? store) {
    if (widget.isRegisterMode) return _registerDraft;
    if (store == null) return null;
    if (_detailDraft == null || _detailDraftStoreIdx != store.storeIdx) {
      _detailDraft?.dispose();
      _detailDraft = StoreRegisterDraft()..hydrateFromStore(store);
      _detailDraftStoreIdx = store.storeIdx;
      _isEditing = false;
    }
    return _detailDraft;
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = widget.isRegisterMode
        ? const AsyncValue<Store?>.data(null)
        : (widget.storeIdx != null
              ? ref.watch(storeDetailProvider(widget.storeIdx!))
              : const AsyncValue<Store?>.data(null));

    return storeAsync.when(
      data: (store) {
        final draft = _draftForStore(store);

        /// 등록 모드는 셸 [MainFrameLayout] 상단 배너에 제목이 있으므로 본문 제목(중복 띠)을 생략한다.
        final Widget title;
        if (widget.isRegisterMode) {
          title = const SizedBox.shrink();
        } else if (store != null) {
          title = DetailScreenHeadline.leadTail(
            lead: store.storeNm,
            tail: '님 상세 정보',
          );
        } else {
          title = DetailScreenHeadline.plain(text: '가맹점 상세');
        }

        return DetailScreenWithTabs(
          title: title,
          tabTitles: StoreDetailView._tabTitles,
          tabPages: [
            for (final title in StoreDetailView._tabTitles)
              StoreDetailPanel(
                title: title,
                store: store,
                isRegisterMode: widget.isRegisterMode,
                registerDraft: draft,
                sharedEditing: widget.isRegisterMode ? true : _isEditing,
                onEditModeChanged: widget.isRegisterMode
                    ? null
                    : (value) => setState(() => _isEditing = value),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
    );
  }
}
