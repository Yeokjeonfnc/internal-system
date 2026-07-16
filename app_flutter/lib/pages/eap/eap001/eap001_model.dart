// 다우오피스 전자결재 문서·양식 모델.

enum EapDocStatus {
  writing,
  draft,
  inProgress,
  complete,
  returned,
  cancelled,
  tempSave,
}

extension EapDocStatusX on EapDocStatus {
  String get label => switch (this) {
    EapDocStatus.writing => '작성중',
    EapDocStatus.draft => '상신',
    EapDocStatus.inProgress => '진행중',
    EapDocStatus.complete => '완료',
    EapDocStatus.returned => '반려',
    EapDocStatus.cancelled => '상신취소',
    EapDocStatus.tempSave => '임시저장',
  };

  String get daouCode => switch (this) {
    EapDocStatus.writing => 'WRITING',
    EapDocStatus.draft => 'DRAFT',
    EapDocStatus.inProgress => 'INPROGRESS',
    EapDocStatus.complete => 'COMPLETE',
    EapDocStatus.returned => 'RETURN',
    EapDocStatus.cancelled => 'CANCEL',
    EapDocStatus.tempSave => 'TEMPSAVE',
  };

  static EapDocStatus fromDaouCode(String? code) {
    final c = (code ?? '').trim().toUpperCase();
    return switch (c) {
      'WRITING' => EapDocStatus.writing,
      'DRAFT' => EapDocStatus.draft,
      'INPROGRESS' ||
      'IN_PROGRESS' ||
      'PROGRESS' ||
      'RECV_WAITING' ||
      'RECEIVED' => EapDocStatus.inProgress,
      'COMPLETE' ||
      'DONE' ||
      'APPROVED' ||
      'COMPLETED' => EapDocStatus.complete,
      'RETURN' ||
      'REJECT' ||
      'REJECTED' ||
      'RETURNED' ||
      'FORCED_RETURN' => EapDocStatus.returned,
      'CANCEL' ||
      'CANCELED' ||
      'CANCELLED' ||
      'DELETE' ||
      'FORCE_DELETE' => EapDocStatus.cancelled,
      'TEMPSAVE' || 'TEMP_SAVE' => EapDocStatus.tempSave,
      _ => EapDocStatus.writing,
    };
  }
}

class EapDocument {
  const EapDocument({
    required this.docId,
    required this.docNum,
    required this.draftDate,
    required this.formName,
    required this.title,
    required this.status,
    this.mappingId,
    this.updatedAt,
    this.formCode = '',
    this.drafterName = '',
    this.contentHtml = '',
    this.attachmentCount = 0,
    this.urgent = false,
    this.erpMenuId = '',
    this.erpSourceId = '',
  });

  factory EapDocument.fromJson(Map<String, dynamic> json) {
    final draftRaw = json['draftDate']?.toString();
    DateTime draftDate = DateTime.now();
    if (draftRaw != null && draftRaw.isNotEmpty) {
      draftDate = DateTime.tryParse(draftRaw) ?? draftDate;
    }
    DateTime? updatedAt;
    final updatedRaw = json['updatedAt']?.toString();
    if (updatedRaw != null && updatedRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedRaw);
    }
    return EapDocument(
      mappingId: (json['mappingId'] as num?)?.toInt(),
      docId: json['docId']?.toString() ?? '',
      docNum: json['docNum']?.toString() ?? '',
      draftDate: draftDate,
      updatedAt: updatedAt,
      formName: json['formName']?.toString() ?? '',
      formCode: json['formCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: EapDocStatusX.fromDaouCode(json['status']?.toString()),
      drafterName: json['drafterName']?.toString() ?? '',
      contentHtml: json['contentHtml']?.toString() ?? '',
      erpMenuId: json['erpMenuId']?.toString() ?? '',
      erpSourceId: json['erpSourceId']?.toString() ?? '',
    );
  }

  final int? mappingId;
  final String docId;
  final String docNum;
  final DateTime draftDate;
  final DateTime? updatedAt;
  final String formName;
  final String formCode;
  final String title;
  final EapDocStatus status;
  final String drafterName;
  final String contentHtml;
  final int attachmentCount;
  final bool urgent;
  final String erpMenuId;
  final String erpSourceId;

  bool get isWritable => status == EapDocStatus.writing;

