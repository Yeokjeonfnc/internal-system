import 'package:json_annotation/json_annotation.dart';

import 'package:app_flutter/core/user_mst/user_mst_api_json_keys.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';

part 'mst001_model.g.dart';

/// 사원 한 명(목록·필터 소스).
enum SvYn { yes, no }

enum OwnerYn { yes, no }

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
    required this.svYn,
    this.ownerYn = OwnerYn.no,
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

  @JsonKey(name: UserMstApiJsonKeys.deptIdx)
  final int? deptIdx;

  @JsonKey(name: UserMstApiJsonKeys.positionNm)
  final String positionNm;

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

  @JsonKey(
    name: UserMstApiJsonKeys.svYn,
    fromJson: _svYnFromJsonField,
    toJson: _svYnToJson,
  )
  final SvYn svYn;

  @JsonKey(
    name: UserMstApiJsonKeys.ownerYn,
    fromJson: _ownerYnFromJsonField,
    toJson: _ownerYnToJson,
    defaultValue: OwnerYn.no,
  )
  final OwnerYn ownerYn;

  factory User.fromJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    m[UserMstApiJsonKeys.userIdx] ??= 0;
    m[UserMstApiJsonKeys.userName] ??= '';
    m[UserMstApiJsonKeys.deptNm] ??= '';
    m[UserMstApiJsonKeys.positionNm] ??= '';
    m[UserMstApiJsonKeys.userPhone] ??= '';
    m[UserMstApiJsonKeys.userEmail] ??= '';
    m[UserMstApiJsonKeys.userId] ??= '';
    return _$UserFromJson(m);
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);

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
    bool svYn = false,
    bool ownerYn = false,
  }) {
    final body = <String, dynamic>{
      UserMstWriteRequest.jsonKeyUserName: name.trim(),
      UserMstWriteRequest.jsonKeyUserPassword: userPassword,
      UserMstWriteRequest.jsonKeySvYn: svYn ? 'Y' : 'N',
      UserMstWriteRequest.jsonKeyOwnerYn: ownerYn ? 'Y' : 'N',
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

  /// 수정 요청 본문.
  ///
  /// 서버(`UserMstUpdateRequestDto`)는 **키가 들어온 필드만** 갱신하는 presence
  /// 방식이라, 빈 값이라고 키를 빼 버리면 "변경 없음"으로 읽혀 기존 값이 되살아난다.
  /// 예전에는 빈 문자열을 전부 걸러 보내서 퇴사자 이메일 삭제·잘못 적은 휴대전화
  /// 지우기·입사일 삭제가 하나도 먹지 않았다(저장은 성공했다고 뜨는데 다시 열면
  /// 그대로였다).
  ///
  /// 그래서 인자 의미를 가맹점주(mst006)와 같은 방식으로 맞춘다 —
  /// **null 이면 "이 항목은 건드리지 않음"(키 자체를 안 보냄), 값이 있으면 빈
  /// 문자열이라도 그대로 보내 지운다.** 항목을 다루지 않는 호출자(CSV 업로드의
  /// 입사일 등)가 실수로 값을 날리지 않게 하려면 그냥 인자를 넘기지 않으면 된다.
  ///
  /// `userPassword` 만 예외다 — 빈 값이 곧 "이번엔 비밀번호를 안 바꾼다"는 뜻이라
  /// 지우는 개념이 없다.
  static UserMstWriteRequest buildUpdateUserRequest({
    required String name,
    String userPassword = '',
    String? userId,
    int? deptIdx,
    String? mobilePhone,
    String? email,
    String? joinDt,
    String? positionCd,
    bool svYn = false,
    bool ownerYn = false,
  }) {
    final body = <String, dynamic>{
      UserMstWriteRequest.jsonKeyUserName: name.trim(),
      UserMstWriteRequest.jsonKeySvYn: svYn ? 'Y' : 'N',
      UserMstWriteRequest.jsonKeyOwnerYn: ownerYn ? 'Y' : 'N',
    };
    final pw = userPassword.trim();
    if (pw.isNotEmpty) body[UserMstWriteRequest.jsonKeyUserPassword] = pw;
    if (userId != null) {
      body[UserMstWriteRequest.jsonKeyUserId] = userId.trim();
    }
    if (deptIdx != null) body[UserMstWriteRequest.jsonKeyDeptIdx] = deptIdx;
    if (mobilePhone != null) {
      body[UserMstWriteRequest.jsonKeyUserPhone] = mobilePhone.trim();
    }
    if (email != null) {
      body[UserMstWriteRequest.jsonKeyUserEmail] = email.trim();
    }
    if (positionCd != null) {
      body[UserMstWriteRequest.jsonKeyPositionCd] = positionCd.trim();
    }
    if (joinDt != null) {
      // 입사일만 서버가 LocalDate 로 받는다 — 빈 문자열의 해석을 Jackson 설정에
      // 맡기지 않도록 "지움"은 명시적인 null 로 보낸다.
      final jd = joinDt.trim();
      body[UserMstWriteRequest.jsonKeyJoinDt] = jd.isEmpty ? null : jd;
    }
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

SvYn _svYnFromJsonField(Object? value) {
  if (value is SvYn) return value;
  if (value is bool) return value ? SvYn.yes : SvYn.no;
  if (value is num) return value != 0 ? SvYn.yes : SvYn.no;
  final s = value?.toString().trim().toUpperCase() ?? '';
  if (s == 'Y' || s == 'TRUE' || s == '1') return SvYn.yes;
  return SvYn.no;
}

String _svYnToJson(SvYn v) => v == SvYn.yes ? 'Y' : 'N';

OwnerYn _ownerYnFromJsonField(Object? value) {
  if (value is OwnerYn) return value;
  if (value is bool) return value ? OwnerYn.yes : OwnerYn.no;
  if (value is num) return value != 0 ? OwnerYn.yes : OwnerYn.no;
  final s = value?.toString().trim().toUpperCase() ?? '';
  if (s == 'Y' || s == 'TRUE' || s == '1') return OwnerYn.yes;
  return OwnerYn.no;
}

String _ownerYnToJson(OwnerYn v) => v == OwnerYn.yes ? 'Y' : 'N';
