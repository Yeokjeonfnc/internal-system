// 사원(mst001) API.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/user_mst/user_id_availability.dart';
import 'package:app_flutter/core/user_mst/user_mst_write_request.dart';
import 'package:app_flutter/pages/master/mst001/mst001_model.dart';

/// [Mst001ApiService.resetPassword] 결과 — 실패해도 예외를 던지지 않고
/// 사유를 그대로 돌려준다(일괄 처리 중 몇 명 실패했는지 요약해야 하므로).
typedef ResetPasswordResult = ({bool ok, String? failure});

class Mst001ApiService extends BaseRepository {
  Future<List<User>> getUsers({int? deptIdx}) async {
    final qp = deptIdx != null
        ? <String, dynamic>{UserMstWriteRequest.jsonKeyDeptIdx: deptIdx}
        : null;
    try {
      final r = await client.get(UserMstApiPaths.root, queryParameters: qp);
      if (r.statusCode != 200 || r.data == null) {
        debugPrint('getUsers HTTP ${r.statusCode}');
        return const [];
      }
      final root = parseEnvelopeRoot(r.data);
      if (root == null) {
        debugPrint('getUsers: invalid envelope');
        return const [];
      }
      final data = root['data'];
      if (data is! List) {
        debugPrint('getUsers: data is not a list (${data.runtimeType})');
        return const [];
      }
      final users = <User>[];
      var skipped = 0;
      for (final raw in data) {
        if (raw is! Map) continue;
        try {
          users.add(User.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e, st) {
          skipped++;
          debugPrint('getUsers row parse skip: $e\n$raw\n$st');
        }
      }
      if (skipped > 0) {
        debugPrint('getUsers: parsed ${users.length}, skipped $skipped');
      }
      return users;
    } catch (e, st) {
      debugPrint('getUsers failed: $e\n$st');
      rethrow;
    }
  }

  Future<User> getUser(int userIdx) =>
      getData(UserMstApiPaths.one(userIdx), fromJson: User.fromJson);

  /// 로그인 ID 사용 가능 여부. [true] 이면 중복 없음(등록 가능).
  ///
  /// 쿼리 키가 `userId` 가 아니라 `candidateUserId` 인 이유: 서버의 인증 필터가
  /// `userId` 파라미터를 "호출자 신분 주장"으로 보고 토큰 주인과 다르면 403 을
  /// 던진다. 여기 넘기는 값은 아직 없는 새 ID 라 항상 403 이 되어 신규 계정
  /// 등록이 통째로 막혔었다.
  Future<bool> isUserIdAvailable(String userId) async {
    final v = await getDataOrNull(
      UserMstApiPaths.checkUserId,
      queryParameters: {'candidateUserId': userId},
      fromJson: UserIdAvailability.fromJson,
    );
    return v?.available ?? false;
  }

  Future<User> createUser(UserMstWriteRequest body) =>
      postData(UserMstApiPaths.root, data: body.toRequestBody(), fromJson: User.fromJson);

  Future<User> updateUser(int userIdx, UserMstWriteRequest body) =>
      putData(UserMstApiPaths.one(userIdx), data: body.toRequestBody(), fromJson: User.fromJson);

  Future<void> deleteUser(int userIdx) async {
    await client.delete(UserMstApiPaths.one(userIdx));
  }

  /// 퇴사자 목록 — 관리자 전용.
  Future<List<User>> getResignedUsers() async {
    try {
      final r = await client.get(UserMstApiPaths.resigned);
      if (r.statusCode != 200 || r.data == null) return const [];
      final root = parseEnvelopeRoot(r.data);
      final data = root?['data'];
      if (data is! List) return const [];
      final users = <User>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        try {
          users.add(User.fromJson(Map<String, dynamic>.from(raw)));
        } catch (e) {
          debugPrint('getResignedUsers row parse skip: $e');
        }
      }
      return users;
    } catch (e, st) {
      debugPrint('getResignedUsers failed: $e\n$st');
      rethrow;
    }
  }

  /// 퇴사 처리 — 계정 행은 유지하고 재직 플래그만 내린다(관리자 전용).
  Future<User> resignUser(int userIdx, {required String leaveDt}) => postData(
        '${UserMstApiPaths.one(userIdx)}/resign',
        data: {'leaveDt': leaveDt},
        fromJson: User.fromJson,
      );

  /// 비밀번호를 초기값으로 되돌린다. 로그인ID가 없는 사원 등 서버가 거부한
  /// 경우도 예외를 던지지 않고 사유를 그대로 돌려준다(일괄 처리용).
  Future<ResetPasswordResult> resetPassword(int userIdx) async {
    try {
      final r = await client.post('${UserMstApiPaths.one(userIdx)}/reset-password');
      if (r.statusCode == 200) return (ok: true, failure: null);
      return (ok: false, failure: readEnvelopeMessage(r.data) ?? '초기화에 실패했습니다.');
    } on DioException catch (e) {
      return (ok: false, failure: dioErrorMessage(e, fallback: '초기화에 실패했습니다.'));
    } catch (e) {
      debugPrint('resetPassword failed: $e');
      return (ok: false, failure: '초기화에 실패했습니다.');
    }
  }

  /// 사번(선택 항목) 조회 — 서버에 컬럼이 아직 없으면 null.
  Future<String?> getEmpNo(int userIdx) async {
    try {
      final r = await client.get('${UserMstApiPaths.one(userIdx)}/emp-no');
      final root = parseEnvelopeRoot(r.data);
      final data = root?['data'];
      if (data is Map) {
        return data['empNo']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('getEmpNo failed: $e');
      return null;
    }
  }

  /// 사번(선택 항목) 저장. 서버에 컬럼이 아직 없으면 실패 사유를 돌려준다.
  Future<String?> updateEmpNo(int userIdx, String empNo) async {
    try {
      final r = await client.put(
        '${UserMstApiPaths.one(userIdx)}/emp-no',
        data: {'empNo': empNo},
      );
      if (r.statusCode == 200) return null;
      return readEnvelopeMessage(r.data) ?? '사번 저장에 실패했습니다.';
    } on DioException catch (e) {
      return dioErrorMessage(e, fallback: '사번 저장에 실패했습니다.');
    } catch (e) {
      debugPrint('updateEmpNo failed: $e');
      return '사번 저장에 실패했습니다.';
    }
  }
}
