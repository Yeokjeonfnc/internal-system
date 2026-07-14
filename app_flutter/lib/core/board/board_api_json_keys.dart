/// 게시판 API JSON 키.
abstract final class BoardApiJsonKeys {
  static const String folderIdx = 'folderIdx';
  static const String folderNm = 'folderNm';
  static const String sortOrder = 'sortOrder';
  static const String useYn = 'useYn';
  static const String ownerViewYn = 'ownerViewYn';
  static const String staffViewYn = 'staffViewYn';
  static const String postCount = 'postCount';

  static const String postIdx = 'postIdx';
  static const String title = 'title';
  static const String bodyTxt = 'bodyTxt';
  static const String privateYn = 'privateYn';
  static const String noticeYn = 'noticeYn';
  static const String viewCnt = 'viewCnt';
  static const String createdBy = 'createdBy';
  static const String authorNm = 'authorNm';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String hasAttachment = 'hasAttachment';
  static const String thumbContentType = 'thumbContentType';
  static const String thumbDocIdx = 'thumbDocIdx';
  static const String storeIdx = 'storeIdx';
  static const String storeNm = 'storeNm';

  static const String bbsDocIdx = 'bbsDocIdx';
  static const String fileName = 'fileName';
  static const String fileSize = 'fileSize';
  static const String contentType = 'contentType';
  static const String attachedAt = 'attachedAt';
  static const String fileExists = 'fileExists';

  static const String userId = 'userId';
  static const String keyword = 'keyword';
}

abstract final class BoardApiPaths {
  static const String folders = '/board/folders';
  static String folder(int folderIdx) => '$folders/$folderIdx';
  static const String posts = '/board/posts';
  static String post(int postIdx) => '$posts/$postIdx';
  static String documents(int postIdx) => '${post(postIdx)}/documents';
  static String documentDownload(int postIdx, int bbsDocIdx) =>
      '${post(postIdx)}/documents/$bbsDocIdx/download';
  static String document(int postIdx, int bbsDocIdx) =>
      '${post(postIdx)}/documents/$bbsDocIdx';
}
