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
    );
  }

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
        jsonKeyMenuPermissions:
            menuPermissions.map((e) => e.toJson()).toList(),
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
