import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/master/mst006/mst006_api.dart';
import 'package:app_flutter/pages/master/mst006/mst006_filter.dart';
import 'package:app_flutter/pages/master/mst006/mst006_model.dart';
import 'package:app_flutter/pages/master/mst006/mst006_provider.dart';

final mst006ApiServiceProvider = Provider<Mst006ApiService>(
  (ref) => Mst006ApiService(),
);

final ownerUserDataProvider = FutureProvider<List<OwnerUser>>((ref) async {
  try {
    return await ref.watch(mst006ApiServiceProvider).getOwners();
  } catch (e) {
    debugPrint('가맹점주 목록 조회 실패: $e');
    return const [];
  }
});

final ownerUserDetailProvider = FutureProvider.family<OwnerUser?, int>((
  ref,
  userIdx,
) async {
  if (userIdx <= 0) return null;
  try {
    return await ref.watch(mst006ApiServiceProvider).getOwner(userIdx);
  } catch (_) {
    return null;
  }
});

final ownerUserProvider = NotifierProvider<OwnerUserNotifier, OwnerUserFilter>(
  OwnerUserNotifier.new,
);

class OwnerUserNotifier extends BaseListNotifier<OwnerUserFilter, OwnerUser> {
  @override
  OwnerUserFilter build() => const OwnerUserFilter();

  @override
  AsyncValue<List<OwnerUser>> get listAsync => ref.watch(ownerUserDataProvider);

  @override
  List<ListFilterRule<OwnerUserFilter, OwnerUser>> get ruleList =>
      kMst006ListRules;

  void setKeyword(String v) => state = state.copyWith(keyword: v);

  void refresh() => ref.invalidate(ownerUserDataProvider);
}
