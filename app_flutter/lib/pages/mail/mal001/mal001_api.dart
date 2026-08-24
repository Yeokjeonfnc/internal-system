// 메일(mal001) API.
//
// 이 파일의 원칙은 `eap001_api.dart` 와 같다: **실패를 null 로 뭉개지 않는다.**
//
// `BaseRepository` 의 `*OrNull` 계열 헬퍼는 403(권한 없음)·500(서버 오류)·타임아웃·
// 파싱 실패를 전부 null 하나로 바꿔 버린다. 그러면 화면은 "권한이 없다"와 "서버가
// 죽었다"와 "메일이 없다"를 구분할 방법이 없고, 전자결재에서 실제로 그 때문에
// "등록된 서식이 없습니다" 같은 오보가 나갔다. 메일은 남이 보내는 데이터라
// 같은 사고가 나면 "메일이 안 왔다"로 오해하게 된다.
//
// 그래서 여기서는 실패를 서버가 준 메시지를 담아 [StateError] 로 던지고,
// 화면이 그 사유를 그대로 사용자에게 보여 준다.

import 'package:dio/dio.dart';

import 'package:app_flutter/core/api/api_client.dart';
import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/auth/auth_token_store.dart';
import 'package:app_flutter/pages/mail/mal001/mal001_model.dart';

abstract final class MailApiPaths {
  static const String messages = '/mail/messages';
  static const String messagesCount = '/mail/messages/count';
  static const String counts = '/mail/counts';
  static const String bulk = '/mail/messages/bulk';
  static const String recipients = '/mail/recipients';
  static const String signatures = '/mail/signatures';
  static const String folders = '/mail/folders';
  static const String preferences = '/mail/preferences';

  /// 자동분류 규칙.
  static const String rules = '/mail/rules';
  static const String rulesReorder = '/mail/rules/reorder';

  /// 자동전달 — 전체 설정과 예외 규칙이 따로다.
  static const String forward = '/mail/forward';
  static const String forwardRules = '/mail/forward/rules';

  static String message(int id) => '/mail/messages/$id';
  static String flags(int id) => '/mail/messages/$id/flags';
  static String send(int id) => '/mail/messages/$id/send';
  static String attachments(int id) => '/mail/messages/$id/attachments';
  static String attachmentDownload(int attId) =>
      '/mail/attachments/$attId/download';
  static String attachment(int attId) => '/mail/attachments/$attId';
  static String thread(int id) => '/mail/threads/$id';
  static String refreshBody(int id) => '/mail/messages/$id/refresh-body';
  static String signature(int id) => '/mail/signatures/$id';
  static String folder(int id) => '/mail/folders/$id';
  static String rule(int id) => '/mail/rules/$id';
  static String forwardRule(int id) => '/mail/forward/rules/$id';
}

/// **아직 백엔드에 없는 기능**을 만났을 때 던진다.
///
/// 실패를 삼키지 않는다는 원칙은 그대로다 — 다만 "서버가 죽었다/권한이 없다"와
/// "이 API 가 아직 안 만들어졌다"는 사용자에게 다르게 보여야 한다. 전자는 빨간
/// 오류로, 후자는 "준비 중"으로. 이 예외를 쓰는 곳은 **신규 엔드포인트뿐**이고,
/// 기존 메일 조회·발송은 예전처럼 [StateError] 로 그대로 터뜨린다.
///
/// 주의: `getMessage` 의 404 는 "메일이 없다"는 정상 응답이라 여기에 넣으면 안 된다.
class MailFeatureUnavailable implements Exception {
  const MailFeatureUnavailable(this.feature, [this.detail = '']);

  final String feature;
  final String detail;

  @override
  String toString() =>
      detail.isEmpty ? '$feature 기능은 준비 중입니다.' : '$feature 기능은 준비 중입니다. $detail';
}

class Mal001ApiService extends BaseRepository {
  /// 목록 최대 건수 — 서버 상한(500)과 같은 값. 메일 화면은 페이저 없이 전량 로드한다.
  static const int maxPageSize = 500;

  /// 실패 응답을 사용자에게 보여 줄 문장으로 바꾼다.
  ///
  /// 백엔드는 실패도 `{success:false, message:"..."}` 봉투로 내려보내므로 그 문장을
  /// 우선 쓴다. 봉투가 없을 때만 상태코드를 붙인 기본 문구로 물러난다.
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

