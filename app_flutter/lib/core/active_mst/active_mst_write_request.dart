/// 체크리스트 결과 저장 행 — 백엔드 `ChkResultDtlSaveDto`와 동일 키.
class ChkResultDtlSave {
  static const String jsonKeyChkIdx = 'chkIdx';
  static const String jsonKeyAnswerVal = 'answerVal';
  static const String jsonKeyAnswerScore = 'answerScore';

  const ChkResultDtlSave({
    required this.chkIdx,
    required this.answerVal,
    required this.answerScore,
  });

  final int chkIdx;
  final String answerVal;
  final int answerScore;

  Map<String, dynamic> toJson() => {
        jsonKeyChkIdx: chkIdx,
        jsonKeyAnswerVal: answerVal,
        jsonKeyAnswerScore: answerScore,
      };
}

/// `POST`/`PUT /activities` 요청 본문 — `ActivityWriteRequest.toJson()`으로 직렬화.
/// 키는 `ActiveMstWriteRequestDto` JSON과 동일.
class ActivityWriteRequest {
  static const String jsonKeyStoreIdx = 'storeIdx';
  static const String jsonKeyActType = 'actType';
  static const String jsonKeyActDt = 'actDt';
  static const String jsonKeyMemoTxt = 'memoTxt';
  static const String jsonKeyActNotes = 'actNotes';
  static const String jsonKeySvId = 'svId';
  static const String jsonKeyApprStatus = 'apprStatus';
  static const String jsonKeySuggestions = 'suggestions';
  static const String jsonKeySvNotes = 'svNotes';
  static const String jsonKeyApprUserIds = 'apprUserIds';
  static const String jsonKeyChecklistResults = 'checklistResults';

  const ActivityWriteRequest({
    required this.storeIdx,
    required this.actType,
    required this.actDt,
    required this.memoTxt,
    required this.actNotes,
    required this.svId,
    required this.apprStatus,
    required this.suggestions,
    required this.svNotes,
    this.apprUserIds,
    this.checklistResults,
  });

  final int storeIdx;
  final String actType;
  final String actDt;
  final String memoTxt;
  final String actNotes;
  final String? svId;
  final String apprStatus;
  final String suggestions;
  final String svNotes;
  final List<String>? apprUserIds;
  final List<ChkResultDtlSave>? checklistResults;

  Map<String, dynamic> toJson() {
    return {
      jsonKeyStoreIdx: storeIdx,
      jsonKeyActType: actType,
      jsonKeyActDt: actDt,
      jsonKeyMemoTxt: memoTxt,
      jsonKeyActNotes: actNotes,
      jsonKeySvId: svId,
      jsonKeyApprStatus: apprStatus,
      jsonKeySuggestions: suggestions,
      jsonKeySvNotes: svNotes,
      if (apprUserIds != null && apprUserIds!.isNotEmpty)
        jsonKeyApprUserIds: apprUserIds,
      if (checklistResults != null && checklistResults!.isNotEmpty)
        jsonKeyChecklistResults:
            checklistResults!.map((e) => e.toJson()).toList(),
    };
  }
}
