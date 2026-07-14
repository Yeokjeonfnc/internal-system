import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_flutter/core/auth/auth_api_service.dart';
import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';
import 'package:app_flutter/core/router/app_router.dart';

class AuthProvider extends ChangeNotifier {
  AuthProfile? _profile;
  bool _rememberPassword = false;
  String? _savedUserId;
  String? _savedPassword;
  bool _sessionRestored = false;
  Future<void>? _restoreFuture;

  AuthProfile? get profile => _profile;

  bool get isLoggedIn => _profile != null;

  /// [ensureSessionRestored] 완료 후에만 라우터·UI가 로그인 상태를 판단해야 한다.
  bool get isSessionRestored => _sessionRestored;

  bool get rememberPassword => _rememberPassword;
  String? get savedUserId => _savedUserId;
  String? get savedPassword => _savedPassword;

  String get userName => _profile?.userNm ?? '';
  String get userId => _profile?.userId ?? '';
  String get positionNm => _profile?.positionNm ?? '';

  bool get isFranchiseOwner => _profile?.isFranchiseOwner ?? false;

  /// 슈퍼 관리자 여부 (`user_mst.admin_yn`) — 모든 메뉴/권한을 무조건 허용한다.
  bool get isSuperAdmin => _profile?.isSuperAdmin ?? false;

  /// 실제로 부여된 권한이 하나라도 있을 때만 메뉴/라우트를 제한한다.
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

  /// 관리자 전용 메뉴 — 슈퍼 관리자만 접근/조회할 수 있다.
  static bool _isAdminOnlyMenu(String menuCd) => menuCd == kMenuMst003;

  bool canViewMenu(String menuCd) {
    if (_profile == null) {
      return false;
    }
    if (isSuperAdmin) {
      return true;
    }
    if (_isAdminOnlyMenu(menuCd)) {
      return false;
    }
    if (isFranchiseOwner) {
      return menuCd == kMenuBbs001;
    }
    return _check(menuCd, (p) => p.canView);
  }

  bool canCreateMenu(String menuCd) {
    if (isSuperAdmin) return true;
    if (_isAdminOnlyMenu(menuCd)) return false;
    if (isFranchiseOwner) return menuCd == kMenuBbs001;
    return _check(menuCd, (p) => p.canCreate);
  }

  bool canUpdateMenu(String menuCd) {
    if (isSuperAdmin) return true;
    if (_isAdminOnlyMenu(menuCd)) return false;
    if (isFranchiseOwner) return menuCd == kMenuBbs001;
    return _check(menuCd, (p) => p.canUpdate);
  }

  bool canDeleteMenu(String menuCd) {
    if (isSuperAdmin) return true;
    if (_isAdminOnlyMenu(menuCd)) return false;
    if (isFranchiseOwner) return menuCd == kMenuBbs001;
    return _check(menuCd, (p) => p.canDelete);
  }

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
    if (isSuperAdmin) {
      return true;
    }
    if (isFranchiseOwner) {
      return path == AppRoutes.board || path.startsWith('${AppRoutes.board}/');
    }
    final menuCd = menuCdForPath(path);
    // 메뉴권한 관리는 권한 미설정 계정에도 노출하지 않는다(관리자 전용).
    if (menuCd != null && _isAdminOnlyMenu(menuCd)) {
      return false;
    }
    if (!usesMenuPermissions) {
      return true;
    }
    if (menuCd == null) {
      return true;
    }
    if (isMenuCreatePath(path)) {
      return canCreateMenu(menuCd);
    }
    if (menuCd == kMenuAct004 && !canViewMenu(kMenuAct004)) {
      return canViewMenu(kMenuAct002);
    }
    if (menuCd == kMenuEap001 && !canViewMenu(kMenuEap001)) {
      return canViewMenu(kMenuAct002) || canViewMenu(kMenuAct003);
    }
    return canViewMenu(menuCd);
  }

  String? get firstAllowedPath {
    if (isFranchiseOwner) return AppRoutes.board;
    return firstAllowedRoute(canViewMenu);
  }

  /// 앱 시작 시 한 번 호출 — SharedPreferences 복원·(선택) 자동 재로그인.
  Future<void> ensureSessionRestored() {
    return _restoreFuture ??= _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberPassword = prefs.getBool('rememberPassword') ?? false;
      if (_rememberPassword) {
        _savedUserId = prefs.getString('savedUserId')?.trim();
        _savedPassword = prefs.getString('savedPassword');
      }

      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final map = json.decode(userJson) as Map<String, dynamic>;
          _profile = AuthProfile.fromJson(map);
        } catch (e, st) {
          debugPrint('저장된 로그인 정보 파싱 실패: $e\n$st');
          _profile = null;
          await prefs.remove('user');
        }
      }
    } catch (e, st) {
      debugPrint('세션 복원 실패: $e\n$st');
    } finally {
      // 로컬 복원 완료 — 첫 프레임을 즉시 띄운다.
      _sessionRestored = true;
      notifyListeners();
    }

    // 캐시된 프로필이 없을 때만 자동 로그인을 백그라운드로 시도한다.
    // (네트워크 로그인이 시작 화면을 막지 않도록 await 하지 않는다.)
    if (_profile == null && _rememberPassword) {
      unawaited(_silentLoginInBackground());
    }
  }

  /// 백그라운드 자동 로그인 — 성공하면 라우터/UI 를 갱신한다.
  Future<void> _silentLoginInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _trySilentLogin(prefs);
    } catch (e, st) {
      debugPrint('백그라운드 자동 로그인 실패: $e\n$st');
    } finally {
      if (_profile != null) notifyListeners();
    }
  }

  /// 프로필 캐시가 없을 때 비밀번호 기억에 저장된 계정으로 재로그인.
  Future<void> _trySilentLogin(SharedPreferences prefs) async {
    if (!_rememberPassword) return;
    final userId = _savedUserId?.trim() ?? '';
    final password = _savedPassword ?? '';
    if (userId.isEmpty || password.isEmpty) return;

    try {
      final profile = await AuthApiService().login(
        userId: userId,
        userPassword: password,
      );
      if (profile == null) {
        debugPrint('자동 로그인: 서버 인증 실패 ($userId)');
        return;
      }
      _profile = profile;
      await prefs.setString('user', json.encode(profile.toJson()));
      if (kDebugMode) {
        debugPrint('자동 로그인 성공: $userId');
      }
    } catch (e, st) {
      debugPrint('자동 로그인 API 오류: $e\n$st');
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

  Future<void> applyMenuPermissionsForUser(
    int userIdx,
    List<MenuPermission> perms, {
    String? userId,
  }) async {
    final current = _profile;
    if (current == null || !_isSameUser(current, userIdx, userId)) {
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
      ownerYn: current.ownerYn,
      adminYn: current.adminYn,
      storeIdx: current.storeIdx,
      storeNm: current.storeNm,
      joinDtRaw: current.joinDtRaw,
      menuPermissions: List<MenuPermission>.unmodifiable(perms),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_profile!.toJson()));

    notifyListeners();
  }

  static bool _isSameUser(AuthProfile current, int userIdx, String? userId) {
    if (current.userIdx != null && current.userIdx == userIdx) {
      return true;
    }
    final uid = userId?.trim();
    if (uid != null && uid.isNotEmpty && current.userId == uid) {
      return true;
    }
    return false;
  }
}
