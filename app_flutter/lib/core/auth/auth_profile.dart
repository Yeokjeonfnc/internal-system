import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';

/// 로그인·프로필 API 응답 — 백엔드 `AuthProfileDto` 키와 동일.
class AuthProfile {
  static const String jsonKeyUserIdx = 'userIdx';
  static const String jsonKeyUserId = 'userId';
  static const String jsonKeyMenuPermissions = 'menuPermissions';
  static const String jsonKeyUserNm = 'userNm';
  static const String jsonKeyEmail = 'email';
  static const String jsonKeyDeptIdx = 'deptIdx';
  static const String jsonKeyUserPhone = 'userPhone';
  static const String jsonKeyDeptNm = 'deptNm';
  static const String jsonKeyPositionCd = 'positionCd';
  static const String jsonKeyPositionNm = 'positionNm';
  static const String jsonKeySvYn = 'svYn';
  static const String jsonKeyOwnerYn = 'ownerYn';
  static const String jsonKeyAdminYn = 'adminYn';
  static const String jsonKeyStoreIdx = 'storeIdx';
  static const String jsonKeyStoreNm = 'storeNm';
  static const String jsonKeyJoinDt = 'joinDt';
  static const String jsonKeyAccessToken = 'accessToken';
  static const String jsonKeyMustChangePassword = 'mustChangePassword';

  const AuthProfile({
    this.userIdx,
    required this.userId,
    required this.userNm,
    this.menuPermissions = const [],
    required this.email,
    this.deptIdx,
    required this.userPhone,
    required this.deptNm,
    required this.positionCd,
    required this.positionNm,
    required this.svYn,
    required this.ownerYn,
    this.adminYn = '',
    this.storeIdx,
    required this.storeNm,
    required this.joinDtRaw,
    this.accessToken = '',
    this.mustChangePassword = false,
  });

  final int? userIdx;
  final String userId;
  final List<MenuPermission> menuPermissions;
  final String userNm;
  final String email;
  final int? deptIdx;
  final String userPhone;
  final String deptNm;
  final String positionCd;
  final String positionNm;
  final String svYn;
  final String ownerYn;
  final String adminYn;
  final int? storeIdx;
  final String storeNm;
  final String joinDtRaw;

  /// 로그인 시 서버가 발급한 인증 토큰. 이후 모든 API 호출의 Authorization 헤더에 실린다.
  final String accessToken;

  /// 초기화된 비밀번호로 로그인함 — 변경 전까지 다른 화면을 쓸 수 없다.
  final bool mustChangePassword;

  bool get isFranchiseOwner => ownerYn.trim().toUpperCase() == 'Y';

  /// 관리자 여부 (`user_mst.admin_yn`) — 전 메뉴/권한 허용.
  bool get isSuperAdmin => adminYn.trim().toUpperCase() == 'Y';

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    final permsRaw = json[jsonKeyMenuPermissions];
    final permissions = permsRaw is List
        ? permsRaw
              .whereType<Map<String, dynamic>>()
              .map(MenuPermission.fromJson)
              .toList()
        : const <MenuPermission>[];

