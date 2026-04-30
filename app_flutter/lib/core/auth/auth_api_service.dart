import 'package:flutter/foundation.dart';
import 'package:app_flutter/core/api/api_client.dart';

class AuthApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>?> login({
    required String userId,
    required String userPassword,
  }) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {
          'userId': userId,
          'userPassword': userPassword,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('로그인 에러: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client.get('/auth/profile?userId=$userId');

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('사용자 정보 조회 에러: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateUserProfile({
    required String userId,
    String? userName,
    String? userPassword,
    String? userPhone,
    String? positionCd,
    String? svYn,
    String? tagYn,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (userName != null) data['userName'] = userName;
      if (userPassword != null && userPassword.isNotEmpty) {
        data['userPassword'] = userPassword;
      }
      if (userPhone != null) data['userPhone'] = userPhone;
      if (positionCd != null) data['positionCd'] = positionCd;
      if (svYn != null) data['svYn'] = svYn;
      if (tagYn != null) data['tagYn'] = tagYn;

      final response = await _client.put(
        '/auth/profile?userId=$userId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('사용자 정보 수정 에러: $e');
    }
    return null;
  }
}
