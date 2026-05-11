// 예비창업자 목록(dev001) 필터 상태.

import 'package:app_flutter/pages/development/dev001/dev001_model.dart';

class PartnerFilter {
  const PartnerFilter({
    this.partnerKeyword = '',
    this.pRegion = '전체',
    this.partnerStatus = '전체',
    this.evaluation,
    this.regionNms = const <String>{},
  });

  /// 이름·휴대전화·이메일 등 통합 검색(부분 일치, OR).
  final String partnerKeyword;
  final String pRegion;

  /// [Partner.partnerStatus]와 같은 한글 라벨(`전체`·`예비창업자`·`가맹점사업자`).
  final String partnerStatus;
  final EvaluationStatus? evaluation;

  final Set<String> regionNms;

  PartnerFilter copy({
    String? partnerKeyword,
    String? pRegion,
    Set<String>? regionNms,
    String? partnerStatus,
    EvaluationStatus? evaluation,
    bool clearEvaluation = false,
    bool clearRegions = false,
  }) {
    return PartnerFilter(
      partnerKeyword: partnerKeyword ?? this.partnerKeyword,
      pRegion: pRegion ?? this.pRegion,
      partnerStatus: partnerStatus ?? this.partnerStatus,
      regionNms: clearRegions ? <String>{} : regionNms ?? this.regionNms,
      evaluation: clearEvaluation ? null : evaluation ?? this.evaluation,
    );
  }
}
