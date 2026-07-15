import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_profile.dart';
import 'package:app_flutter/core/auth/auth_write_request.dart';

class AuthApiService extends BaseRepository {
  Future<AuthProfile?> login({
    required String userId,
    required String userPassword,
  }) async {
    try {
      final body = AuthLoginRequest(
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
      return null;
    } on DioException catch (e) {
      debugPrint('로그인 에러: ${dioErrorMessage(e)}');
      // 401 등 — 화면에서 서버 message를 보여주도록 재던짐(원문 Dio 덤프는 숨김)
      throw StateError(
        dioErrorMessage(e, fallback: '아이디 또는 비밀번호가 일치하지 않습니다.'),
      );
    } catch (e) {
      debugPrint('로그인 에러: $e');
      rethrow;
    }
  }

  Future<AuthProfile?> getUserProfile(String userId) async {
    try {
      final response = await client.get(
        AuthApiPaths.profile,
        queryParameters: {AuthLoginRequest.jsonKeyUserId: userId},
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
  }) async {
    try {
      final body = AuthProfileUpdateRequest(
        userName: userName,
        userPassword: userPassword,
        userPhone: userPhone,
        positionCd: positionCd,
        svYn: svYn,
      );

      final response = await client.put(
        AuthApiPaths.profile,
        queryParameters: {AuthLoginRequest.jsonKeyUserId: userId},
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
