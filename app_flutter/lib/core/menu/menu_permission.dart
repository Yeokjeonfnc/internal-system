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
      parentMenuCd: json[jsonKeyParentMenuCd] as String?,
      routePath: json[jsonKeyRoutePath] as String?,
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
  }) =>
      MenuPermission(
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

  bool get hasAnyPermission =>
      canView || canCreate || canUpdate || canDelete;

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
