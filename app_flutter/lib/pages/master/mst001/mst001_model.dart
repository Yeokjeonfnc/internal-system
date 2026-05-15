import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/user_mst/user_mst_api_json_keys.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';

part 'mst001_model.g.dart';

/// 사원 한 명(목록·필터 소스).
///
enum TagYn { tagged, untagged }

@JsonSerializable()
class User {
  const User({
    required this.userIdx,
    required this.name,
    required this.department,
    required this.positionNm,
    required this.mobilePhone,
    required this.email,
    required this.joinDt,
    required this.tagYn,
    this.userId = '',
    this.deptIdx,
    this.positionCd,
  });

  @JsonKey(name: UserMstApiJsonKeys.userIdx)
  final int userIdx;

  @JsonKey(name: UserMstApiJsonKeys.userName)
  final String name;

  @JsonKey(name: UserMstApiJsonKeys.deptNm)
  final String department;

  /// 상세 API에서 내려오는 부서 PK(목록에는 없을 수 있음).
  @JsonKey(name: UserMstApiJsonKeys.deptIdx)
  final int? deptIdx;

  @JsonKey(name: UserMstApiJsonKeys.positionNm)
  final String positionNm;

  /// 직급 코드(상세·저장 시 드롭다운 값).
  @JsonKey(name: UserMstApiJsonKeys.positionCd)
  final String? positionCd;

  String get jobTitle => positionNm;

  @JsonKey(name: UserMstApiJsonKeys.userPhone)
  final String mobilePhone;

  @JsonKey(name: UserMstApiJsonKeys.userEmail)
  final String email;

  @JsonKey(name: UserMstApiJsonKeys.joinDt, fromJson: _joinDtFromJson)
  final String joinDt;

  @JsonKey(name: UserMstApiJsonKeys.userId, defaultValue: '')
  final String userId;

  /// 서버 `UserMstDto`는 `tagYn`·`svYn` 둘 다 줄 수 있다. `tagYn`이 비어 있으면 `User.fromJson`에서 `svYn`으로 보강한다.
  /// enum 자동 디코드는 쓰지 않는다(`Y`와 `tagged` 불일치 방지).
  @JsonKey(
    name: UserMstApiJsonKeys.tagYn,
    fromJson: _tagYnFromJsonField,
    toJson: _tagYnToJson,
  )
  final TagYn tagYn;

  factory User.fromJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    final tag = m[UserMstApiJsonKeys.tagYn];
    if (tag == null && m[UserMstApiJsonKeys.svYn] != null) {
      m[UserMstApiJsonKeys.tagYn] = m[UserMstApiJsonKeys.svYn];
    }
    return _$UserFromJson(m);
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// POST `/users` 본문을 만든다. 필드 의미는 [User]와 동일하게 맞춘다.
  static UserMstWriteRequest buildCreateUserRequest({
    int? userIdx,
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
    final yn = tagYn ? 'Y' : 'N';
    final body = <String, dynamic>{
      UserMstWriteRequest.jsonKeyUserName: name.trim(),
      UserMstWriteRequest.jsonKeyUserPassword: userPassword,
      UserMstWriteRequest.jsonKeyTagYn: yn,
      UserMstWriteRequest.jsonKeySvYn: yn,
    };
    final uid = userId.trim();
    if (uid.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserId] = uid;
    if (deptIdx != null) body[UserMstWriteRequest.jsonKeyDeptIdx] = deptIdx;
    final phone = mobilePhone.trim();
    if (phone.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserPhone] = phone;
    final em = email.trim();
    if (em.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserEmail] = em;
    final pos = positionCd.trim();
    if (pos.isNotEmpty) body[UserMstWriteRequest.jsonKeyPositionCd] = pos;
    final jd = joinDt.trim();
    if (jd.isNotEmpty) body[UserMstWriteRequest.jsonKeyJoinDt] = jd;
    return UserMstWriteRequest.fromMap(body);
  }

  /// PUT `/users/:userIdx` — 비밀번호는 비어 있으면 본문에 넣지 않는다.
  static UserMstWriteRequest buildUpdateUserRequest({
    required String name,
    String userPassword = '',
    String userId = '',
    int? deptIdx,
    String mobilePhone = '',
    String email = '',
    String joinDt = '',
    String positionCd = '',
    bool tagYn = false,
  }) {
    final yn = tagYn ? 'Y' : 'N';
    final body = <String, dynamic>{
      UserMstWriteRequest.jsonKeyUserName: name.trim(),
      UserMstWriteRequest.jsonKeyTagYn: yn,
      UserMstWriteRequest.jsonKeySvYn: yn,
    };
    final pw = userPassword.trim();
    if (pw.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserPassword] = pw;
    final uid = userId.trim();
    if (uid.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserId] = uid;
    if (deptIdx != null) body[UserMstWriteRequest.jsonKeyDeptIdx] = deptIdx;
    final phone = mobilePhone.trim();
    if (phone.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserPhone] = phone;
    final em = email.trim();
    if (em.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserEmail] = em;
    final pos = positionCd.trim();
    if (pos.isNotEmpty) body[UserMstWriteRequest.jsonKeyPositionCd] = pos;
    final jd = joinDt.trim();
    if (jd.isNotEmpty) body[UserMstWriteRequest.jsonKeyJoinDt] = jd;
    return UserMstWriteRequest.fromMap(body);
  }
}

String _joinDtFromJson(Object? v) {
  final str = v?.toString() ?? '';
  if (str.length >= 10) {
    return str.substring(0, 10);
  }
  return str;
}

TagYn _tagYnFromJsonField(Object? value) {
  if (value is TagYn) return value;
  if (value is bool) return value ? TagYn.tagged : TagYn.untagged;
  if (value is num) return value != 0 ? TagYn.tagged : TagYn.untagged;
  final s = value?.toString().trim().toUpperCase() ?? '';
  if (s == 'Y' || s == 'TRUE' || s == '1') return TagYn.tagged;
  return TagYn.untagged;
}

String _tagYnToJson(TagYn v) => v == TagYn.tagged ? 'Y' : 'N';
