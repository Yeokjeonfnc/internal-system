import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/development/dev001/dev001_model.dart';
import 'package:app_flutter/core/partner_mst/partner_mst_write_request.dart';

/// 예비창업자 API — 백엔드 `DevController` (`/partners`).
class PartnerApiService extends BaseRepository {
  Future<List<Partner>> fetchList() async {
    try {
      return await getDataList(PartnerMstApiPaths.root, fromJson: Partner.fromJson);
    } catch (e) {
      debugPrint('Error fetching partners: $e');
    }
    return const [];
  }

  Future<Partner?> fetchOne(int partnerIdx) async {
    try {
      return await getDataOrNull(
        PartnerMstApiPaths.one(partnerIdx),
        fromJson: Partner.fromJson,
      );
    } catch (e) {
      debugPrint('Error fetching partner: $e');
    }
    return null;
  }

  /// 이메일 사용 가능 여부. [true] 이면 중복 없음(등록·수정 가능).
  /// [excludePartnerIdx] 는 수정 시 본인 제외.
  Future<bool> isEmailAvailable(
    String email, {
    int? excludePartnerIdx,
  }) async {
    try {
      final data = await getDataMapOrNull(
        PartnerMstApiPaths.checkEmail,
        queryParameters: {
          'email': email,
          if (excludePartnerIdx != null) 'excludePartnerIdx': excludePartnerIdx,
        },
      );
      if (data == null) return false;
      return data['available'] == true;
    } catch (e) {
      debugPrint('Error checking partner email: $e');
      return false;
    }
  }

  /// 신규 등록. 실패 시 서버 [message]를 [onServerMessage]로 전달(이메일 중복 400 등).
  Future<Partner?> create(
    PartnerMstWriteRequest body, {
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('createPartner: $m');
      }
    }

    try {
      final r = await client.post(
        PartnerMstApiPaths.root,
        data: body.toRequestBody(),
      );
      if (r.data == null) {
        fail('서버 응답이 비어 있습니다.');
        return null;
      }
      if (!envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '등록에 실패했습니다.');
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) {
        fail('등록에 실패했습니다.');
        return null;
      }
      final partner = parseDataOrNull(r.data, Partner.fromJson);
      if (partner == null) {
        fail('응답 데이터를 해석할 수 없습니다.');
      }
      return partner;
    } catch (e, st) {
      debugPrint('Error creating partner: $e\n$st');
      if (e is DioException) {
        final apiMsg = dioErrorMessage(e, fallback: '등록에 실패했습니다.');
        fail(apiMsg);
        return null;
      }
      fail(formatApiUserMessage(e, fallback: '등록에 실패했습니다.'));
    }
    return null;
  }

  /// 수정. 실패 시 서버 [message]를 [onServerMessage]로 전달(이메일 중복 400 등).
  Future<Partner?> update(
    int partnerIdx,
    PartnerMstWriteRequest body, {
    void Function(String message)? onServerMessage,
  }) async {
    void fail(String m) {
      if (onServerMessage != null) {
        onServerMessage(m);
      } else {
        debugPrint('updatePartner: $m');
      }
    }

    try {
      final r = await client.put(
        PartnerMstApiPaths.one(partnerIdx),
        data: body.toRequestBody(),
      );
      if (r.data == null) {
        fail('서버 응답이 비어 있습니다.');
        return null;
      }
      if (!envelopeSuccess(r.data)) {
        fail(envelopeMessage(r.data) ?? '저장에 실패했습니다.');
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) {
        fail('저장에 실패했습니다.');
        return null;
      }
      final partner = parseDataOrNull(r.data, Partner.fromJson);
      if (partner == null) {
        fail('응답 데이터를 해석할 수 없습니다.');
      }
      return partner;
    } catch (e, st) {
      debugPrint('Error updating partner: $e\n$st');
      if (e is DioException) {
        final apiMsg = dioErrorMessage(e, fallback: '저장에 실패했습니다.');
        fail(apiMsg);
        return null;
      }
      fail(formatApiUserMessage(e, fallback: '저장에 실패했습니다.'));
    }
    return null;
  }

  Future<bool> deletePartner(int partnerIdx) =>
      deleteOk(PartnerMstApiPaths.one(partnerIdx));
}
