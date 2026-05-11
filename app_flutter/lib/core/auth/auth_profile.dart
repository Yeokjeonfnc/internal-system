import 'package:app_flutter/core/utils/json_extensions.dart';

/// 로그인·프로필 API 응답 — 백엔드 `AuthProfileDto` 키와 동일.
class AuthProfile {
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyUserNm = 'userNm';
  static const String jsonKeyEmail = 'email';
  static const String jsonKeyDeptIdx = 'deptIdx';
  static const String jsonKeyUserPhone = 'userPhone';
  static const String jsonKeyDeptNm = 'deptNm';
  static const String jsonKeyPositionCd = 'positionCd';
  static const String jsonKeyPositionNm = 'positionNm';
  static const String jsonKeySvYn = 'svYn';
  static const String jsonKeyTagYn = 'tagYn';
  static const String jsonKeyJoinDt = 'joinDt';

  const AuthProfile({
    required this.userId,
    required this.userNm,
    required this.email,
    this.deptIdx,
    required this.userPhone,
    required this.deptNm,
    required this.positionCd,
    required this.positionNm,
    required this.svYn,
    required this.tagYn,
    required this.joinDtRaw,
  });

  final String userId;
  final String userNm;
  final String email;
  final int? deptIdx;
  final String userPhone;
  final String deptNm;
  final String positionCd;
  final String positionNm;
  final String svYn;
  final String tagYn;
  final String joinDtRaw;

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    return AuthProfile(
      userId: json.jsonString(jsonKeyUserId),
      userNm: json.jsonString(jsonKeyUserNm),
      email: json.jsonString(jsonKeyEmail),
      deptIdx: asJsonIntOpt(json[jsonKeyDeptIdx]),
      userPhone: json.jsonString(jsonKeyUserPhone),
      deptNm: json.jsonString(jsonKeyDeptNm),
      positionCd: json.jsonString(jsonKeyPositionCd),
      positionNm: json.jsonString(jsonKeyPositionNm),
      svYn: json.jsonString(jsonKeySvYn),
      tagYn: json.jsonString(jsonKeyTagYn),
      joinDtRaw: _joinDtString(json[jsonKeyJoinDt]),
    );
  }

  Map<String, dynamic> toJson() => {
        jsonKeyUserId: userId,
        jsonKeyUserNm: userNm,
        jsonKeyEmail: email,
        if (deptIdx != null) jsonKeyDeptIdx: deptIdx,
        jsonKeyUserPhone: userPhone,
        jsonKeyDeptNm: deptNm,
        jsonKeyPositionCd: positionCd,
        jsonKeyPositionNm: positionNm,
        jsonKeySvYn: svYn,
        jsonKeyTagYn: tagYn,
        jsonKeyJoinDt: joinDtRaw,
      };

  static String _joinDtString(Object? v) {
    if (v == null) return '';
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return '';
      return s.split('T').first;
    }
    if (v is List && v.isNotEmpty) {
      final y = (v[0] as num?)?.toInt();
      final m = v.length > 1 ? (v[1] as num?)?.toInt() : null;
      final d = v.length > 2 ? (v[2] as num?)?.toInt() : null;
      if (y != null && m != null && d != null) {
        String two(int x) => x.toString().padLeft(2, '0');
        return '$y-${two(m)}-${two(d)}';
      }
    }
    return v.toString();
  }
}
