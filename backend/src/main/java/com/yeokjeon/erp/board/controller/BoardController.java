package com.yeokjeon.erp.board.controller;

import com.yeokjeon.erp.board.dto.BbsCommentDto;
import com.yeokjeon.erp.board.dto.BbsCommentSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsFolderDto;
import com.yeokjeon.erp.board.dto.BbsFolderSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsPostDto;
import com.yeokjeon.erp.board.dto.BbsPostSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsDocumentDto;
import com.yeokjeon.erp.board.service.BoardCommentService;
import com.yeokjeon.erp.board.service.BoardDocumentService;
import com.yeokjeon.erp.board.service.BoardService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 게시판(bbs001).
 *
 * <p><b>여기에 {@code MenuAccessGuard} 를 걸지 말 것.</b> 게시판은 메뉴 권한 검사를
 * 이미 {@link com.yeokjeon.erp.board.service.BoardAccessService} 에서 하고 있다 —
 * 같은 {@code MenuPermissionService} 로 같은 {@code bbs001} 코드를 보고, 거기에
 * 소유권(본인 글인지)·폴더 공개범위까지 더 본다. 즉 가드를 추가해도 새로 막히는
 * 것은 없고 검사만 두 번 돈다.
 *
 * <p>게다가 <b>추가하면 가맹점주가 게시판을 통째로 못 쓴다.</b> 가맹점주 계정은
 * {@code OwnerUserService} 가 만들고 메뉴권한 관리 화면(mst003)을 거치지 않아
 * {@code user_menu_auth} 에 행이 하나도 없다. {@code BoardAccessService} 는 이걸 알고
 * {@code ownerYn='Y'} 를 권한표 조회 전에 통과시키지만, {@code MenuAccessGuard} 에는
 * 그 예외가 없어 권한 없음으로 떨어진다(글쓰기·수정·삭제·첨부 전부).
 */
@RestController
@RequestMapping("/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;
    private final BoardDocumentService boardDocumentService;
    private final BoardCommentService boardCommentService;

    @GetMapping("/folders")
    public ResponseEntity<ApiResponse<List<BbsFolderDto>>> listFolders(
            @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(boardService.listFolders(userId)));
    }

    @PostMapping("/folders")
    public ResponseEntity<ApiResponse<BbsFolderDto>> createFolder(
            @RequestParam String userId,
            @Valid @RequestBody BbsFolderSaveRequestDto body) {
        return ResponseEntity.ok(
                ApiResponse.success("폴더가 등록되었습니다.", boardService.createFolder(userId, body)));
    }

    @PutMapping("/folders/{folderIdx}")
    public ResponseEntity<ApiResponse<BbsFolderDto>> updateFolder(
            @PathVariable int folderIdx,
            @RequestParam String userId,
            @RequestBody BbsFolderSaveRequestDto body) {
        return ResponseEntity.ok(
                ApiResponse.success("폴더가 수정되었습니다.", boardService.updateFolder(folderIdx, userId, body)));
    }

    @DeleteMapping("/folders/{folderIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteFolder(
            @PathVariable int folderIdx, @RequestParam String userId) {
        boardService.deleteFolder(folderIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("폴더가 삭제되었습니다.", null));
    }

    @GetMapping("/posts")
    public ResponseEntity<ApiResponse<List<BbsPostDto>>> listPosts(
            @RequestParam String userId,
            @RequestParam(required = false) Integer folderIdx,
            @RequestParam(required = false) String keyword) {
        return ResponseEntity.ok(
                ApiResponse.success(boardService.listPosts(userId, folderIdx, keyword)));
    }

    @GetMapping("/posts/{postIdx}")
    public ResponseEntity<ApiResponse<BbsPostDto>> getPost(
            @PathVariable int postIdx, @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(boardService.getPost(postIdx, userId, true)));
    }

    @PostMapping("/posts")
    public ResponseEntity<ApiResponse<BbsPostDto>> createPost(
            @RequestParam String userId, @Valid @RequestBody BbsPostSaveRequestDto body) {
        return ResponseEntity.ok(
                ApiResponse.success("게시글이 등록되었습니다.", boardService.createPost(userId, body)));
    }

    @PutMapping("/posts/{postIdx}")
    public ResponseEntity<ApiResponse<BbsPostDto>> updatePost(
            @PathVariable int postIdx,
            @RequestParam String userId,
            @RequestBody BbsPostSaveRequestDto body) {
        return ResponseEntity.ok(
                ApiResponse.success("게시글이 수정되었습니다.", boardService.updatePost(postIdx, userId, body)));
    }

    @DeleteMapping("/posts/{postIdx}")
    public ResponseEntity<ApiResponse<Void>> deletePost(
            @PathVariable int postIdx, @RequestParam String userId) {
        boardService.deletePost(postIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("게시글이 삭제되었습니다.", null));
    }

    @GetMapping("/posts/{postIdx}/documents")
    public ResponseEntity<ApiResponse<List<BbsDocumentDto>>> listDocuments(
            @PathVariable int postIdx, @RequestParam String userId) {
        return ResponseEntity.ok(
                ApiResponse.success(boardDocumentService.list(postIdx, userId)));
    }

    @PostMapping(value = "/posts/{postIdx}/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<BbsDocumentDto>> uploadDocument(
            @PathVariable int postIdx,
            @RequestParam String userId,
            @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(
                ApiResponse.success(
                        "파일이 업로드되었습니다.",
                        boardDocumentService.upload(postIdx, file, userId)));
    }

    @GetMapping("/posts/{postIdx}/documents/{bbsDocIdx}/download")
    public ResponseEntity<org.springframework.core.io.Resource> downloadDocument(
            @PathVariable int postIdx,
            @PathVariable int bbsDocIdx,
            @RequestParam String userId) throws Exception {
        BoardDocumentService.DownloadPayload payload =
                boardDocumentService.download(postIdx, bbsDocIdx, userId);
        String encoded =
                URLEncoder.encode(payload.fileName(), StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encoded)
                .contentType(
                        payload.contentType() != null
                                ? MediaType.parseMediaType(payload.contentType())
                                : MediaType.APPLICATION_OCTET_STREAM)
                .body(payload.resource());
    }

    @GetMapping("/posts/{postIdx}/comments")
    public ResponseEntity<ApiResponse<List<BbsCommentDto>>> listComments(
            @PathVariable int postIdx, @RequestParam String userId) {
        return ResponseEntity.ok(
                ApiResponse.success(boardCommentService.list(postIdx, userId)));
    }

    @PostMapping("/posts/{postIdx}/comments")
    public ResponseEntity<ApiResponse<BbsCommentDto>> createComment(
            @PathVariable int postIdx,
            @RequestParam String userId,
            @Valid @RequestBody BbsCommentSaveRequestDto body) {
        return ResponseEntity.ok(
                ApiResponse.success(
                        "댓글이 등록되었습니다.",
                        boardCommentService.create(postIdx, userId, body)));
    }

    @DeleteMapping("/posts/{postIdx}/comments/{commentIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(
            @PathVariable int postIdx,
            @PathVariable int commentIdx,
            @RequestParam String userId) {
        boardCommentService.delete(postIdx, commentIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("댓글이 삭제되었습니다.", null));
    }

    @DeleteMapping("/posts/{postIdx}/documents/{bbsDocIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteDocument(
            @PathVariable int postIdx,
            @PathVariable int bbsDocIdx,
            @RequestParam String userId) {
        boardDocumentService.delete(postIdx, bbsDocIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("첨부 파일이 삭제되었습니다.", null));
    }
}