  bool get hasBeenRevised {
    final u = updatedAt;
    if (u == null) return false;
    return u.difference(draftDate).inSeconds.abs() > 2;
  }

  String get draftDateLabel => _fmtDate(draftDate);

  String get draftDateTimeLabel => _fmtDateTime(draftDate);

  String? get updatedDateTimeLabel {
    final u = updatedAt;
    if (u == null || !hasBeenRevised) return null;
    return _fmtDateTime(u);
  }

  static String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class EapFormConfig {
  const EapFormConfig({
    required this.formCode,
    required this.formName,
    this.integrationType = 'v4',
    this.erpSourceMenu = '',
    this.htmlTemplateKey = '',
    this.useEmail = false,
    this.useBoard = false,
    this.enabled = true,
    this.sortOrder = 0,
  });

  factory EapFormConfig.fromJson(Map<String, dynamic> json) {
    return EapFormConfig(
      formCode: json['formCode']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      integrationType: json['integrationType']?.toString() ?? 'v4',
      erpSourceMenu: json['erpSourceMenu']?.toString() ?? '',
      htmlTemplateKey: json['htmlTemplateKey']?.toString() ?? '',
      useEmail: json['useEmail'] == true,
      useBoard: json['useBoard'] == true,
      enabled: json['enabled'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreateBody() => {
    'formCode': formCode,
    'formName': formName,
    'integrationType': integrationType,
    'erpSourceMenu': erpSourceMenu.isEmpty ? null : erpSourceMenu,
    'htmlTemplateKey': htmlTemplateKey.isEmpty ? null : htmlTemplateKey,
    'useEmail': useEmail,
    'useBoard': useBoard,
    'enabled': enabled,
    'sortOrder': sortOrder,
  };

  Map<String, dynamic> toUpdateBody() => {
    'formName': formName,
    'integrationType': integrationType,
    'erpSourceMenu': erpSourceMenu.isEmpty ? null : erpSourceMenu,
    'htmlTemplateKey': htmlTemplateKey.isEmpty ? null : htmlTemplateKey,
    'useEmail': useEmail,
    'useBoard': useBoard,
    'enabled': enabled,
    'sortOrder': sortOrder,
  };

  final String formCode;
  final String formName;
  final String integrationType;
  final String erpSourceMenu;
  final String htmlTemplateKey;
  final bool useEmail;
  final bool useBoard;
  final bool enabled;
  final int sortOrder;
}

class EapDraftRequest {
  const EapDraftRequest({
    required this.formCode,
    required this.title,
    this.erpMenuId = 'eap001',
    this.erpSourceId,
    this.draftUserId,
    this.contentHtml,
    this.mappingId,
  });

  Map<String, dynamic> toJson() => {
    'formCode': formCode,
    'title': title,
    'erpMenuId': erpMenuId,
    if (erpSourceId != null) 'erpSourceId': erpSourceId,
    if (draftUserId != null) 'draftUserId': draftUserId,
    if (contentHtml != null) 'contentHtml': contentHtml,
    if (mappingId != null) 'mappingId': mappingId,
  };

  final String formCode;
  final String title;
  final String erpMenuId;
  final String? erpSourceId;
  final String? draftUserId;
  final String? contentHtml;
  final int? mappingId;
}

class EapDraftResult {
  const EapDraftResult({
    required this.mappingId,
    required this.daouDocumentId,
    required this.formCode,
    required this.status,
    required this.title,
    required this.daouSubmitted,
    required this.message,
    this.redirectUrl,
  });

  factory EapDraftResult.fromJson(Map<String, dynamic> json) {
    final redirect = json['redirectUrl']?.toString();
    return EapDraftResult(
      mappingId: (json['mappingId'] as num?)?.toInt() ?? 0,
      daouDocumentId: json['daouDocumentId']?.toString() ?? '',
      formCode: json['formCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      daouSubmitted: json['daouSubmitted'] == true,
      message: json['message']?.toString() ?? '',
      redirectUrl: (redirect == null || redirect.isEmpty) ? null : redirect,
    );
  }

  final int mappingId;
  final String daouDocumentId;
  final String formCode;
  final String status;
  final String title;
  final bool daouSubmitted;
  final String message;

  /// 다우 302 Location — 브라우저에서 열어야 실제 기안 화면
  final String? redirectUrl;
}
