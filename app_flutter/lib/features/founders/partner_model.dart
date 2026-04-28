/// 예비창업자 평가 상태.
enum EvaluationStatus { pending, completed }

/// 예비창업자 / 가맹점사업자 구분.
enum PartnerStatus { prospect, franchisee }

String partnerStatusLabelKorean(PartnerStatus s) => switch (s) {
  PartnerStatus.prospect => '예비창업자',
  PartnerStatus.franchisee => '가맹점사업자',
};

/// 성별.
enum Gender { male, female }

/// 예비창업자 모델.
class Partner {
  const Partner({
    required this.partnerIdx,
    required this.createDt,
    required this.partnerNm,
    required this.partnerTel,
    required this.partnerEmail,
    required this.gender,
    required this.partnerBirth,
    required this.pZipCd,
    required this.pAddress,
    required this.pAddressDetail,
    required this.evaluationStatus,
    required this.evaluationScore,
    required this.pRegion,
    required this.partnerStatus,
  });

  final int partnerIdx;
  final String createDt;
  final String partnerNm;
  final String partnerTel;
  final String partnerEmail;
  final Gender gender;
  final String partnerBirth;
  final String pZipCd;
  final String pAddress;
  final String pAddressDetail;
  final EvaluationStatus evaluationStatus;
  final int? evaluationScore;
  final String pRegion;
  final PartnerStatus partnerStatus;
}
