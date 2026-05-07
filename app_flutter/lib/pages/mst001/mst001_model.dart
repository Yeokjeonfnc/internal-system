import 'package:json_annotation/json_annotation.dart';

part 'mst001_model.g.dart';

/// 사원 한 명(목록·필터 소스).
@JsonSerializable()
class Employee {
  const Employee({
    required this.no,
    required this.name,
    required this.department,
    required this.jobTitle,
    required this.mobilePhone,
    required this.email,
    required this.joinDt,
    required this.tagYn,
    this.userId = '',
  });

  @JsonKey(name: 'userIdx')
  final int no;

  @JsonKey(name: 'userName')
  final String name;

  @JsonKey(name: 'deptNm')
  final String department;

  @JsonKey(name: 'positionNm')
  final String jobTitle;

  @JsonKey(name: 'userPhone')
  final String mobilePhone;

  @JsonKey(name: 'userEmail')
  final String email;

  @JsonKey(name: 'joinDt', fromJson: _joinDtFromJson)
  final String joinDt;

  @JsonKey(name: 'userId', defaultValue: '')
  final String userId;

  @JsonKey(name: 'svYn', fromJson: _svYnFromJson, toJson: _svYnToJson)
  final bool tagYn;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  /// POST `/users` 본문을 만든다. 필드 의미는 [Employee]와 동일하게 맞춘다.
  static Map<String, dynamic> buildCreateUserRequest({
    required String name,
    required String userPassword,
    String userId = '',
    int? deptIdx,
    String mobilePhone = '',
    String email = '',
    String joinDt = '',
    String positionCd = '',
    bool tagYn = false,
  }) {
    final body = <String, dynamic>{
      'userName': name.trim(),
      'userPassword': userPassword,
      'svYn': tagYn ? 'Y' : 'N',
    };
    final uid = userId.trim();
    if (uid.isNotEmpty) body['userId'] = uid;
    if (deptIdx != null) body['deptIdx'] = deptIdx;
    final phone = mobilePhone.trim();
    if (phone.isNotEmpty) body['userPhone'] = phone;
    final em = email.trim();
    if (em.isNotEmpty) body['userEmail'] = em;
    final pos = positionCd.trim();
    if (pos.isNotEmpty) body['positionCd'] = pos;
    final jd = joinDt.trim();
    if (jd.isNotEmpty) body['joinDt'] = jd;
    return body;
  }
}

String _joinDtFromJson(Object? v) {
  final str = v?.toString() ?? '';
  if (str.length >= 10) {
    return str.substring(0, 10);
  }
  return str;
}

bool _svYnFromJson(Object? v) => v?.toString() == 'Y';

String _svYnToJson(bool v) => v ? 'Y' : 'N';
