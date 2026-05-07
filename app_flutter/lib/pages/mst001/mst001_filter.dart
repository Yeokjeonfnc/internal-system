// 사원 목록(emp001) 필터 상태.

class EmployeeFilter {
  const EmployeeFilter({
    this.employeeKeyword = '',
    this.department = '전체',
    this.position = '전체',
  });

  /// 사원명·이메일·휴대전화 통합 검색(부분 일치, OR).
  final String employeeKeyword;
  final String department;
  final String position;

  EmployeeFilter copyWith({
    String? employeeKeyword,
    String? department,
    String? position,
  }) {
    return EmployeeFilter(
      employeeKeyword: employeeKeyword ?? this.employeeKeyword,
      department: department ?? this.department,
      position: position ?? this.position,
    );
  }
}
