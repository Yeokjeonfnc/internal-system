import 'dart:async';

import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/menu/menu_permission.dart';
import 'package:app_flutter/core/menu/menu_route_access.dart';
import 'package:app_flutter/core/router/route_meta.dart';
import 'package:app_flutter/core/usage_log/usage_log_api.dart';

/// 라우트 변경 시 메뉴 사용 기록(중복·로그인 경로 제외).
class UsageLogRecorder {
  UsageLogRecorder._();
  static final UsageLogRecorder instance = UsageLogRecorder._();

  static const _quietAfterFailure = Duration(seconds: 45);

  String? _lastLoggedPath;
  DateTime? _skipUntil;
  final _api = UsageLogApiService();

  void onRouteChanged({
    required String path,
    required AuthProfile? profile,
    MenuPermission? Function(String menuCd)? permissionFor,
  }) {
    if (profile == null) return;
    if (path == '/login' || path.isEmpty) return;
    if (_lastLoggedPath == path) return;
    _lastLoggedPath = path;

    final until = _skipUntil;
    if (until != null && DateTime.now().isBefore(until)) return;

    final menuCd = menuCdForPath(path);
    if (menuCd == null) return;

    final perm = permissionFor?.call(menuCd);
    final label = _menuLabel(
      menuCd: menuCd,
      permissionMenuNm: perm?.menuNm,
      path: path,
    );

    unawaited(
      _send(
        userId: profile.userId,
        userNm: profile.userNm,
        deptNm: profile.deptNm,
        positionNm: profile.positionNm,
        svYn: profile.svYn,
        menuCd: menuCd,
        menuLabel: label,
      ),
    );
  }

  Future<void> _send({
    required String userId,
    required String userNm,
    String? deptNm,
    String? positionNm,
    String? svYn,
    required String menuCd,
    required String menuLabel,
  }) async {
    final ok = await _api.recordMenu(
      userId: userId,
      userNm: userNm,
      deptNm: deptNm,
      positionNm: positionNm,
      svYn: svYn,
      menuCd: menuCd,
      menuLabel: menuLabel,
    );
    _skipUntil = ok ? null : DateTime.now().add(_quietAfterFailure);
  }

  static String _menuLabel({
    required String menuCd,
    String? permissionMenuNm,
    required String path,
  }) {
    final fromPerm = permissionMenuNm?.trim();
    if (fromPerm != null && fromPerm.isNotEmpty) {
      return _shortenMenuLabel(fromPerm);
    }
    final title = resolveRouteMeta(path).title.trim();
    if (title.isNotEmpty && title != '역전에프앤씨') {
      return _shortenMenuLabel(title);
    }
    return menuCd;
  }

  static String _shortenMenuLabel(String name) {
    if (name.endsWith('관리') && name.length > 2) {
      return name.substring(0, name.length - 2);
    }
    if (name.endsWith('조회') && name.length > 2) {
      return name.substring(0, name.length - 2);
    }
    return name;
  }
}
