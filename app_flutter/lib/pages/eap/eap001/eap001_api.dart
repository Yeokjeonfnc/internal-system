// 전자결재 API.
//
// 이 파일의 원칙: **실패를 null 로 뭉개지 않는다.**
//
// 예전에는 대부분의 메서드가 `BaseRepository` 의 `*OrNull` 계열을 썼는데, 그 헬퍼들은
// 403(권한 없음)·500(서버 오류)·타임아웃·응답 파싱 실패를 **전부 null 하나로** 바꾼다.
// 그러면 호출하는 화면은 "권한이 없다" 와 "서버가 죽었다" 와 "그런 서식이 없다" 를
// 구분할 방법이 없다. 실제로 그래서 이런 오보가 나갔다:
//   - 권한이 없어 403 이 떨어져도 → "등록된 서식이 없습니다"
//   - 서버 오류로 조회가 실패해도 → "서식을 찾을 수 없습니다"
//   - 저장이 실패해도 → "서식을 등록했습니다"
// 이제 실패는 서버가 보낸 메시지를 담아 예외로 던지고, 화면이 그 사유를 그대로 보여 준다.

import 'package:dio/dio.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/pages/eap/eap001/eap001_model.dart';

abstract final class EapApiPaths {
  static const String forms = '/eap/forms';
  static String form(String formCode) => '/eap/forms/$formCode';
  static const String documents = '/eap/documents';
  static String document(String docId) => '/eap/documents/$docId';
  static String approve(String docId) => '/eap/documents/$docId/approve';
  static String reject(String docId) => '/eap/documents/$docId/reject';
  static const String draft = '/eap/draft';
}

class EapApiService extends BaseRepository {
  /// 실패 응답을 사용자에게 보여 줄 문장으로 바꾼다.
  ///
  /// 백엔드는 실패도 `{success:false, message:"..."}` 봉투로 내려보내므로
  /// 그 문장을 우선 쓴다(예: "이 작업을 수행할 권한이 없습니다.").
  /// 봉투가 없을 때만 상태코드를 붙인 기본 문구로 물러난다.
  Never _failResponse(Response<dynamic> r, String fallback) {
    final msg = envelopeMessage(r.data)?.trim();
    throw StateError(
      msg == null || msg.isEmpty ? '$fallback (${r.statusCode})' : msg,
    );
  }

  /// Dio 예외(네트워크 끊김·타임아웃·비2xx)를 같은 방식으로 문장화한다.
  Never _failDio(DioException e, String fallback) {
    throw StateError(dioErrorMessage(e, fallback: fallback));
  }

  Future<List<EapFormConfig>> listForms({bool enabledOnly = false}) async {
    try {
      final r = await client.get(
        EapApiPaths.forms,
        queryParameters: {'enabledOnly': enabledOnly},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '서식 목록을 불러오지 못했습니다');
      }
      return parseDataList(r.data, EapFormConfig.fromJson);
    } on DioException catch (e) {
      _failDio(e, '서식 목록을 불러오지 못했습니다.');
    }
  }

  /// 서식 1건. **없으면 null, 실패하면 예외** — 이 둘을 섞지 않는다.
  ///
  /// 백엔드는 없는 서식을 404 가 아니라 400(IllegalArgumentException)으로 내려보내므로
  /// 상태코드로 "없음" 을 판정하면 안 된다. 성공 응답인데 data 가 비어 있을 때만 없음이다.
  Future<EapFormConfig?> getForm(String formCode) async {
    try {
      final r = await client.get(EapApiPaths.form(formCode));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '서식을 불러오지 못했습니다');
      }
      return parseDataOrNull(r.data, EapFormConfig.fromJson);
    } on DioException catch (e) {
      _failDio(e, '서식을 불러오지 못했습니다.');
    }
  }

  Future<EapFormConfig> createForm(EapFormConfig form) async {
    try {
      final r = await client.post(EapApiPaths.forms, data: form.toCreateBody());
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '서식 등록에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, EapFormConfig.fromJson);
      if (saved == null) {
        throw StateError('서식 등록 응답을 해석하지 못했습니다. 목록에서 확인해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDio(e, '서식 등록에 실패했습니다.');
    }
  }

  Future<EapFormConfig> updateForm(EapFormConfig form) async {
    try {
      final r = await client.put(
        EapApiPaths.form(form.formCode),
        data: form.toUpdateBody(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '서식 수정에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, EapFormConfig.fromJson);
      if (saved == null) {
        throw StateError('서식 수정 응답을 해석하지 못했습니다. 목록에서 확인해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDio(e, '서식 수정에 실패했습니다.');
    }
  }

  Future<void> deleteForm(String formCode) async {
    try {
      final r = await client.delete(EapApiPaths.form(formCode));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '서식 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDio(e, '서식 삭제에 실패했습니다.');
    }
  }

  Future<List<EapDocument>> listDocuments(String folder) async {
    try {
      final r = await client.get(
        EapApiPaths.documents,
        queryParameters: {'folder': folder},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '문서 목록 조회에 실패했습니다');
      }
      return parseDataList(r.data, EapDocument.fromJson);
    } on DioException catch (e) {
      _failDio(e, '문서 목록 조회에 실패했습니다.');
    }
  }

  Future<EapDocument?> getDocument(String docId) async {
    try {
      final r = await client.get(EapApiPaths.document(docId));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '결재 문서를 불러오지 못했습니다');
      }
      return parseDataOrNull(r.data, EapDocument.fromJson);
    } on DioException catch (e) {
      _failDio(e, '결재 문서를 불러오지 못했습니다.');
    }
  }

  Future<EapDraftResult> draft(EapDraftRequest request) async {
    try {
      final r = await client.post(EapApiPaths.draft, data: request.toJson());
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '상신에 실패했습니다');
      }
      final result = parseDataOrNull(r.data, EapDraftResult.fromJson);
      if (result == null) {
        throw StateError('상신 응답을 해석하지 못했습니다. 문서함에서 확인해 주세요.');
      }
      return result;
    } on DioException catch (e) {
      _failDio(e, '상신에 실패했습니다.');
    }
  }

  Future<EapDocument> approve(String docId) async {
    try {
      final r = await client.post(
        EapApiPaths.approve(docId),
        data: const <String, dynamic>{},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '결재 처리에 실패했습니다');
      }
      return parseData(r.data, EapDocument.fromJson);
    } on DioException catch (e) {
      _failDio(e, '결재 처리에 실패했습니다.');
    }
  }

  Future<EapDocument> reject(String docId) async {
    try {
      final r = await client.post(
        EapApiPaths.reject(docId),
        data: const <String, dynamic>{},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '반려 처리에 실패했습니다');
      }
      return parseData(r.data, EapDocument.fromJson);
    } on DioException catch (e) {
      _failDio(e, '반려 처리에 실패했습니다.');
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      final r = await client.delete(EapApiPaths.document(docId));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '문서 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDio(e, '문서 삭제에 실패했습니다.');
    }
  }
}
