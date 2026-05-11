import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:app_flutter/core/auth/auth_profile.dart';

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
}
