// 예비창업자 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/pages/dev001/dev001_api.dart';
import 'package:app_flutter/pages/dev001/dev001_filter.dart';
import 'package:app_flutter/pages/dev001/dev001_model.dart';
import 'package:app_flutter/pages/dev001/dev001_provider.dart';

abstract class PartnerRepository {
  Future<List<Partner>> all();
  Future<Partner?> find(int partnerIdx);
  List<String> regions();
}

class ApiPartnerRepository implements PartnerRepository {
  const ApiPartnerRepository(this._apiService);

  final PartnerApiService _apiService;

  @override
  Future<List<Partner>> all() => _apiService.getAllPartners();

  @override
  Future<Partner?> find(int partnerIdx) => _apiService.getPartner(partnerIdx);

  @override
  List<String> regions() => const <String>['전체'];
}

final partnerApiServiceProvider = Provider<PartnerApiService>(
  (ref) => PartnerApiService(),
);

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => ApiPartnerRepository(ref.watch(partnerApiServiceProvider)),
);

final partnerCommonCodeApiServiceProvider = Provider<CommonCodeApiService>(
  (ref) => CommonCodeApiService(),
);

final partnerCodeOptionsProvider = FutureProvider.family<List<CodeOption>, int>(
  (ref, grpCd) =>
      ref.watch(partnerCommonCodeApiServiceProvider).getCodes(grpCd),
);

final partnerDataProvider = FutureProvider<List<Partner>>((ref) async {
  return ref.watch(partnerRepositoryProvider).all();
});

final partnerDetailProvider = FutureProvider.family<Partner?, int>((
  ref,
  partnerIdx,
) async {
  if (partnerIdx <= 0) return null;
  return ref.watch(partnerRepositoryProvider).find(partnerIdx);
});

final partnerProvider = NotifierProvider<PartnerNotifier, PartnerFilter>(
  PartnerNotifier.new,
);

class PartnerNotifier extends BaseListNotifier<PartnerFilter, Partner> {
  @override
  PartnerFilter build() => const PartnerFilter();

  @override
  AsyncValue<List<Partner>> get listAsync => ref.watch(partnerDataProvider);

  @override
  List<ListFilterRule<PartnerFilter, Partner>> get ruleList => kDev001ListRules;

  void setPartnerKeyword(String v) => state = state.copy(partnerKeyword: v);
  void setRegion(String v) => state = state.copy(pRegion: v);
  void setPartnerStatus(String v) => state = state.copy(partnerStatus: v);
  void setEvaluation(EvaluationStatus? v) => state = v == null
      ? state.copy(clearEvaluation: true)
      : state.copy(evaluation: v);

  void refresh() {
    ref.invalidate(partnerDataProvider);
  }
}
