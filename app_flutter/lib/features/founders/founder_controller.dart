// 예비창업자 목록 필터와 임시 메모리 Repository를 한 파일에서 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_flutter/core/state/base_list_provider.dart';
import 'package:app_flutter/features/founders/founder_model.dart';

abstract class FounderRepository {
  List<Founder> all();
  Founder? find(int no);
  List<String> regions();
}

class InMemoryFounderRepository implements FounderRepository {
  const InMemoryFounderRepository();

  @override
  List<Founder> all() => const <Founder>[];

  @override
  Founder? find(int no) => null;

  @override
  List<String> regions() => const <String>['전체'];
}

final founderRepositoryProvider = Provider<FounderRepository>(
  (ref) => const InMemoryFounderRepository(),
);

class FounderFilter {
  const FounderFilter({
    this.name = '',
    this.phone = '',
    this.region = '전체',
    this.founderStatus = '전체',
    this.evaluation,
  });

  final String name;
  final String phone;
  final String region;

  /// [Founder.founderStatus]와 같은 한글 라벨(`전체`·`예비창업자`·`가맹점사업자`).
  final String founderStatus;
  final EvaluationStatus? evaluation;

  FounderFilter copy({
    String? name,
    String? phone,
    String? region,
    String? founderStatus,
    EvaluationStatus? evaluation,
    bool clearEvaluation = false,
  }) {
    return FounderFilter(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      founderStatus: founderStatus ?? this.founderStatus,
      evaluation: clearEvaluation ? null : evaluation ?? this.evaluation,
    );
  }
}

final founderProvider = NotifierProvider<FounderNotifier, FounderFilter>(
  FounderNotifier.new,
);

class FounderNotifier extends RuleListNotifier<FounderFilter, Founder> {
  @override
  FounderFilter build() => const FounderFilter();

  @override
  List<Founder> get source => ref.read(founderRepositoryProvider).all();

  @override
  List<ListFilterRule<FounderFilter, Founder>> get rules => [
    (s, r) => s.evaluation == null || r.evaluationStatus == s.evaluation,
    (s, r) => s.region == '전체' || r.region == s.region,
    (s, r) {
      if (s.founderStatus == '전체') return true;
      return founderStatusLabelKorean(r.founderStatus) == s.founderStatus;
    },
    (s, r) {
      final q = s.name.trim();
      return q.isEmpty || r.name.contains(q);
    },
    (s, r) {
      final q = s.phone.trim();
      return q.isEmpty || r.phone.contains(q);
    },
  ];

  void setName(String v) => state = state.copy(name: v);
  void setPhone(String v) => state = state.copy(phone: v);
  void setRegion(String v) => state = state.copy(region: v);
  void setFounderStatus(String v) => state = state.copy(founderStatus: v);
  void setEvaluation(EvaluationStatus? v) => state = v == null
      ? state.copy(clearEvaluation: true)
      : state.copy(evaluation: v);
}
