/// 예비창업자 평가 상태.
enum EvaluationStatus { pending, completed }

/// 예비창업자 / 가맹점사업자 구분.
enum FounderStatus { prospect, franchisee }

String founderStatusLabelKorean(FounderStatus s) => switch (s) {
  FounderStatus.prospect => '예비창업자',
  FounderStatus.franchisee => '가맹점사업자',
};

/// 성별.
enum Gender { male, female }

/// 예비창업자 모델.
class Founder {
  const Founder({
    required this.no,
    required this.registrationDate,
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.postalCode,
    required this.address,
    required this.addressDetail,
    required this.evaluationStatus,
    required this.evaluationScore,
    required this.region,
    required this.founderStatus,
  });

  final int no;
  final String registrationDate;
  final String name;
  final String phone;
  final String email;
  final Gender gender;
  final String birthDate;
  final String postalCode;
  final String address;
  final String addressDetail;
  final EvaluationStatus evaluationStatus;
  final int? evaluationScore;
  final String region;
  final FounderStatus founderStatus;
}