  /// 신규 엔드포인트 전용 실패 처리.
  ///
  /// 404(라우트 없음)·501(미구현)·405(메서드 불일치)는 "서버에 아직 이 API 가 없다"는
  /// 뜻으로 보고 [MailFeatureUnavailable] 로 바꾼다. 그 외(403 권한·500 오류·타임아웃)는
  /// 예전과 똑같이 [StateError] 로 던져 사유를 그대로 보여 준다.
  Never _failDioFeature(DioException e, String feature, String fallback) {
    final code = e.response?.statusCode;
    if (code == 404 || code == 501 || code == 405) {
      throw MailFeatureUnavailable(feature);
    }
    throw StateError(dioErrorMessage(e, fallback: fallback));
  }

  /// 날짜 쿼리는 서버가 `yyyy-MM-dd`(`@DateTimeFormat(ISO.DATE)`)로만 받는다.
  /// `toIso8601String()` 을 그대로 보내면 시간까지 붙어 400 이 난다.
  static String _dateParam(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _listQuery({
    required String folder,
    String? keyword,
    DateTime? fromDate,
    DateTime? toDate,
    bool mine = false,
  }) {
    final kw = keyword?.trim() ?? '';
    return <String, dynamic>{
      'folder': folder,
      // 서버는 2자 미만 키워드를 null 로 정규화한다. 굳이 보내 봐야 조건만 늘어난다.
      if (kw.length >= 2) 'keyword': kw,
      if (fromDate != null) 'fromDate': _dateParam(fromDate),
      if (toDate != null) 'toDate': _dateParam(toDate),
      // `userId` 라는 이름의 쿼리 파라미터는 절대 쓰지 않는다 —
      // `AuthTokenFilter` 예약어라 토큰 주인과 다르면 무조건 403 이다.
      'mine': mine,
    };
  }

  Future<List<MailListItem>> listMessages({
    required String folder,
    String? keyword,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
    int offset = 0,
    bool mine = false,
  }) async {
    try {
      final r = await client.get(
        MailApiPaths.messages,
        queryParameters: {
          ..._listQuery(
            folder: folder,
            keyword: keyword,
            fromDate: fromDate,
            toDate: toDate,
            mine: mine,
          ),
          'limit': limit > maxPageSize ? maxPageSize : limit,
          'offset': offset,
        },
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 목록을 불러오지 못했습니다');
      }
      return parseDataList(r.data, MailListItem.fromJson);
    } on DioException catch (e) {
      _failDio(e, '메일 목록을 불러오지 못했습니다.');
    }
  }

  Future<int> countMessages({
    required String folder,
    String? keyword,
    bool mine = false,
  }) async {
    try {
      final r = await client.get(
        MailApiPaths.messagesCount,
        queryParameters: _listQuery(
          folder: folder,
          keyword: keyword,
          mine: mine,
        ),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 건수를 조회하지 못했습니다');
      }
      // `data` 가 객체가 아니라 숫자 하나다 — parseData 계열을 쓰면 안 된다.
      final raw = responseMap(r)['data'];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    } on DioException catch (e) {
      _failDio(e, '메일 건수를 조회하지 못했습니다.');
    }
  }

  Future<MailCounts> counts({bool mine = true}) async {
    try {
      final r = await client.get(
        MailApiPaths.counts,
        queryParameters: {'mine': mine},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일함 현황을 불러오지 못했습니다');
      }
      final result = parseData(r.data, MailCounts.fromJson);
      return result;
    } on DioException catch (e) {
      _failDio(e, '메일함 현황을 불러오지 못했습니다.');
    }
  }

  /// 메일 1건. **없으면 null, 실패하면 예외** — 이 둘을 절대 섞지 않는다.
  Future<MailDetail?> getMessage(int mailIdx) async {
    try {
      final r = await client.get(MailApiPaths.message(mailIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '메일을 불러오지 못했습니다');
      }
      return parseDataOrNull(r.data, MailDetail.fromJson);
    } on DioException catch (e) {
      _failDio(e, '메일을 불러오지 못했습니다.');
    }
  }

  /// 읽음·스팸·담당자 등 플래그 변경. null 인 항목은 서버가 건드리지 않는다.
  Future<MailListItem> updateFlags(
    int mailIdx, {
    bool? read,
    bool? spam,
    bool? starred,
    String? ownerUserId,
    int? partnerIdx,
    int? mappingId,
  }) async {
    try {
      final r = await client.patch(
        MailApiPaths.flags(mailIdx),
        data: <String, dynamic>{
          'read': ?read,
          'spam': ?spam,
          // 중요표시. 서버가 아직 이 필드를 모르면 그냥 무시하고 200 을 준다 —
          // 그래서 화면은 응답으로 돌아온 `starred` 를 믿고 다시 그린다.
          // (요청만 보고 켜 두면 새로고침했을 때 별이 사라져 더 헷갈린다.)
          'starred': ?starred,
          // 담당자 필드 이름이 `ownerUserId` 인 이유는 `userId` 가
          // `AuthTokenFilter` 예약어이기 때문이다(서버 DTO 주석과 동일).
          'ownerUserId': ?ownerUserId,
          'partnerIdx': ?partnerIdx,
          'mappingId': ?mappingId,
        },
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 상태 변경에 실패했습니다');
      }
      final result = parseData(r.data, MailListItem.fromJson);
      return result;
    } on DioException catch (e) {
      _failDio(e, '메일 상태 변경에 실패했습니다.');
    }
  }

  Future<void> deleteMessage(int mailIdx) async {
    try {
      final r = await client.delete(MailApiPaths.message(mailIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '메일 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDio(e, '메일 삭제에 실패했습니다.');
    }
  }

  Future<MailSendResult> compose(MailSendRequest body) async {
    try {
      final r = await client.post(MailApiPaths.messages, data: body.toJson());
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 저장에 실패했습니다');
      }
      final result = parseDataOrNull(r.data, MailSendResult.fromJson);
      if (result == null) {
        throw StateError('메일 저장 응답을 해석하지 못했습니다. 임시보관함에서 확인해 주세요.');
      }
      return result;
    } on DioException catch (e) {
      _failDio(e, '메일 저장에 실패했습니다.');
    }
  }

  /// 임시저장(DRAFT) → 발송대기(QUEUED). 실제 발송은 서버 워커가 한다.
  Future<MailSendResult> send(int mailIdx) async {
    try {
      final r = await client.post(
        MailApiPaths.send(mailIdx),
        data: const <String, dynamic>{},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 발송 요청에 실패했습니다');
      }
      final result = parseDataOrNull(r.data, MailSendResult.fromJson);
      if (result == null) {
        throw StateError('발송 응답을 해석하지 못했습니다. 보낸메일함에서 확인해 주세요.');
      }
      return result;
    } on DioException catch (e) {
      _failDio(e, '메일 발송 요청에 실패했습니다.');
    }
  }

  Future<MailAttachment> uploadAttachment(
    int mailIdx, {
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final r = await client.postMultipart(
        MailApiPaths.attachments(mailIdx),
        formData: formData,
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '첨부파일 업로드에 실패했습니다');
      }
      final result = parseData(r.data, MailAttachment.fromJson);
      return result;
    } on DioException catch (e) {
      _failDio(e, '첨부파일 업로드에 실패했습니다.');
    }
  }

  Future<void> deleteAttachment(int mailAttIdx) async {
    try {
      final r = await client.delete(MailApiPaths.attachment(mailAttIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '첨부파일 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDio(e, '첨부파일 삭제에 실패했습니다.');
    }
  }

  Future<MailThread?> getThread(int threadIdx) async {
    try {
      final r = await client.get(MailApiPaths.thread(threadIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '메일 스레드를 불러오지 못했습니다');
      }
      return parseDataOrNull(r.data, MailThread.fromJson);
    } on DioException catch (e) {
      _failDio(e, '메일 스레드를 불러오지 못했습니다.');
    }
  }

  /// 본문 재수집 — Resend Received Emails API 를 다시 호출한다.
  /// 외부 호출이라 기본 15초 타임아웃으론 모자랄 수 있어 넉넉히 준다.
  Future<MailDetail> refreshBody(int mailIdx) async {
    try {
      final r = await client.post(
        MailApiPaths.refreshBody(mailIdx),
        data: const <String, dynamic>{},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '본문을 다시 가져오지 못했습니다');
      }
      final result = parseData(r.data, MailDetail.fromJson);
      return result;
    } on DioException catch (e) {
      _failDio(e, '본문을 다시 가져오지 못했습니다.');
    }
  }

  // ───────────────────────── 일괄 처리 ─────────────────────────

  /// 선택한 메일들을 한 번에 처리한다 — `POST /mail/messages/bulk`.
  ///
  /// 목록에서 100건을 고르고 낱개 API 를 100번 부르면 중간에 몇 건이 실패해도
  /// 사용자는 알 길이 없다. 서버가 한 번에 처리하고 **실제 처리 건수**를 돌려주게 해서,
  /// 요청 수와 처리 수가 다르면 화면이 그 사실을 그대로 말하게 한다.
  Future<MailBulkResult> bulkAction({
    required List<int> mailIdxList,
    required String action,
    int? targetFolderIdx,
  }) async {
    if (mailIdxList.isEmpty) {
      throw StateError('선택된 메일이 없습니다.');
    }
    try {
      final r = await client.post(
        MailApiPaths.bulk,
        data: <String, dynamic>{
          // 서버 DTO(MailBulkActionRequestDto) 필드명은 mailIdxes 다.
          // 예전엔 mailIdx 로 보내서 @JsonIgnoreProperties 에 조용히 씹히고
          // (ignoreUnknown=true) mailIdxes 가 null 로 남아 @NotEmpty 에 걸려
          // 삭제·중요표시·읽음/안읽음·복구 등 모든 일괄처리가 "입력값 검증
          // 실패"로 100% 실패했다.
          'mailIdxes': mailIdxList,
          'action': action,
          'targetFolderIdx': ?targetFolderIdx,
        },
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '${MailBulkActions.labelOf(action)}에 실패했습니다');
      }
      final parsed = parseDataOrNull(r.data, MailBulkResult.fromJson);
      // 응답 본문이 없어도 2xx 면 성공으로 본다. 다만 처리 건수를 모르므로
      // 요청 건수를 그대로 적어 둔다(화면이 "0건 처리"로 오해하지 않게).
      return parsed ??
          MailBulkResult(
            requested: mailIdxList.length,
            affected: mailIdxList.length,
            message: '',
          );
    } on DioException catch (e) {
      _failDioFeature(
        e,
        '메일 일괄 ${MailBulkActions.labelOf(action)}',
        '${MailBulkActions.labelOf(action)}에 실패했습니다.',
      );
    }
  }

  // ───────────────────────── 받는사람 자동완성 ─────────────────────────

  /// 직원·거래처·부서 검색 — `GET /mail/recipients?q=`.
  ///
  /// 두 글자 미만이면 서버를 부르지 않는다. 한 글자로 검색하면 72명 전체가
  /// 내려와 목록이 쓸모없어지고 요청만 늘어난다.
  Future<List<MailRecipient>> searchRecipients(String query) async {
    final q = query.trim();
    if (q.length < 2) return const <MailRecipient>[];
    try {
      final r = await client.get(
        MailApiPaths.recipients,
        queryParameters: <String, dynamic>{'q': q},
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '받는사람을 검색하지 못했습니다');
      }
      return parseDataList(r.data, MailRecipient.fromJson);
    } on DioException catch (e) {
      _failDioFeature(e, '받는사람 자동완성', '받는사람을 검색하지 못했습니다.');
    }
  }

