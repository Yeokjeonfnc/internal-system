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
      final body = AuthLoginRequest(userId: userId, userPassword: userPassword);
      final response = await client.post(
        AuthApiPaths.login,
        data: body.toRequestBody(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseDataOrNull(response.data, AuthProfile.fromJson);
      }
    } on DioException catch (e) {
      debugPrint('로그인 에러: $e');
      rethrow;
    } catch (e, st) {
      // 여기로 오는 것은 응답 파싱·타입 오류 같은 **우리 쪽 결함**이다.
      // 예전에는 조용히 null 을 돌려줬는데, 그러면 화면에는 "아이디 또는 비밀번호가
      // 올바르지 않습니다" 로 표시된다. 비밀번호는 맞는데 로그인이 안 되는 상황에서
      // 사용자도 우리도 원인을 알 수 없게 된다. 로그로 남기고 그대로 올린다.
      debugPrint('로그인 응답 처리 실패: $e\n$st');
      rethrow;
    }
    return null;
  }

  /// 비밀번호 변경. [failure] 가 null 이면 성공이다.
  ///
  /// 대상 사용자는 서버가 토큰에서 판단하므로 요청에 담지 않는다. 서버는 변경과 동시에
  /// 기존 토큰을 모두 무효화하고 새 토큰을 [token] 으로 돌려주므로, 호출부는 이 값을
  /// 반드시 세션에 반영해야 한다(안 하면 직후 요청이 전부 401).
  Future<({String? failure, String? token})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await client.post(
        AuthApiPaths.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      if (response.statusCode == 200) {
        String? token;
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          final value = (data['data'] as Map)['accessToken'];
          if (value is String && value.isNotEmpty) token = value;
        }
        return (failure: null, token: token);
      }
      return (
        failure: envelopeMessage(response.data) ?? '비밀번호 변경에 실패했습니다.',
        token: null,
      );
    } on DioException catch (e) {
      return (
        failure: dioErrorMessage(e, fallback: '비밀번호 변경에 실패했습니다.'),
        token: null,
      );
    } catch (e) {
      debugPrint('비밀번호 변경 오류: $e');
      return (failure: '비밀번호 변경에 실패했습니다.', token: null);
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
