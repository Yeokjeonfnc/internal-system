package com.yeokjeon.erp.board.controller;

import com.yeokjeon.erp.board.dto.BbsFolderDto;
import com.yeokjeon.erp.board.dto.BbsFolderSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsPostDto;
import com.yeokjeon.erp.board.dto.BbsPostSaveRequestDto;
import com.yeokjeon.erp.board.dto.BbsDocumentDto;
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

@RestController
@RequestMapping("/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;
    private final BoardDocumentService boardDocumentService;

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

    @DeleteMapping("/posts/{postIdx}/documents/{bbsDocIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteDocument(
            @PathVariable int postIdx,
            @PathVariable int bbsDocIdx,
            @RequestParam String userId) {
        boardDocumentService.delete(postIdx, bbsDocIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("첨부 파일이 삭제되었습니다.", null));
    }
}