  // ───────────────────────── 서명 ─────────────────────────

  Future<List<MailSignature>> listSignatures() async {
    try {
      final r = await client.get(MailApiPaths.signatures);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '서명 목록을 불러오지 못했습니다');
      }
      return parseDataList(r.data, MailSignature.fromJson);
    } on DioException catch (e) {
      _failDioFeature(e, '메일 서명', '서명 목록을 불러오지 못했습니다.');
    }
  }

  Future<MailSignature> saveSignature(MailSignature body) async {
    try {
      final isNew = body.signIdx <= 0;
      final r = isNew
          ? await client.post(MailApiPaths.signatures, data: body.toJson())
          : await client.put(
              MailApiPaths.signature(body.signIdx),
              data: body.toJson(),
            );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '서명 저장에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, MailSignature.fromJson);
      if (saved == null) {
        throw StateError('서명 저장 응답을 해석하지 못했습니다. 목록을 새로고침해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 서명', '서명 저장에 실패했습니다.');
    }
  }

  Future<void> deleteSignature(int signIdx) async {
    try {
      final r = await client.delete(MailApiPaths.signature(signIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '서명 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDioFeature(e, '메일 서명', '서명 삭제에 실패했습니다.');
    }
  }

  // ───────────────────────── 사용자 정의 메일함 ─────────────────────────

  Future<List<MailUserFolder>> listUserFolders() async {
    try {
      final r = await client.get(MailApiPaths.folders);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일함 목록을 불러오지 못했습니다');
      }
      return parseDataList(r.data, MailUserFolder.fromJson);
    } on DioException catch (e) {
      _failDioFeature(e, '사용자 메일함', '메일함 목록을 불러오지 못했습니다.');
    }
  }

  Future<MailUserFolder> saveUserFolder(MailUserFolder body) async {
    try {
      final isNew = body.folderIdx <= 0;
      final r = isNew
          ? await client.post(MailApiPaths.folders, data: body.toJson())
          : await client.put(
              MailApiPaths.folder(body.folderIdx),
              data: body.toJson(),
            );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일함 저장에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, MailUserFolder.fromJson);
      if (saved == null) {
        throw StateError('메일함 저장 응답을 해석하지 못했습니다. 목록을 새로고침해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDioFeature(e, '사용자 메일함', '메일함 저장에 실패했습니다.');
    }
  }

  Future<void> deleteUserFolder(int folderIdx) async {
    try {
      final r = await client.delete(MailApiPaths.folder(folderIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '메일함 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDioFeature(e, '사용자 메일함', '메일함 삭제에 실패했습니다.');
    }
  }

  // ───────────────────────── 개인 환경설정 ─────────────────────────

  Future<MailPreferences> getPreferences() async {
    try {
      final r = await client.get(MailApiPaths.preferences);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 환경설정을 불러오지 못했습니다');
      }
      final result = parseDataOrNull(r.data, MailPreferences.fromJson);
      return result ?? MailPreferences.defaults;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 환경설정', '메일 환경설정을 불러오지 못했습니다.');
    }
  }

  Future<MailPreferences> savePreferences(MailPreferences body) async {
    try {
      final r = await client.put(
        MailApiPaths.preferences,
        data: body.toJson(),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '메일 환경설정 저장에 실패했습니다');
      }
      final result = parseDataOrNull(r.data, MailPreferences.fromJson);
      return result ?? body;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 환경설정', '메일 환경설정 저장에 실패했습니다.');
    }
  }

  // ───────────────────────── 자동분류 규칙 ─────────────────────────
  //
  // 아직 서버에 없을 수 있는 신규 엔드포인트다. 404/501/405 는
  // [MailFeatureUnavailable] 로 바꿔 화면이 "준비 중"으로 물러나게 하고,
  // 그 밖의 실패(403·500·타임아웃)는 예전처럼 사유를 그대로 던진다.

  Future<List<MailRule>> listRules() async {
    try {
      final r = await client.get(MailApiPaths.rules);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동분류 규칙을 불러오지 못했습니다');
      }
      return parseDataList(r.data, MailRule.fromJson);
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동분류', '자동분류 규칙을 불러오지 못했습니다.');
    }
  }

  /// 새 규칙은 POST, 기존 규칙은 PATCH.
  ///
  /// PUT 이 아니라 PATCH 인 이유는 서버 규약(`PATCH /mail/rules/{id}`)이 그렇기
  /// 때문이다. 여기서 메서드를 틀리면 405 가 나고, 그건 위에서 "준비 중"으로
  /// 해석돼 **버그가 기능 미구현으로 위장된다.** 경로·메서드를 함부로 바꾸지 말 것.
  Future<MailRule> saveRule(MailRule body) async {
    try {
      final isNew = body.ruleIdx <= 0;
      final r = isNew
          ? await client.post(MailApiPaths.rules, data: body.toJson())
          : await client.patch(
              MailApiPaths.rule(body.ruleIdx),
              data: body.toJson(),
            );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동분류 규칙 저장에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, MailRule.fromJson);
      if (saved == null) {
        throw StateError('규칙 저장 응답을 해석하지 못했습니다. 목록을 새로고침해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동분류', '자동분류 규칙 저장에 실패했습니다.');
    }
  }

  Future<void> deleteRule(int ruleIdx) async {
    try {
      final r = await client.delete(MailApiPaths.rule(ruleIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '자동분류 규칙 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동분류', '자동분류 규칙 삭제에 실패했습니다.');
    }
  }

  /// 규칙 순서 바꾸기 — `PATCH /mail/rules/reorder`.
  ///
  /// 순서가 곧 우선순위다(위에서부터 먼저 걸린다). 한 건씩 sort_order 를 고치면
  /// 중간에 실패했을 때 순서가 뒤죽박죽으로 남으므로 **전체 순서를 한 번에** 보낸다.
  Future<void> reorderRules(List<int> ruleIdxInOrder) async {
    if (ruleIdxInOrder.isEmpty) return;
    try {
      final r = await client.patch(
        MailApiPaths.rulesReorder,
        data: <String, dynamic>{'ruleIdx': ruleIdxInOrder},
      );
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '규칙 순서 변경에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동분류', '규칙 순서 변경에 실패했습니다.');
    }
  }

  // ───────────────────────── 자동전달 ─────────────────────────

  Future<MailForwardSetting> getForward() async {
    try {
      final r = await client.get(MailApiPaths.forward);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동전달 설정을 불러오지 못했습니다');
      }
      // 아직 설정한 적이 없으면 서버가 빈 응답을 줄 수 있다 — 그건 "꺼짐"이다.
      final result = parseDataOrNull(r.data, MailForwardSetting.fromJson);
      return result ?? MailForwardSetting.off;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동전달', '자동전달 설정을 불러오지 못했습니다.');
    }
  }

  Future<MailForwardSetting> saveForward(MailForwardSetting body) async {
    try {
      final r = await client.put(MailApiPaths.forward, data: body.toJson());
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동전달 설정 저장에 실패했습니다');
      }
      final result = parseDataOrNull(r.data, MailForwardSetting.fromJson);
      return result ?? body;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동전달', '자동전달 설정 저장에 실패했습니다.');
    }
  }

  Future<List<MailForwardRule>> listForwardRules() async {
    try {
      final r = await client.get(MailApiPaths.forwardRules);
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동전달 예외 규칙을 불러오지 못했습니다');
      }
      return parseDataList(r.data, MailForwardRule.fromJson);
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동전달', '자동전달 예외 규칙을 불러오지 못했습니다.');
    }
  }

  Future<MailForwardRule> saveForwardRule(MailForwardRule body) async {
    try {
      final isNew = body.ruleIdx <= 0;
      final r = isNew
          ? await client.post(MailApiPaths.forwardRules, data: body.toJson())
          : await client.patch(
              MailApiPaths.forwardRule(body.ruleIdx),
              data: body.toJson(),
            );
      if (!isHttpSuccess(r.statusCode) || r.data == null) {
        _failResponse(r, '자동전달 예외 규칙 저장에 실패했습니다');
      }
      final saved = parseDataOrNull(r.data, MailForwardRule.fromJson);
      if (saved == null) {
        throw StateError('예외 규칙 저장 응답을 해석하지 못했습니다. 목록을 새로고침해 주세요.');
      }
      return saved;
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동전달', '자동전달 예외 규칙 저장에 실패했습니다.');
    }
  }

  Future<void> deleteForwardRule(int ruleIdx) async {
    try {
      final r = await client.delete(MailApiPaths.forwardRule(ruleIdx));
      if (!isHttpSuccess(r.statusCode)) {
        _failResponse(r, '자동전달 예외 규칙 삭제에 실패했습니다');
      }
    } on DioException catch (e) {
      _failDioFeature(e, '메일 자동전달', '자동전달 예외 규칙 삭제에 실패했습니다.');
    }
  }

  /// 새 탭 다운로드용 절대 URL.
  ///
  /// 이 URL 은 브라우저가 직접 열기 때문에 Dio 인터셉터를 타지 않는다 —
  /// Authorization 헤더가 실리지 않아 그대로 두면 항상 401 이다.
  /// 서버 `AuthTokenFilter` 가 **`/download` 로 끝나는 경로에 한해** `?token=`
  /// 쿼리 토큰을 허용하므로 여기에 맞춰 붙인다. 경로 형태를 바꾸면 다운로드가
  /// 조용히 401 로 죽으니 [MailApiPaths.attachmentDownload] 를 손대지 말 것.
  String attachmentDownloadUrl(int mailAttIdx) {
    final base = ApiClient.resolveBaseUrl();
    final path = MailApiPaths.attachmentDownload(mailAttIdx);
    final String url;
    if (base.endsWith('/') && path.startsWith('/')) {
      url = '${base.substring(0, base.length - 1)}$path';
    } else if (!base.endsWith('/') && !path.startsWith('/')) {
      url = '$base/$path';
    } else {
      url = '$base$path';
    }
    if (!AuthTokenStore.hasToken) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}token=${Uri.encodeQueryComponent(AuthTokenStore.token)}';
  }
}
