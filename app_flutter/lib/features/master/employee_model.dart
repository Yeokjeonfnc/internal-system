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
    this.userId = '',
  });

  final int no;
  final String name;
  final String department;
  final String jobTitle;
  final String mobilePhone;
  final String email;

  /// 로그인 ID (user_mst.user_id). 결재 저장·매칭용.
  final String userId;

  /// 입사년월일 `YYYY-MM-DD`
  final String hireDateYmd;
  final bool tagEnabled;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      no: json['userIdx'] as int? ?? 0,
      name: json['userName'] as String? ?? '',
      department: json['deptNm'] as String? ?? '',
      jobTitle: json['positionNm'] as String? ?? '',
      mobilePhone: json['userPhone'] as String? ?? '',
      email: json['userEmail'] as String? ?? '',
      hireDateYmd: _formatDate(json['createdAt']),
      tagEnabled: (json['svYn'] as String?) == 'Y',
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userIdx': no,
      'userId': userId,
      'userName': name,
      'deptNm': department,
      'positionNm': jobTitle,
      'userPhone': mobilePhone,
      'userEmail': email,
      'createdAt': hireDateYmd,
      'svYn': tagEnabled ? 'Y' : 'N',
    };
  }

  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    final str = dateValue.toString();
    if (str.length >= 10) {
      return str.substring(0, 10);
    }
    return str;
  }
}
