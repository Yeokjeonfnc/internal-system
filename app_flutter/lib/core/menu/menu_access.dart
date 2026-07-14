import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart' as provider;

import 'package:app_flutter/core/auth/auth_provider.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';

/// 화면에서 메뉴 권한 조회 — [AuthProvider] 래퍼.
extension MenuAccessContext on BuildContext {
  AuthProvider get _menuAuth =>
      provider.Provider.of<AuthProvider>(this);

  bool menuCanView(String menuCd) => _menuAuth.canViewMenu(menuCd);

  bool menuCanCreate(String menuCd) => _menuAuth.canCreateMenu(menuCd);

  bool menuCanUpdate(String menuCd) => _menuAuth.canUpdateMenu(menuCd);

  bool menuCanDelete(String menuCd) => _menuAuth.canDeleteMenu(menuCd);

  bool pathCanView(String path) => _menuAuth.canAccessPath(path);

  bool pathCanCreate(String path) {
    final cd = menuCdForPath(path);
    if (cd == null) return true;
    return menuCanCreate(cd);
  }

  bool pathCanUpdate(String path) {
    final cd = menuCdForPath(path);
    if (cd == null) return true;
    return menuCanUpdate(cd);
  }
}
