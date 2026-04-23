// 마스터 — 사원 목록 행.

/// 사원 한 명(목록·필터 소스).
class Employee {
  const Employee({
    required this.no,
    required this.name,
    required this.department,
    required this.jobTitle,
    required this.mobilePhone,
    required this.email,
    required this.hireDateYmd,
    required this.tagEnabled,
  });

  final int no;
  final String name;
  final String department;
  final String jobTitle;
  final String mobilePhone;
  final String email;

  /// 입사년월일 `YYYY-MM-DD`
  final String hireDateYmd;
  final bool tagEnabled;
}
