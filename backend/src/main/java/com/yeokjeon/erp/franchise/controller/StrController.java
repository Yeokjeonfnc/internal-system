package com.yeokjeon.erp.franchise.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.franchise.dto.StoreDocumentDto;
import com.yeokjeon.erp.franchise.dto.StoreHistoryRowDto;
import com.yeokjeon.erp.franchise.dto.StoreMstDto;
import com.yeokjeon.erp.franchise.dto.StoreMstWriteRequestDto;
import com.yeokjeon.erp.franchise.service.StoreDocumentService;
import com.yeokjeon.erp.franchise.service.StrService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
public class StrController {

    private final StrService strService;
    private final StoreDocumentService storeDocumentService;
    private final MenuAccessGuard menuAccessGuard;

    @GetMapping
    public ResponseEntity<ApiResponse<List<StoreMstDto>>> getAllStores() {
        log.info("가맹점 목록 조회 요청");
        List<StoreMstDto> stores = strService.list();
        return ResponseEntity.ok(ApiResponse.success(stores));
    }

    @GetMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<StoreMstDto>> getStore(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 상세 조회 요청: {}", storeIdx);
        StoreMstDto store = strService.one(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(store));
    }

    @GetMapping("/{storeIdx}/histories")
    public ResponseEntity<ApiResponse<List<StoreHistoryRowDto>>> getStoreHistories(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 히스토리 조회 요청: {}", storeIdx);
        List<StoreHistoryRowDto> histories = strService.listHistories(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(histories));
    }

    @GetMapping("/{storeIdx}/documents")
    public ResponseEntity<ApiResponse<List<StoreDocumentDto>>> getStoreDocuments(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 문서 목록 조회: {}", storeIdx);
        return ResponseEntity.ok(ApiResponse.success(storeDocumentService.list(storeIdx)));
    }

    /*
     * 아래 문서 업로드·삭제는 남의 가맹점에 붙은 계약서·서류를 건드리는 작업이다.
     * userId 파라미터는 "누가 올렸는지" 기록용일 뿐 권한을 뜻하지 않아서,
     * 검사가 없으면 로그인만 한 사람이 아무 가맹점 문서나 올리고 지울 수 있다.
     * 가맹점 관리(str001) 권한을 요구한다.
     */

    @PostMapping(value = "/{storeIdx}/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<StoreDocumentDto>> uploadStoreDocument(
            @PathVariable Integer storeIdx,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) String userId,
            @RequestParam(value = "attachmentBaseDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate attachmentBaseDate,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.STR001, MenuAccessGuard.Action.CREATE);
        log.info("가맹점 문서 업로드: storeIdx={}, file={}", storeIdx, file.getOriginalFilename());
        StoreDocumentDto created = storeDocumentService.upload(
                storeIdx, file, userId, attachmentBaseDate);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("문서가 업로드되었습니다", created));
    }

    @GetMapping("/{storeIdx}/documents/{storeDocIdx}/download")
    public ResponseEntity<org.springframework.core.io.Resource> downloadStoreDocument(
            @PathVariable Integer storeIdx,
            @PathVariable Integer storeDocIdx) {
        StoreDocumentService.DownloadPayload payload =
                storeDocumentService.download(storeIdx, storeDocIdx);
        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (payload.contentType() != null && !payload.contentType().isBlank()) {
            mediaType = MediaType.parseMediaType(payload.contentType());
        }
        ContentDisposition disposition = ContentDisposition.attachment()
                .filename(payload.fileName(), StandardCharsets.UTF_8)
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .contentType(mediaType)
                .body(payload.resource());
    }

    @DeleteMapping("/{storeIdx}/documents/{storeDocIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteStoreDocument(
            @PathVariable Integer storeIdx,
            @PathVariable Integer storeDocIdx,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.STR001, MenuAccessGuard.Action.DELETE);
        log.info("가맹점 문서 삭제: storeIdx={}, docIdx={}", storeIdx, storeDocIdx);
        storeDocumentService.delete(storeIdx, storeDocIdx);
        return ResponseEntity.ok(ApiResponse.success("문서가 삭제되었습니다", null));
    }

    /*
     * 가맹점 마스터 자체를 만들고 바꾸고 지우는 작업이다. 로그인 여부만 보던
     * 기존 상태에서는 아무 직원이나 남의 가맹점 정보를 수정하거나 통째로
     * 삭제할 수 있었다. 가맹점 관리(str001) 권한을 요구한다.
     */

    @PostMapping
    public ResponseEntity<ApiResponse<StoreMstDto>> createStore(
            @RequestBody StoreMstWriteRequestDto body, HttpServletRequest request) {
        // 변경 이력의 '수정자'로 남길 호출자 — 요청 파라미터가 아니라 토큰 주인이라 사칭 불가.
        String callerId = MenuAccessGuard.callerId(request);
        menuAccessGuard.ensure(callerId, MenuCodes.STR001, MenuAccessGuard.Action.CREATE);
        log.info("가맹점 생성 요청: {}", body.storeCd());
        StoreMstDto createdStore = strService.create(body, callerId);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("가맹점이 생성되었습니다", createdStore));
    }

    @PutMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<StoreMstDto>> updateStore(
            @PathVariable Integer storeIdx,
            @RequestBody StoreMstWriteRequestDto body,
            HttpServletRequest request) {
        String callerId = MenuAccessGuard.callerId(request);
        menuAccessGuard.ensure(callerId, MenuCodes.STR001, MenuAccessGuard.Action.UPDATE);
        log.info("가맹점 수정 요청: {}", storeIdx);
        StoreMstDto updatedStore = strService.update(storeIdx, body, callerId);
        return ResponseEntity.ok(
                ApiResponse.success("가맹점이 수정되었습니다", updatedStore));
    }

    @DeleteMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteStore(
            @PathVariable Integer storeIdx, HttpServletRequest request) {
        String callerId = MenuAccessGuard.callerId(request);
        menuAccessGuard.ensure(callerId, MenuCodes.STR001, MenuAccessGuard.Action.DELETE);
        log.info("가맹점 삭제 요청: {}", storeIdx);
        strService.remove(storeIdx, callerId);
        return ResponseEntity.ok(
                ApiResponse.success("가맹점이 삭제되었습니다", null));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<StoreMstDto>>> searchStores(
            @RequestParam String storeNm) {
        log.info("가맹점 검색 요청: {}", storeNm);
        List<StoreMstDto> stores = strService.listByStoreName(storeNm);
        return ResponseEntity.ok(ApiResponse.success(stores));
    }
}
