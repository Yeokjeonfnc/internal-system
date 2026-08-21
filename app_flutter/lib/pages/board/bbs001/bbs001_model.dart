import 'package:app_flutter/core/board/board_api_json_keys.dart';
import 'package:app_flutter/core/utils/json_extensions.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_preview_kind.dart';

class BoardFolder {
  const BoardFolder({
    required this.folderIdx,
    required this.folderNm,
    required this.sortOrder,
    required this.postCount,
    this.ownerViewYn = 'Y',
    this.staffViewYn = 'Y',
  });

  final int folderIdx;
  final String folderNm;
  final int sortOrder;
  final int postCount;
  final String ownerViewYn;
  final String staffViewYn;

  bool get allowsOwner => ownerViewYn.trim().toUpperCase() == 'Y';
  bool get allowsStaff => staffViewYn.trim().toUpperCase() == 'Y';

  factory BoardFolder.fromJson(Map<String, dynamic> json) {
    return BoardFolder(
      folderIdx: asJsonIntOpt(json[BoardApiJsonKeys.folderIdx]) ?? 0,
      folderNm: json.jsonString(BoardApiJsonKeys.folderNm),
      sortOrder: asJsonIntOpt(json[BoardApiJsonKeys.sortOrder]) ?? 0,
      postCount: asJsonIntOpt(json[BoardApiJsonKeys.postCount]) ?? 0,
      ownerViewYn: json.jsonString(BoardApiJsonKeys.ownerViewYn, 'Y'),
      staffViewYn: json.jsonString(BoardApiJsonKeys.staffViewYn, 'Y'),
    );
  }
}

class BoardPost {
  const BoardPost({
    required this.postIdx,
    required this.folderIdx,
    required this.folderNm,
    required this.title,
    this.bodyTxt = '',
    required this.privateYn,
    required this.noticeYn,
    required this.viewCnt,
    required this.authorNm,
    required this.createdBy,
    required this.createdAtRaw,
    required this.hasAttachment,
    this.thumbContentType,
    this.thumbDocIdx,
    this.storeNm = '',
  });

  final int postIdx;
  final int folderIdx;
  final String folderNm;
  final String title;
  final String bodyTxt;
  final String privateYn;
  final String noticeYn;
  final int viewCnt;
  final String authorNm;
  final String createdBy;
  final String createdAtRaw;
  final bool hasAttachment;
  final String? thumbContentType;
  final int? thumbDocIdx;
  final String storeNm;

  bool get isPrivate => privateYn.trim().toUpperCase() == 'Y';
  bool get isNotice => noticeYn.trim().toUpperCase() == 'Y';
  bool get hasImageThumb => thumbDocIdx != null;

  String get createdAtLabel {
    final raw = createdAtRaw.trim();
    if (raw.isEmpty) return '-';
    final date = raw.contains('T') ? raw.split('T').first : raw;
    return date.replaceAll('-', '.');
  }

  factory BoardPost.fromJson(Map<String, dynamic> json) {
    return BoardPost(
      postIdx: asJsonIntOpt(json[BoardApiJsonKeys.postIdx]) ?? 0,
      folderIdx: asJsonIntOpt(json[BoardApiJsonKeys.folderIdx]) ?? 0,
      folderNm: json.jsonString(BoardApiJsonKeys.folderNm),
      title: json.jsonString(BoardApiJsonKeys.title),
      bodyTxt: json.jsonString(BoardApiJsonKeys.bodyTxt),
      privateYn: json.jsonString(BoardApiJsonKeys.privateYn, 'N'),
      noticeYn: json.jsonString(BoardApiJsonKeys.noticeYn, 'N'),
      viewCnt: asJsonIntOpt(json[BoardApiJsonKeys.viewCnt]) ?? 0,
      authorNm: json.jsonString(BoardApiJsonKeys.authorNm),
      createdBy: json.jsonString(BoardApiJsonKeys.createdBy),
      createdAtRaw: json.jsonString(BoardApiJsonKeys.createdAt),
      hasAttachment: json[BoardApiJsonKeys.hasAttachment] == true,
      thumbContentType: json[BoardApiJsonKeys.thumbContentType] as String?,
      thumbDocIdx: asJsonIntOpt(json[BoardApiJsonKeys.thumbDocIdx]),
      storeNm: json.jsonString(BoardApiJsonKeys.storeNm),
    );
  }

  Map<String, dynamic> toSaveBody({
    required int folderIdx,
    bool privateYn = false,
    bool noticeYn = false,
  }) {
    return {
      BoardApiJsonKeys.folderIdx: folderIdx,
      BoardApiJsonKeys.title: title.trim(),
      BoardApiJsonKeys.bodyTxt: bodyTxt,
      BoardApiJsonKeys.privateYn: privateYn ? 'Y' : 'N',
      BoardApiJsonKeys.noticeYn: noticeYn ? 'Y' : 'N',
    };
  }
}

class BoardDocument {
  const BoardDocument({
    required this.bbsDocIdx,
    required this.postIdx,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
  });

  final int bbsDocIdx;
  final int postIdx;
  final String fileName;
  final int fileSize;
  final String contentType;

  bool get isImage => boardDocumentIsImage(fileName, contentType);

  factory BoardDocument.fromJson(Map<String, dynamic> json) {
    return BoardDocument(
      bbsDocIdx: asJsonIntOpt(json[BoardApiJsonKeys.bbsDocIdx]) ?? 0,
      postIdx: asJsonIntOpt(json[BoardApiJsonKeys.postIdx]) ?? 0,
      fileName: json.jsonString(BoardApiJsonKeys.fileName),
      fileSize: asJsonIntOpt(json[BoardApiJsonKeys.fileSize]) ?? 0,
      contentType: json.jsonString(BoardApiJsonKeys.contentType),
    );
  }
}

bool boardDocumentIsImage(String fileName, String contentType) {
  if (contentType.toLowerCase().startsWith('image/')) return true;
  return storeDocumentPreviewKindFor(fileName) ==
      StoreDocumentPreviewKind.image;
}
