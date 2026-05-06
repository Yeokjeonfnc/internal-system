// 예비창업자 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/api/common_code_api_service.dart';
import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/founders/partner_api_service.dart';
import 'package:app_flutter/features/founders/partner_model.dart';

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

class PartnerFilter {
  const PartnerFilter({
    this.partnerKeyword = '',
    this.pRegion = '전체',
    this.partnerStatus = '전체',
    this.evaluation,
  });

  /// 이름·휴대전화·이메일 등 통합 검색(부분 일치, OR).
  final String partnerKeyword;
  final String pRegion;

  /// [Partner.partnerStatus]와 같은 한글 라벨(`전체`·`예비창업자`·`가맹점사업자`).
  final String partnerStatus;
  final EvaluationStatus? evaluation;

  PartnerFilter copy({
    String? partnerKeyword,
    String? pRegion,
    String? partnerStatus,
    EvaluationStatus? evaluation,
    bool clearEvaluation = false,
  }) {
    return PartnerFilter(
      partnerKeyword: partnerKeyword ?? this.partnerKeyword,
      pRegion: pRegion ?? this.pRegion,
      partnerStatus: partnerStatus ?? this.partnerStatus,
      evaluation: clearEvaluation ? null : evaluation ?? this.evaluation,
    );
  }
}

final partnerProvider = NotifierProvider<PartnerNotifier, PartnerFilter>(
  PartnerNotifier.new,
);

class PartnerNotifier extends RuleListNotifier<PartnerFilter, Partner> {
  @override
  PartnerFilter build() => const PartnerFilter();

  @override
  List<Partner> get source {
    final partnersAsync = ref.watch(partnerDataProvider);
    return partnersAsync.maybeWhen(data: (rows) => rows, orElse: () => []);
  }

  @override
  List<ListFilterRule<PartnerFilter, Partner>> get rules => [
    (s, r) => s.evaluation == null || r.evaluationStatus == s.evaluation,
    (s, r) => s.pRegion == '전체' || r.pRegion == s.pRegion,
    (s, r) {
      if (s.partnerStatus == '전체') return true;
      return partnerStatusLabelKorean(r.partnerStatus) == s.partnerStatus;
    },
    (s, r) {
      final q = s.partnerKeyword.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.partnerNm.toLowerCase().contains(q) ||
          r.partnerTel.toLowerCase().contains(q) ||
          r.partnerEmail.toLowerCase().contains(q);
    },
  ];

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
