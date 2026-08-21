import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_flutter/core/auth/auth_api_service.dart';
import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/auth/auth_token_store.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/menu/menu_codes.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';
import 'package:app_flutter/core/router/app_router.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    AuthTokenStore.sessionExpired.addListener(_onSessionExpired);
  }

  AuthProfile? _profile;
  bool _rememberPassword = false;
  String? _savedUserId;
  String? _savedPassword;
  bool _sessionRestored = false;
  Future<void>? _restoreFuture;

  /// 서버가 401 을 돌려줬다 — 토큰 만료·무효화·서버 재시작 등.
  ///
  /// 세션을 끊어 라우터가 로그인 화면으로 보내게 한다. 이 처리가 없으면 화면은
  /// 로그인 상태로 남고 모든 목록이 빈 채로 그려져 데이터가 사라진 것처럼 보인다.
  void _onSessionExpired() {
    if (_profile == null) return;
    debugPrint('세션 만료(401) — 로그아웃 처리');
    unawaited(logout());
  }

  @override
  void dispose() {
    AuthTokenStore.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  /// 프로필 변경 시 API 인증 토큰도 함께 동기화한다.
  /// (`_profile` 에 직접 대입하지 말고 항상 이 메서드를 쓸 것 — 토큰이 어긋나면
  ///  모든 API 가 401 로 실패한다.)
  ///
  /// **토큰이 없는 프로필이 들어와도 기존 토큰을 지우지 않는다.** 로그인
  /// 응답만 토큰을 싣고, 프로필 조회·수정 응답(`/auth/profile`)은 토큰 자리가
  /// 비어 있다. 예전에는 이걸 로그아웃으로 오해해 토큰을 지웠고, 그 결과
  /// **"내 정보"를 저장하면 곧바로 로그인 화면으로 튕겼다.**
  /// 세션을 실제로 끊을 때는 [logout] 이 `null` 을 넘긴다 — 그때만 지운다.
  void _applyProfile(AuthProfile? next) {
    if (next == null) {
      _profile = null;
      AuthTokenStore.clear();
      return;
    }
    // 토큰·메뉴권한이 빠진 응답이면 직전 값을 이어붙인다(저장분에도 남도록
    // 저장소뿐 아니라 프로필 객체 자체를 보정한다 — 객체만 비어 있으면
    // 새로고침 때 "토큰 없는 세션"으로 판정돼 폐기된다).
    final merged = next.carryOverSessionFrom(_profile);
    _profile = merged;
    if (merged.accessToken.isNotEmpty) {
      AuthTokenStore.set(merged.accessToken);
    }
  }

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

      // 저장된 값 하나가 예상과 다른 타입이면 getString/getBool 이 예외를 던지고,
      // 그 예외가 아래 세션 복원까지 통째로 날려 버린다(= 전원 로그아웃).
      // 항목별로 막아서, 하나가 망가져도 나머지는 살린다.
      String? readString(String key) {
        try {
          final v = prefs.get(key);
          return v is String ? v : null;
        } catch (e) {
          debugPrint('저장값 읽기 실패(무시): $key — $e');
          return null;
        }
      }

      try {
        _rememberPassword = prefs.getBool('rememberPassword') ?? false;
      } catch (e) {
        debugPrint('저장값 읽기 실패(무시): rememberPassword — $e');
        _rememberPassword = false;
      }
      if (_rememberPassword) {
        _savedUserId = readString('savedUserId')?.trim();
        _savedPassword = readString('savedPassword');
      }

      final userJson = readString('user');
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final map = json.decode(userJson) as Map<String, dynamic>;
          final restored = AuthProfile.fromJson(map);
          if (restored.accessToken.isEmpty) {
            // 토큰 없는 저장 세션 = 서버 인증 도입 전에 저장된 것.
            // 그대로 복원하면 "로그인 상태"로 보이지만 모든 조회가 401 이 되어
            // 화면마다 빈 목록이 뜬다(데이터가 사라진 것처럼 보인다).
            // 로그인 화면으로 보내는 편이 정확하다.
            debugPrint('저장된 세션에 토큰이 없어 폐기 — 재로그인 필요');
            _applyProfile(null);
            await prefs.remove('user');
          } else {
            _applyProfile(restored);
          }
        } catch (e, st) {
          debugPrint('저장된 로그인 정보 파싱 실패: $e\n$st');
          _applyProfile(null);
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
      _applyProfile(profile);
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
    _applyProfile(profile);
    _rememberPassword = rememberPassword;

    final prefs = await SharedPreferences.getInstance();
    // 인자 profile 이 아니라 _applyProfile 이 보정한 _profile 을 저장한다.
    // (프로필 수정 응답처럼 토큰이 빠진 객체가 들어오면 여기서 원본을 저장해
    //  버려 저장분에만 토큰이 없어지고, 새로고침 시 세션이 폐기된다.)
    await prefs.setString('user', json.encode((_profile ?? profile).toJson()));
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

  /// 비밀번호 변경 완료 — 강제 플래그를 내리고, 재발급 토큰과 저장분에도 반영한다.
  ///
  /// 서버가 기존 토큰을 끊고 새 토큰을 돌려주므로, 강제 변경이 아니었더라도
  /// 토큰 교체는 반드시 해야 한다(안 하면 변경 직후 전부 401).
  Future<void> markPasswordChanged({String? reissuedToken}) async {
    final current = _profile;
    if (current == null) return;
    _applyProfile(current.afterPasswordChange(reissuedToken: reissuedToken));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_profile!.toJson()));
    // 비밀번호가 바뀌었으므로 저장된 자동로그인 비밀번호는 더 이상 유효하지 않다.
    await prefs.remove('savedPassword');
    _savedPassword = null;

    notifyListeners();
  }

  /// 로그아웃 — **자동 재로그인 재료까지 지운다.**
  ///
  /// 예전에는 `user` 키만 지웠다. 그런데 저장된 비밀번호(`savedPassword`)와
  /// `rememberPassword` 는 그대로 남아서, 로그인 화면에서 **새로고침만 해도
  /// 백그라운드 자동 로그인이 돌아 다시 들어가졌다.**
  /// 공용 PC 에서는 앞사람이 로그아웃하고 자리를 떠도, 다음 사람이 새로고침하면
  /// 앞사람 계정으로 들어가게 된다.
  ///
  /// 아이디(`savedUserId`)는 남겨 둔다 — 다음 로그인 때 입력칸을 채워 주는
  /// 편의 기능이고, 그것만으로는 세션이 살아나지 않는다.
  Future<void> logout() async {
    _applyProfile(null);
    _savedPassword = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('savedPassword');

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
    _applyProfile(
      AuthProfile(
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
        // 토큰이 빠지면 이후 모든 API 가 401 이 된다 — 반드시 유지.
        accessToken: current.accessToken,
      ),
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
