import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';

abstract final class MenuPermissionApiPaths {
  static String userPermissions(int userIdx) =>
      '${UserMstApiPaths.one(userIdx)}/menu-permissions';
}

class UserMenuPermissionSaveRequest {
  const UserMenuPermissionSaveRequest({required this.items});

  final List<UserMenuPermissionSaveItem> items;

  Map<String, dynamic> toRequestBody() => {
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class UserMenuPermissionSaveItem {
  const UserMenuPermissionSaveItem({
    required this.menuCd,
    required this.canView,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  final String menuCd;
  final bool canView;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  Map<String, dynamic> toJson() => {
        'menuCd': menuCd,
        'canView': canView,
        'canCreate': canCreate,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
      };
}

class Mst003ApiService extends BaseRepository {
  Future<List<MenuPermission>> fetchUserPermissions(int userIdx) => getDataList(
        MenuPermissionApiPaths.userPermissions(userIdx),
        fromJson: MenuPermission.fromJson,
      );

  Future<void> saveUserPermissions(
    int userIdx,
    UserMenuPermissionSaveRequest body,
  ) async {
    await client.put(
      MenuPermissionApiPaths.userPermissions(userIdx),
      data: body.toRequestBody(),
    );
  }
}
