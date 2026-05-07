import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';

class AuthApiService extends BaseRepository {
  Future<Map<String, dynamic>?> login({
    required String userId,
    required String userPassword,
  }) async {
    try {
      final response = await client.post(
        '/auth/login',
        data: {
          'userId': userId,
          'userPassword': userPassword,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(
          response.data,
          (m) => m,
        );
      }
    } catch (e) {
      debugPrint('로그인 에러: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client.get(
        '/auth/profile',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, (m) => m);
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

      final response = await client.put(
        '/auth/profile',
        queryParameters: {'userId': userId},
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, (m) => m);
      }
    } catch (e) {
      debugPrint('사용자 정보 수정 에러: $e');
    }
    return null;
  }
}
