import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _rememberPassword = false;
  String? _savedUserId;
  String? _savedPassword;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get rememberPassword => _rememberPassword;
  String? get savedUserId => _savedUserId;
  String? get savedPassword => _savedPassword;

  String get userName => _user?['userNm']?.toString() ?? '';
  String get userId => _user?['userId']?.toString() ?? '';

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

    // 자동 로그인 체크
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = json.decode(userJson) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<void> login(
    Map<String, dynamic> userData, {
    required bool rememberPassword,
    required String userId,
    required String password,
  }) async {
    _user = userData;
    _rememberPassword = rememberPassword;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(userData));
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
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    notifyListeners();
  }
}
