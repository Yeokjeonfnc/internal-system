// 사원 목록(mst001) 필터 상태.

class UserFilter {
  const UserFilter({
    this.userKeyword = '',
    this.department = '전체',
    this.position = '전체',
  });

  /// 사원명·이메일·휴대전화 통합 검색(부분 일치, OR).
  final String userKeyword;
  final String department;
  final String position;

  UserFilter copyWith({
    String? userKeyword,
    String? department,
    String? position,
  }) {
    return UserFilter(
      userKeyword: userKeyword ?? this.userKeyword,
      department: department ?? this.department,
      position: position ?? this.position,
    );
  }
}
