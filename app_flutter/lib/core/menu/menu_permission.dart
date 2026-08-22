import 'package:app_flutter/core/utils/json_extensions.dart';

/// 로그인·권한 API — 백엔드 `MenuPermissionDto`.
class MenuPermission {
  const MenuPermission({
    required this.menuCd,
    required this.menuNm,
    this.parentMenuCd,
    this.routePath,
    required this.menuType,
    this.sortOrder,
    required this.canView,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  static const String jsonKeyMenuCd = 'menuCd';
  static const String jsonKeyMenuNm = 'menuNm';
  static const String jsonKeyParentMenuCd = 'parentMenuCd';
  static const String jsonKeyRoutePath = 'routePath';
  static const String jsonKeyMenuType = 'menuType';
  static const String jsonKeySortOrder = 'sortOrder';
  static const String jsonKeyCanView = 'canView';
  static const String jsonKeyCanCreate = 'canCreate';
  static const String jsonKeyCanUpdate = 'canUpdate';
  static const String jsonKeyCanDelete = 'canDelete';

  final String menuCd;
  final String menuNm;
  final String? parentMenuCd;
  final String? routePath;
  final String menuType;
  final int? sortOrder;
  final bool canView;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  bool get isGroup => menuType == 'G';
  bool get isLeaf => menuType == 'L';

  factory MenuPermission.fromJson(Map<String, dynamic> json) {
    return MenuPermission(
      menuCd: json.jsonString(jsonKeyMenuCd),
      menuNm: json.jsonString(jsonKeyMenuNm),
      // 이 둘만 `as String?` 로 직접 변환하고 있었다. 서버나 저장본이 숫자·불리언을
      // 보내면 그 자리에서 TypeError 가 나고, 그 예외가 **세션 복원 전체를 무너뜨려
      // 로그인 상태가 통째로 날아간다.** 다른 필드처럼 방어적으로 읽는다.
      parentMenuCd: _readStringOrNull(json[jsonKeyParentMenuCd]),
      routePath: _readStringOrNull(json[jsonKeyRoutePath]),
      menuType: json.jsonString(jsonKeyMenuType),
      sortOrder: asJsonIntOpt(json[jsonKeySortOrder]),
      canView: _readBool(json[jsonKeyCanView]),
      canCreate: _readBool(json[jsonKeyCanCreate]),
      canUpdate: _readBool(json[jsonKeyCanUpdate]),
      canDelete: _readBool(json[jsonKeyCanDelete]),
    );
  }

  Map<String, dynamic> toJson() => {
    jsonKeyMenuCd: menuCd,
    jsonKeyMenuNm: menuNm,
    if (parentMenuCd != null) jsonKeyParentMenuCd: parentMenuCd,
    if (routePath != null) jsonKeyRoutePath: routePath,
    jsonKeyMenuType: menuType,
    if (sortOrder != null) jsonKeySortOrder: sortOrder,
    jsonKeyCanView: canView,
    jsonKeyCanCreate: canCreate,
    jsonKeyCanUpdate: canUpdate,
    jsonKeyCanDelete: canDelete,
  };

  MenuPermission copyWith({
    bool? canView,
    bool? canCreate,
    bool? canUpdate,
    bool? canDelete,
  }) => MenuPermission(
    menuCd: menuCd,
    menuNm: menuNm,
    parentMenuCd: parentMenuCd,
    routePath: routePath,
    menuType: menuType,
    sortOrder: sortOrder,
    canView: canView ?? this.canView,
    canCreate: canCreate ?? this.canCreate,
    canUpdate: canUpdate ?? this.canUpdate,
    canDelete: canDelete ?? this.canDelete,
  );

  bool get hasAnyPermission => canView || canCreate || canUpdate || canDelete;

  /// 문자열이면 그대로, 아니면 null. 타입이 어긋나도 예외를 던지지 않는다.
  static String? _readStringOrNull(Object? v) => v is String ? v : null;

  static bool _readBool(Object? v) {
    if (v == true) return true;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == 'y' || s == '1';
    }
    if (v is num) return v != 0;
    return false;
  }
}
