package com.yeokjeon.erp.franchise.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagDto;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagLookupDto;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagRegisterRequestDto;
import com.yeokjeon.erp.franchise.service.StoreNfcTagService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
public class StoreNfcTagController {

    private final StoreNfcTagService storeNfcTagService;

    @GetMapping("/by-nfc-tag")
    public ResponseEntity<ApiResponse<StoreNfcTagLookupDto>> lookupByTagUid(
            @RequestParam String tagUid) {
        return ResponseEntity.ok(
                ApiResponse.success(storeNfcTagService.lookupByTagUid(tagUid)));
    }

    @GetMapping("/{storeIdx}/nfc-tag")
    public ResponseEntity<ApiResponse<StoreNfcTagDto>> getStoreNfcTag(
            @PathVariable Integer storeIdx) {
        StoreNfcTagDto dto = storeNfcTagService.findByStoreIdx(storeIdx);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PutMapping("/{storeIdx}/nfc-tag")
    public ResponseEntity<ApiResponse<StoreNfcTagDto>> registerStoreNfcTag(
            @PathVariable Integer storeIdx,
            @Valid @RequestBody StoreNfcTagRegisterRequestDto body) {
        StoreNfcTagDto saved = storeNfcTagService.register(
                storeIdx, body.tagUid(), body.registeredBy());
        return ResponseEntity.ok(ApiResponse.success("NFC 태그가 등록되었습니다", saved));
    }

    @DeleteMapping("/{storeIdx}/nfc-tag")
    public ResponseEntity<ApiResponse<Void>> deleteStoreNfcTag(
            @PathVariable Integer storeIdx) {
        storeNfcTagService.remove(storeIdx);
        return ResponseEntity.ok(ApiResponse.success("NFC 태그 등록이 해제되었습니다", null));
    }
}
