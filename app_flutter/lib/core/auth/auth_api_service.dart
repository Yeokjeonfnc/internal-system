import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/auth/auth_write_payload.dart';

class AuthApiService extends BaseRepository {
  Future<AuthProfile?> login({
    required String userId,
    required String userPassword,
  }) async {
    try {
      final body = AuthLoginPayload(
        userId: userId,
        userPassword: userPassword,
      );
      final response = await client.post(
        AuthApiPaths.login,
        data: body.toRequestBody(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, AuthProfile.fromJson);
      }
    } catch (e) {
      debugPrint('로그인 에러: $e');
    }
    return null;
  }

  Future<AuthProfile?> getUserProfile(String userId) async {
    try {
      final response = await client.get(
        AuthApiPaths.profile,
        queryParameters: {AuthLoginPayload.jsonKeyUserId: userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, AuthProfile.fromJson);
      }
    } catch (e) {
      debugPrint('사용자 정보 조회 에러: $e');
    }
    return null;
  }

  Future<AuthProfile?> updateUserProfile({
    required String userId,
    String? userName,
    String? userPassword,
    String? userPhone,
    String? positionCd,
    String? svYn,
    String? tagYn,
  }) async {
    try {
      final body = AuthProfileUpdatePayload(
        userName: userName,
        userPassword: userPassword,
        userPhone: userPhone,
        positionCd: positionCd,
        svYn: svYn,
        tagYn: tagYn,
      );

      final response = await client.put(
        AuthApiPaths.profile,
        queryParameters: {AuthLoginPayload.jsonKeyUserId: userId},
        data: body.toRequestBody(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, AuthProfile.fromJson);
      }
    } catch (e) {
      debugPrint('사용자 정보 수정 에러: $e');
    }
    return null;
  }
}
