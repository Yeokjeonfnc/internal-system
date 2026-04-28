package com.yeokjeon.erp.store.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.store.dto.StoreCreateDto;
import com.yeokjeon.erp.store.dto.StoreHistoryResponseDto;
import com.yeokjeon.erp.store.dto.StoreResponseDto;
import com.yeokjeon.erp.store.service.StoreService;
import jakarta.validation.Valid;
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
public class StoreController {

    private final StoreService storeService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<StoreResponseDto>>> getAllStores() {
        log.info("가맹점 목록 조회 요청");
        List<StoreResponseDto> stores = storeService.getAllStores();
        return ResponseEntity.ok(ApiResponse.success(stores));
    }

    @GetMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<StoreResponseDto>> getStore(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 상세 조회 요청: {}", storeIdx);
        StoreResponseDto store = storeService.getStoreByIdx(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(store));
    }

    @GetMapping("/{storeIdx}/histories")
    public ResponseEntity<ApiResponse<List<StoreHistoryResponseDto>>> getStoreHistories(
            @PathVariable Integer storeIdx) {
        log.info("가맹점 히스토리 조회 요청: {}", storeIdx);
        List<StoreHistoryResponseDto> histories = storeService.getStoreHistories(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(histories));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<StoreResponseDto>> createStore(
            @Valid @RequestBody StoreCreateDto dto) {
        log.info("가맹점 생성 요청: {}", dto.getStoreCd());
        StoreResponseDto createdStore = storeService.createStore(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("가맹점이 생성되었습니다", createdStore));
    }

    @PutMapping("/{storeIdx}")
    public ResponseEntity<ApiResponse<StoreResponseDto>> updateStore(
            @PathVariable Integer storeIdx,
            @Valid @RequestBody StoreCreateDto dto) {
        log.info("가맹점 수정 요청: {}", storeIdx);
        StoreResponseDto updatedStore = storeService.updateStore(storeIdx, dto);
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
    public ResponseEntity<ApiResponse<List<StoreResponseDto>>> searchStores(
            @RequestParam String storeNm) {
        log.info("가맹점 검색 요청: {}", storeNm);
        List<StoreResponseDto> stores = storeService.searchStoresByName(storeNm);
        return ResponseEntity.ok(ApiResponse.success(stores));
    }
}
