// 전자결재 문서·양식 모델.

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

  String get statusCode => switch (this) {
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
    this.drafterDept = '',
    this.contentHtml = '',
    this.attachmentCount = 0,
    this.urgent = false,
    this.erpMenuId = '',
    this.erpSourceId = '',
    this.formCategory = '기타문서',
    this.draftUserId = '',
    this.lines = const [],
    this.canApprove = false,
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
      drafterDept: json['drafterDept']?.toString() ?? '',
      contentHtml: json['contentHtml']?.toString() ?? '',
      erpMenuId: json['erpMenuId']?.toString() ?? '',
      erpSourceId: json['erpSourceId']?.toString() ?? '',
      formCategory: json['formCategory']?.toString().trim().isNotEmpty == true
          ? json['formCategory'].toString()
          : '기타문서',
      draftUserId: json['draftUserId']?.toString() ?? '',
      canApprove: json['canApprove'] == true,
      lines: _parseLines(json['lines']),
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
  final String drafterDept;
  final String contentHtml;
  final int attachmentCount;
  final bool urgent;
  final String erpMenuId;
  final String erpSourceId;
  final String formCategory;
  final String draftUserId;
  final List<EapLineMember> lines;
  final bool canApprove;

  bool canActAs(String userId) {
    if (canApprove) return true;
    final uid = userId.trim();
    if (uid.isEmpty) return false;
    if (status != EapDocStatus.inProgress &&
        status != EapDocStatus.draft &&
        status != EapDocStatus.writing) {
      return false;
    }
    if (draftUserId.trim().isNotEmpty &&
        draftUserId.trim().toLowerCase() == uid.toLowerCase()) {
      return false;
    }
    final mine = lines
        .where(
          (l) =>
              l.userId.trim().toLowerCase() == uid.toLowerCase() &&
              l.lineStatus.toUpperCase() == 'WAIT',
        )
        .toList();
    for (final me in mine) {
      final role = me.roleCd.toUpperCase();
      if (role == 'APPROVER') {
        final blocked = lines.any(
          (p) =>
              p.roleCd.toUpperCase() == 'APPROVER' &&
              p.sortOrder < me.sortOrder &&
              p.lineStatus.toUpperCase() == 'WAIT',
        );
        if (!blocked) return true;
      }
      if (role == 'AGREE') return true;
    }
    return false;
  }

  static List<EapLineMember> _parseLines(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => EapLineMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

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

class EapLineMember {
  const EapLineMember({
    this.lineId,
    required this.roleCd,
    this.sortOrder = 0,
    required this.userId,
    this.userNm = '',
    this.titleNm = '',
    this.lineStatus = 'WAIT',
    this.actedAt,
  });

  factory EapLineMember.fromJson(Map<String, dynamic> json) {
    return EapLineMember(
      lineId: (json['lineId'] as num?)?.toInt(),
      roleCd: json['roleCd']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      userNm: json['userNm']?.toString() ?? '',
      titleNm: json['titleNm']?.toString() ?? '',
      lineStatus: json['lineStatus']?.toString() ?? 'WAIT',
      actedAt: DateTime.tryParse(json['actedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'roleCd': roleCd,
    'sortOrder': sortOrder,
    'userId': userId,
    'userNm': userNm,
    'titleNm': titleNm,
  };

  final int? lineId;
  final String roleCd;
  final int sortOrder;
  final String userId;
  final String userNm;
  final String titleNm;
  final String lineStatus;
  final DateTime? actedAt;

  String get roleLabel => switch (roleCd.toUpperCase()) {
    'APPROVER' => '결재',
    'AGREE' => '합의',
    'CC' => '참조',
    'VIEWER' => '열람',
    _ => roleCd,
  };

  String get statusLabel => switch (lineStatus.toUpperCase()) {
    'DONE' => '완료',
    'REJECT' => '반려',
    _ => '대기',
  };

  String get displayName {
    final nm = userNm.trim().isEmpty ? userId : userNm;
    final title = titleNm.trim();
    return title.isEmpty ? nm : '$nm $title';
  }

  String get actionLabel {
    final st = lineStatus.toUpperCase();
    final role = roleCd.toUpperCase();
    if (st == 'REJECT') {
      return switch (role) {
        'AGREE' => '합의 반려',
        _ => '결재 반려',
      };
    }
    if (st == 'DONE') {
      return switch (role) {
        'AGREE' => '합의 완료',
        'CC' => '참조 확인',
        'VIEWER' => '열람 완료',
        _ => '결재 승인',
      };
    }
    return switch (role) {
      'AGREE' => '합의 대기',
      'CC' => '참조',
      'VIEWER' => '열람',
      _ => '결재 대기',
    };
  }

  String get actedAtLabel {
    final t = actedAt;
    if (t == null) return '';
    final l = t.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final mi = l.minute.toString().padLeft(2, '0');
    return '${l.year}-$mm-$dd $hh:$mi';
  }

  String get actedDateLabel {
    final t = actedAt;
    if (t == null) return '';
    final l = t.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    return '${l.year}-$mm-$dd';
  }
}

class EapFormConfig {
  const EapFormConfig({
    required this.formCode,
    required this.formName,
    this.integrationType = 'internal',
    this.erpSourceMenu = '',
    this.htmlTemplateKey = '',
    this.useEmail = false,
    this.useBoard = false,
    this.enabled = true,
    this.sortOrder = 0,
    this.category = '기타문서',
    this.contentHtml = '',
    this.contentDelta = '',
    this.fieldSchema = '',
    this.createdBy = '',
    this.createdByNm = '',
    this.createdAt,
  });

  factory EapFormConfig.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final createdRaw = json['createdAt']?.toString();
    if (createdRaw != null && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }
    return EapFormConfig(
      formCode: json['formCode']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      integrationType: json['integrationType']?.toString() ?? 'internal',
      erpSourceMenu: json['erpSourceMenu']?.toString() ?? '',
      htmlTemplateKey: json['htmlTemplateKey']?.toString() ?? '',
      useEmail: json['useEmail'] == true,
      useBoard: json['useBoard'] == true,
      enabled: json['enabled'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString().trim().isNotEmpty == true
          ? json['category'].toString()
          : '기타문서',
      contentHtml: json['contentHtml']?.toString() ?? '',
      contentDelta: json['contentDelta']?.toString() ?? '',
      fieldSchema: json['fieldSchema']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      createdByNm: json['createdByNm']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toCreateBody() => {
    'formName': formName,
    'enabled': enabled,
    'sortOrder': sortOrder,
    'category': category,
    'contentHtml': contentHtml,
    'fieldSchema': fieldSchema.isEmpty ? null : fieldSchema,
    'createdBy': createdBy.isEmpty ? null : createdBy,
    'createdByNm': createdByNm.isEmpty ? null : createdByNm,
  };

  Map<String, dynamic> toUpdateBody() => {
    'formName': formName,
    'enabled': enabled,
    'sortOrder': sortOrder,
    'category': category,
    'contentHtml': contentHtml,
    'fieldSchema': fieldSchema.isEmpty ? null : fieldSchema,
  };

  EapFormConfig copyWith({
    String? formCode,
    String? formName,
    bool? enabled,
    String? category,
    String? contentHtml,
    String? fieldSchema,
    String? createdBy,
    String? createdByNm,
  }) {
    return EapFormConfig(
      formCode: formCode ?? this.formCode,
      formName: formName ?? this.formName,
      integrationType: integrationType,
      erpSourceMenu: erpSourceMenu,
      htmlTemplateKey: htmlTemplateKey,
      useEmail: useEmail,
      useBoard: useBoard,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder,
      category: category ?? this.category,
      contentHtml: contentHtml ?? this.contentHtml,
      contentDelta: contentDelta,
      fieldSchema: fieldSchema ?? this.fieldSchema,
      createdBy: createdBy ?? this.createdBy,
      createdByNm: createdByNm ?? this.createdByNm,
      createdAt: createdAt,
    );
  }

  final String formCode;
  final String formName;
  final String integrationType;
  final String erpSourceMenu;
  final String htmlTemplateKey;
  final bool useEmail;
  final bool useBoard;
  final bool enabled;
  final int sortOrder;
  final String category;
  final String contentHtml;
  final String contentDelta;
  final String fieldSchema;
  final String createdBy;
  final String createdByNm;
  final DateTime? createdAt;

  String get createdDateLabel {
    final d = createdAt?.toLocal();
    if (d == null) return '-';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

const kEapFormCategories = ['기타문서', '기획문서', '대외문서', '보고문서', '업무협조', '영업팀문서'];

class EapDraftRequest {
  const EapDraftRequest({
    required this.formCode,
    required this.title,
    this.erpMenuId = 'eap001',
    this.erpSourceId,
    this.draftUserId,
    this.contentHtml,
    this.mappingId,
    this.status,
    this.lines = const [],
  });

  Map<String, dynamic> toJson() => {
    'formCode': formCode,
    'title': title,
    'erpMenuId': erpMenuId,
    if (erpSourceId != null) 'erpSourceId': erpSourceId,
    if (draftUserId != null) 'draftUserId': draftUserId,
    if (contentHtml != null) 'contentHtml': contentHtml,
    if (mappingId != null) 'mappingId': mappingId,
    if (status != null) 'status': status,
    'lines': lines.map((e) => e.toJson()).toList(),
  };

  final String formCode;
  final String title;
  final String erpMenuId;
  final String? erpSourceId;
  final String? draftUserId;
  final String? contentHtml;
  final int? mappingId;
  final String? status;
  final List<EapLineMember> lines;
}

class EapDraftResult {
  const EapDraftResult({
    required this.mappingId,
    required this.documentId,
    required this.formCode,
    required this.status,
    required this.title,
    required this.message,
  });

  factory EapDraftResult.fromJson(Map<String, dynamic> json) {
    return EapDraftResult(
      mappingId: (json['mappingId'] as num?)?.toInt() ?? 0,
      documentId: json['documentId']?.toString() ?? '',
      formCode: json['formCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  final int mappingId;
  final String documentId;
  final String formCode;
  final String status;
  final String title;
  final String message;
}
