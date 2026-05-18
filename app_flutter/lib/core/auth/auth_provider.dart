import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';

class AuthProvider extends ChangeNotifier {
  AuthProfile? _profile;
  bool _rememberPassword = false;
  String? _savedUserId;
  String? _savedPassword;

  AuthProfile? get profile => _profile;

  bool get isLoggedIn => _profile != null;
  bool get rememberPassword => _rememberPassword;
  String? get savedUserId => _savedUserId;
  String? get savedPassword => _savedPassword;

  String get userName => _profile?.userNm ?? '';
  String get userId => _profile?.userId ?? '';
  String get positionNm => _profile?.positionNm ?? '';

  /// 실제로 부여된 권한이 하나라도 있을 때만 메뉴/라우트를 제한한다.
  /// (빈 목록·전부 false·DB 미적용 → 기존처럼 전체 허용)
  bool get usesMenuPermissions =>
      _profile != null &&
      _profile!.menuPermissions.any((p) => p.hasAnyPermission);

  MenuPermission? permissionFor(String menuCd) {
    if (_profile == null || !usesMenuPermissions) {
      return null;
    }
    for (final p in _profile!.menuPermissions) {
      if (p.menuCd == menuCd) {
        return p;
      }
    }
    return null;
  }

  bool canViewMenu(String menuCd) => _check(menuCd, (p) => p.canView);

  bool canCreateMenu(String menuCd) => _check(menuCd, (p) => p.canCreate);

  bool canUpdateMenu(String menuCd) => _check(menuCd, (p) => p.canUpdate);

  bool canDeleteMenu(String menuCd) => _check(menuCd, (p) => p.canDelete);

  bool _check(String menuCd, bool Function(MenuPermission p) flag) {
    if (_profile == null) {
      return false;
    }
    if (!usesMenuPermissions) {
      return true;
    }
    final p = permissionFor(menuCd);
    return p != null && flag(p);
  }

  bool canAccessPath(String path) {
    if (_profile == null) {
      return false;
    }
    if (!usesMenuPermissions) {
      return true;
    }
    final menuCd = menuCdForPath(path);
    if (menuCd == null) {
      return true;
    }
    if (isMenuCreatePath(path)) {
      return canCreateMenu(menuCd);
    }
    return canViewMenu(menuCd);
  }

  String? get firstAllowedPath => firstAllowedRoute(canViewMenu);

  AuthProvider() {
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberPassword = prefs.getBool('rememberPassword') ?? false;
    if (_rememberPassword) {
      _savedUserId = prefs.getString('savedUserId');
      _savedPassword = prefs.getString('savedPassword');
    }

    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final map = json.decode(userJson) as Map<String, dynamic>;
        _profile = AuthProfile.fromJson(map);
      } catch (_) {
        _profile = null;
      }
      notifyListeners();
    }
  }

  Future<void> login(
    AuthProfile profile, {
    required bool rememberPassword,
    required String userId,
    required String password,
  }) async {
    _profile = profile;
    _rememberPassword = rememberPassword;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(profile.toJson()));
    await prefs.setBool('rememberPassword', rememberPassword);

    if (rememberPassword) {
      await prefs.setString('savedUserId', userId);
      await prefs.setString('savedPassword', password);
      _savedUserId = userId;
      _savedPassword = password;
    } else {
      await prefs.remove('savedUserId');
      await prefs.remove('savedPassword');
      _savedUserId = null;
      _savedPassword = null;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _profile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    notifyListeners();
  }

  /// mst003 등에서 본인 권한을 변경했을 때 로컬 캐시를 갱신한다.
  /// 권한이 변경된 사원이 현재 로그인 사용자일 때만 [perms]를 반영하고,
  /// SharedPreferences의 user 캐시도 새 값으로 덮어쓴다.
  Future<void> applyMenuPermissionsForUser(
    int userIdx,
    List<MenuPermission> perms,
  ) async {
    final current = _profile;
    if (current == null || current.userIdx != userIdx) {
      return;
    }
    _profile = AuthProfile(
      userIdx: current.userIdx,
      userId: current.userId,
      userNm: current.userNm,
      email: current.email,
      deptIdx: current.deptIdx,
      userPhone: current.userPhone,
      deptNm: current.deptNm,
      positionCd: current.positionCd,
      positionNm: current.positionNm,
      svYn: current.svYn,
      tagYn: current.tagYn,
      joinDtRaw: current.joinDtRaw,
      menuPermissions: List<MenuPermission>.unmodifiable(perms),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_profile!.toJson()));

    notifyListeners();
  }
}
