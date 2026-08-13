package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.OwnerUserMstCreateRequestDto;
import jakarta.servlet.http.HttpServletRequest;
import com.yeokjeon.erp.master.dto.OwnerUserMstDto;
import com.yeokjeon.erp.master.dto.OwnerUserMstUpdateRequestDto;
import com.yeokjeon.erp.master.service.OwnerUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 가맹점주 — `/owner-users`. */
@RestController
@RequestMapping("/owner-users")
@RequiredArgsConstructor
public class OwnerUserController {

    private final OwnerUserService ownerUserService;
    private final MenuAccessGuard menuAccessGuard;

    @GetMapping
    public ResponseEntity<ApiResponse<List<OwnerUserMstDto>>> list() {
        return ResponseEntity.ok(ApiResponse.success(ownerUserService.getAll()));
    }

    @GetMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> one(@PathVariable Integer userIdx) {
        return ResponseEntity.ok(ApiResponse.success(ownerUserService.get(userIdx)));
    }

    /*
     * 가맹점주도 user_mst 의 계정이다(비밀번호 포함). 사원 계정과 동일하게
     * 권한 검사가 없으면 로그인한 아무나 계정을 만들고 비밀번호를 바꿀 수 있다.
     */

    @PostMapping
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> create(
            @Valid @RequestBody OwnerUserMstCreateRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.CREATE);
        OwnerUserMstDto created = ownerUserService.save(body);
        return ResponseEntity.ok(ApiResponse.success("가맹점주가 등록되었습니다.", created));
    }

    @PutMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> update(
            @PathVariable Integer userIdx,
            @RequestBody OwnerUserMstUpdateRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.UPDATE);
        OwnerUserMstDto updated = ownerUserService.save(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("가맹점주 정보가 수정되었습니다.", updated));
    }

    @DeleteMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.DELETE);
        ownerUserService.remove(userIdx);
        return ResponseEntity.ok(ApiResponse.success("가맹점주가 삭제되었습니다.", null));
    }

    /** 토큰에서 확인된 호출자 — 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? null : v.toString();
    }
}
