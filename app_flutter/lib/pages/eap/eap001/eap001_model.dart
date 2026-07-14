// 다우오피스 전자결재 문서 모델.

enum EapDocStatus {
  draft,
  inProgress,
  complete,
  returned,
  cancelled,
  tempSave,
}

extension EapDocStatusX on EapDocStatus {
  String get label => switch (this) {
        EapDocStatus.draft => '상신',
        EapDocStatus.inProgress => '진행중',
        EapDocStatus.complete => '완료',
        EapDocStatus.returned => '반려',
        EapDocStatus.cancelled => '상신취소',
        EapDocStatus.tempSave => '임시저장',
      };

  String get daouCode => switch (this) {
        EapDocStatus.draft => 'DRAFT',
        EapDocStatus.inProgress => 'INPROGRESS',
        EapDocStatus.complete => 'COMPLETE',
        EapDocStatus.returned => 'RETURN',
        EapDocStatus.cancelled => 'CANCEL',
        EapDocStatus.tempSave => 'TEMPSAVE',
      };
}

class EapDocument {
  const EapDocument({
    required this.docId,
    required this.docNum,
    required this.draftDate,
    required this.formName,
    required this.title,
    required this.status,
    this.drafterName = '',
    this.contentHtml = '',
    this.attachmentCount = 0,
    this.urgent = false,
  });

  final String docId;
  final String docNum;
  final DateTime draftDate;
  final String formName;
  final String title;
  final EapDocStatus status;
  final String drafterName;
  final String contentHtml;
  final int attachmentCount;
  final bool urgent;

  String get draftDateLabel =>
      '${draftDate.year}-${draftDate.month.toString().padLeft(2, '0')}-${draftDate.day.toString().padLeft(2, '0')}';
}
