package com.yeokjeon.erp.franchise.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.franchise.dto.StoreHistoryRowDto;
import com.yeokjeon.erp.franchise.dto.StoreMstDto;
import com.yeokjeon.erp.franchise.dto.StoreMstWriteRequestDto;
import com.yeokjeon.erp.franchise.service.StrService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
public class StrController {

    private final StrService strService;

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

    @PostMapping
    public ResponseEntity<ApiResponse<StoreMstDto>> createStore(
            @RequestBody StoreMstWriteRequestDto body) {
        log.info("가맹점 생성 요청: {}", body.storeCd());
        StoreMstDto createdStore = strService.create(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("가맹점이 생성되었습니다", createdStore));
    }

    @PutMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<StoreMstDto>> updateStore(
            @PathVariable Integer storeIdx,
            @RequestBody StoreMstWriteRequestDto body) {
        log.info("가맹점 수정 요청: {}", storeIdx);
        StoreMstDto updatedStore = strService.update(storeIdx, body);
        return ResponseEntity.ok(
                ApiResponse.success("가맹점이 수정되었습니다", updatedStore));
    }

    @DeleteMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteStore(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 삭제 요청: {}", storeIdx);
        strService.remove(storeIdx);
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
