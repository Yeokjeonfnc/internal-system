import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import 'package:app_flutter/core/api/base_repository.dart';
import 'package:app_flutter/core/board/board_api_json_keys.dart';
import 'package:app_flutter/pages/board/bbs001/bbs001_model.dart';
import 'package:app_flutter/pages/franchise/str001/store_document_preview_kind.dart';

class Bbs001ApiService extends BaseRepository {
  Future<List<BoardFolder>> getFolders(String userId) => getDataList(
    BoardApiPaths.folders,
    queryParameters: {BoardApiJsonKeys.userId: userId},
    fromJson: BoardFolder.fromJson,
  );

  Future<BoardFolder?> createFolder({
    required String userId,
    required String folderNm,
    int sortOrder = 0,
    bool ownerView = true,
    bool staffView = true,
  }) => postDataOrNull(
    BoardApiPaths.folders,
    queryParameters: {BoardApiJsonKeys.userId: userId},
    data: {
      BoardApiJsonKeys.folderNm: folderNm,
      BoardApiJsonKeys.sortOrder: sortOrder,
      BoardApiJsonKeys.useYn: 'Y',
      BoardApiJsonKeys.ownerViewYn: ownerView ? 'Y' : 'N',
      BoardApiJsonKeys.staffViewYn: staffView ? 'Y' : 'N',
    },
    fromJson: BoardFolder.fromJson,
  );

  Future<List<BoardPost>> getPosts({
    required String userId,
    int? folderIdx,
    String keyword = '',
  }) => getDataList(
    BoardApiPaths.posts,
    queryParameters: {
      BoardApiJsonKeys.userId: userId,
      BoardApiJsonKeys.folderIdx: ?folderIdx,
      if (keyword.trim().isNotEmpty) BoardApiJsonKeys.keyword: keyword.trim(),
    },
    fromJson: BoardPost.fromJson,
  );

  Future<BoardPost?> getPost({required int postIdx, required String userId}) =>
      getDataOrNull(
        BoardApiPaths.post(postIdx),
        queryParameters: {BoardApiJsonKeys.userId: userId},
        fromJson: BoardPost.fromJson,
      );

  Future<BoardPost?> createPost({
    required String userId,
    required Map<String, dynamic> body,
  }) => postDataOrNull(
    BoardApiPaths.posts,
    queryParameters: {BoardApiJsonKeys.userId: userId},
    data: body,
    fromJson: BoardPost.fromJson,
  );

  Future<BoardPost?> updatePost({
    required int postIdx,
    required String userId,
    required Map<String, dynamic> body,
  }) => putDataOrNull(
    BoardApiPaths.post(postIdx),
    queryParameters: {BoardApiJsonKeys.userId: userId},
    data: body,
    fromJson: BoardPost.fromJson,
  );

  Future<bool> deletePost({
    required int postIdx,
    required String userId,
  }) async {
    try {
      final r = await client.delete(
        BoardApiPaths.post(postIdx),
        queryParameters: {BoardApiJsonKeys.userId: userId},
      );
      return isHttpSuccess(r.statusCode);
    } catch (e) {
      debugPrint('deletePost failed: $e');
      return false;
    }
  }

  Future<List<BoardDocument>> getDocuments({
    required int postIdx,
    required String userId,
  }) => getDataList(
    BoardApiPaths.documents(postIdx),
    queryParameters: {BoardApiJsonKeys.userId: userId},
    fromJson: BoardDocument.fromJson,
  );

  Future<BoardDocument?> uploadDocument({
    required int postIdx,
    required String userId,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final mime = _mimeTypeForFileName(fileName);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: mime,
        ),
      });
      final r = await client.postMultipart(
        BoardApiPaths.documents(postIdx),
        formData: formData,
        queryParameters: {BoardApiJsonKeys.userId: userId},
      );
      if (r.data == null || !envelopeSuccess(r.data)) {
        debugPrint(
          'uploadDocument failed: ${envelopeMessage(r.data) ?? r.statusCode}',
        );
        return null;
      }
      if (!isHttpSuccess(r.statusCode)) return null;
      return parseDataOrNull(r.data, BoardDocument.fromJson);
    } catch (e, st) {
      debugPrint('uploadDocument failed: $e\n$st');
      return null;
    }
  }

  Future<void> deleteDocument({
    required int postIdx,
    required int bbsDocIdx,
    required String userId,
  }) async {
    await client.delete(
      BoardApiPaths.document(postIdx, bbsDocIdx),
      queryParameters: {BoardApiJsonKeys.userId: userId},
    );
  }

  Future<Uint8List?> downloadDocumentBytes({
    required int postIdx,
    required int bbsDocIdx,
    required String userId,
  }) async {
    try {
      final r = await client.get(
        BoardApiPaths.documentDownload(postIdx, bbsDocIdx),
        queryParameters: {BoardApiJsonKeys.userId: userId},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          headers: {Headers.acceptHeader: '*/*'},
        ),
      );
      if (!isHttpSuccess(r.statusCode) || r.data == null) return null;
      final data = r.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
    } catch (e) {
      debugPrint('downloadDocumentBytes failed: $e');
    }
    return null;
  }

  Future<List<BoardComment>> getComments({
    required int postIdx,
    required String userId,
  }) => getDataList(
    BoardApiPaths.comments(postIdx),
    queryParameters: {BoardApiJsonKeys.userId: userId},
    fromJson: BoardComment.fromJson,
  );

  Future<BoardComment?> createComment({
    required int postIdx,
    required String userId,
    required String bodyTxt,
  }) => postDataOrNull(
    BoardApiPaths.comments(postIdx),
    queryParameters: {BoardApiJsonKeys.userId: userId},
    data: {BoardApiJsonKeys.bodyTxt: bodyTxt},
    fromJson: BoardComment.fromJson,
  );

  Future<bool> deleteComment({
    required int postIdx,
    required int commentIdx,
    required String userId,
  }) async {
    try {
      final r = await client.delete(
        BoardApiPaths.comment(postIdx, commentIdx),
        queryParameters: {BoardApiJsonKeys.userId: userId},
      );
      return isHttpSuccess(r.statusCode);
    } catch (e) {
      debugPrint('deleteComment failed: $e');
      return false;
    }
  }

  MediaType? _mimeTypeForFileName(String fileName) {
    final kind = storeDocumentPreviewKindFor(fileName);
    return switch (kind) {
      StoreDocumentPreviewKind.image => _imageMimeType(fileName),
      StoreDocumentPreviewKind.pdf => MediaType('application', 'pdf'),
      StoreDocumentPreviewKind.unsupported => null,
    };
  }

  MediaType _imageMimeType(String fileName) {
    final lower = fileName.trim().toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.bmp')) return MediaType('image', 'bmp');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }
}