    return AuthProfile(
      userIdx: asJsonIntOpt(json[jsonKeyUserIdx]),
      userId: json.jsonString(jsonKeyUserId),
      userNm: json.jsonString(jsonKeyUserNm),
      email: json.jsonString(jsonKeyEmail),
      deptIdx: asJsonIntOpt(json[jsonKeyDeptIdx]),
      userPhone: json.jsonString(jsonKeyUserPhone),
      deptNm: json.jsonString(jsonKeyDeptNm),
      positionCd: json.jsonString(jsonKeyPositionCd),
      positionNm: json.jsonString(jsonKeyPositionNm),
      svYn: json.jsonString(jsonKeySvYn),
      ownerYn: json.jsonString(jsonKeyOwnerYn),
      adminYn: json.jsonString(jsonKeyAdminYn),
      storeIdx: asJsonIntOpt(json[jsonKeyStoreIdx]),
      storeNm: json.jsonString(jsonKeyStoreNm),
      joinDtRaw: _joinDtString(json[jsonKeyJoinDt]),
      menuPermissions: permissions,
      accessToken: json.jsonString(jsonKeyAccessToken),
      mustChangePassword: json[jsonKeyMustChangePassword] == true,
    );
  }

  /// 토큰·메뉴권한이 비어 있는 응답에 기존 값을 이어붙인 사본.
  ///
  /// `/auth/profile` 응답은 토큰도 메뉴권한도 싣지 않는다(로그인 응답만 싣는다).
  /// 그대로 세션에 반영하면 **토큰이 사라져 즉시 로그아웃되고, 권한 목록이 비어
  /// 메뉴가 잘못 노출된다.** 비어 있는 항목만 이전 값으로 메워 그 사고를 막는다.
  AuthProfile carryOverSessionFrom(AuthProfile? previous) {
    if (previous == null) return this;
    final keepToken = accessToken.isEmpty ? previous.accessToken : accessToken;
    final keepPerms = menuPermissions.isEmpty
        ? previous.menuPermissions
        : menuPermissions;
    if (keepToken == accessToken && keepPerms == menuPermissions) return this;
    return AuthProfile(
      userIdx: userIdx,
      userId: userId,
      userNm: userNm,
      email: email,
      deptIdx: deptIdx,
      userPhone: userPhone,
      deptNm: deptNm,
      positionCd: positionCd,
      positionNm: positionNm,
      svYn: svYn,
      ownerYn: ownerYn,
      adminYn: adminYn,
      storeIdx: storeIdx,
      storeNm: storeNm,
      joinDtRaw: joinDtRaw,
      menuPermissions: keepPerms,
      accessToken: keepToken,
      mustChangePassword: mustChangePassword,
    );
  }

  /// 비밀번호 변경 완료 후: 강제 플래그를 내리고, 서버가 재발급한 토큰으로 갈아끼운 사본.
  ///
  /// 서버는 비밀번호가 바뀌면 기존 토큰을 모두 무효화한다. 새 토큰을 반영하지 않으면
  /// 변경 직후 모든 요청이 401 로 떨어진다.
  AuthProfile afterPasswordChange({String? reissuedToken}) => AuthProfile(
    userIdx: userIdx,
    userId: userId,
    userNm: userNm,
    email: email,
    deptIdx: deptIdx,
    userPhone: userPhone,
    deptNm: deptNm,
    positionCd: positionCd,
    positionNm: positionNm,
    svYn: svYn,
    ownerYn: ownerYn,
    adminYn: adminYn,
    storeIdx: storeIdx,
    storeNm: storeNm,
    joinDtRaw: joinDtRaw,
    menuPermissions: menuPermissions,
    accessToken: (reissuedToken != null && reissuedToken.isNotEmpty)
        ? reissuedToken
        : accessToken,
    mustChangePassword: false,
  );

  /// 비밀번호 변경 완료 후 강제 플래그를 내린 사본.
  AuthProfile clearMustChangePassword() => AuthProfile(
    userIdx: userIdx,
    userId: userId,
    userNm: userNm,
    email: email,
    deptIdx: deptIdx,
    userPhone: userPhone,
    deptNm: deptNm,
    positionCd: positionCd,
    positionNm: positionNm,
    svYn: svYn,
    ownerYn: ownerYn,
    adminYn: adminYn,
    storeIdx: storeIdx,
    storeNm: storeNm,
    joinDtRaw: joinDtRaw,
    menuPermissions: menuPermissions,
    accessToken: accessToken,
    mustChangePassword: false,
  );

  Map<String, dynamic> toJson() => {
    if (userIdx != null) jsonKeyUserIdx: userIdx,
    jsonKeyUserId: userId,
    jsonKeyUserNm: userNm,
    jsonKeyEmail: email,
    if (deptIdx != null) jsonKeyDeptIdx: deptIdx,
    jsonKeyUserPhone: userPhone,
    jsonKeyDeptNm: deptNm,
    jsonKeyPositionCd: positionCd,
    jsonKeyPositionNm: positionNm,
    jsonKeySvYn: svYn,
    jsonKeyOwnerYn: ownerYn,
    jsonKeyAdminYn: adminYn,
    if (storeIdx != null) jsonKeyStoreIdx: storeIdx,
    jsonKeyStoreNm: storeNm,
    jsonKeyJoinDt: joinDtRaw,
    if (accessToken.isNotEmpty) jsonKeyAccessToken: accessToken,
    if (mustChangePassword) jsonKeyMustChangePassword: true,
    jsonKeyMenuPermissions: menuPermissions.map((e) => e.toJson()).toList(),
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

  /// 출입관리 태그 권한 (`sv_yn`).
  bool get canUseStoreEntryTag => svYn.trim().toUpperCase() == 'Y';
}
