package com.yeokjeon.erp.str001.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.str001.service.StoreService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
public class StoreController {

    private final StoreService storeService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllStores() {
        log.info("가맹점 목록 조회 요청");
        List<Map<String, Object>> stores = storeService.getAllStores();
        return ResponseEntity.ok(ApiResponse.success(stores));
    }

    @GetMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStore(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 상세 조회 요청: {}", storeIdx);
        Map<String, Object> store = storeService.getStoreByIdx(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(store));
    }

    @GetMapping("/{storeIdx}/histories")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getStoreHistories(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 히스토리 조회 요청: {}", storeIdx);
        List<Map<String, Object>> histories = storeService.getStoreHistories(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(histories));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createStore(
            @RequestBody Map<String, Object> body) {
        log.info("가맹점 생성 요청: {}", body != null ? body.get("storeCd") : null);
        Map<String, Object> createdStore = storeService.createStore(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("가맹점이 생성되었습니다", createdStore));
    }

    @PutMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateStore(
            @PathVariable Integer storeIdx,
            @RequestBody Map<String, Object> body) {
        log.info("가맹점 수정 요청: {}", storeIdx);
        Map<String, Object> updatedStore = storeService.updateStore(storeIdx, body);
        return ResponseEntity.ok(
                ApiResponse.success("가맹점이 수정되었습니다", updatedStore));
    }

    @DeleteMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteStore(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 삭제 요청: {}", storeIdx);
        storeService.deleteStore(storeIdx);
        return ResponseEntity.ok(
                ApiResponse.success("가맹점이 삭제되었습니다", null));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> searchStores(
            @RequestParam String storeNm) {
        log.info("가맹점 검색 요청: {}", storeNm);
        List<Map<String, Object>> stores = storeService.searchStoresByName(storeNm);
        return ResponseEntity.ok(ApiResponse.success(stores));
    }
}
