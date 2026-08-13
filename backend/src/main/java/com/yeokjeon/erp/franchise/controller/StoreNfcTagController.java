package com.yeokjeon.erp.franchise.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagDto;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagLookupDto;
import com.yeokjeon.erp.franchise.dto.StoreNfcTagRegisterRequestDto;
import com.yeokjeon.erp.franchise.service.StoreNfcTagService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
public class StoreNfcTagController {

    private final StoreNfcTagService storeNfcTagService;
    private final MenuAccessGuard menuAccessGuard;

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

    /*
     * 아래 2개는 가맹점의 출입 인증 수단 자체를 바꾸는 작업이다. 권한 검사가 없으면
     * 로그인한 아무나 남의 매장에 자기 태그를 심어 출입기록을 위조하거나(등록은
     * upsert 라 기존 태그를 덮어쓴다), 태그를 지워 정상 출입을 막을 수 있다.
     * 가맹점 관리(str001) 권한을 요구한다.
     */

    @PutMapping("/{storeIdx}/nfc-tag")
    public ResponseEntity<ApiResponse<StoreNfcTagDto>> registerStoreNfcTag(
            @PathVariable Integer storeIdx,
            @Valid @RequestBody StoreNfcTagRegisterRequestDto body,
            HttpServletRequest request) {
        String callerId = MenuAccessGuard.callerId(request);
        menuAccessGuard.ensure(callerId, MenuCodes.STR001, MenuAccessGuard.Action.CREATE);
        // registeredBy 는 "누가 등록했는가"를 남기는 기록인데 본문으로 들어온다.
        // AuthTokenFilter 는 쿼리 파라미터만 대조하고 본문은 보지 않으므로 남의
        // 이름으로 등록 기록을 남길 수 있다. 토큰에서 확인된 호출자로 덮어쓴다
        // (화면도 본인 로그인ID 를 보내므로 정상 사용에는 차이가 없다).
        StoreNfcTagDto saved = storeNfcTagService.register(storeIdx, body.tagUid(), callerId);
        return ResponseEntity.ok(ApiResponse.success("NFC 태그가 등록되었습니다", saved));
    }

    @DeleteMapping("/{storeIdx}/nfc-tag")
    public ResponseEntity<ApiResponse<Void>> deleteStoreNfcTag(
            @PathVariable Integer storeIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.STR001, MenuAccessGuard.Action.DELETE);
        storeNfcTagService.remove(storeIdx);
        return ResponseEntity.ok(ApiResponse.success("NFC 태그 등록이 해제되었습니다", null));
    }
}
