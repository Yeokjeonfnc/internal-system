package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.auth.token.TokenInvalidationRegistry;
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
import java.util.Objects;

/** 가맹점주 — `/owner-users`. */
@RestController
@RequestMapping("/owner-users")
@RequiredArgsConstructor
public class OwnerUserController {

    private final OwnerUserService ownerUserService;
    private final MenuAccessGuard menuAccessGuard;
    private final TokenInvalidationRegistry tokenInvalidationRegistry;

    /*
     * 조회도 잠근다. 여기 나오는 것은 전 가맹점주의 로그인ID·휴대전화·이메일 명부라
     * 쓰기만 막고 읽기를 열어 두면 로그인한 아무나(가맹점주 계정 포함) 통째로 수집할 수
     * 있다. 사용기록(mst005)에 이미 적용한 기준과 같게 맞춘다.
     */

    @GetMapping
    public ResponseEntity<ApiResponse<List<OwnerUserMstDto>>> list(HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(ownerUserService.getAll()));
    }

    @GetMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<OwnerUserMstDto>> one(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.VIEW);
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
        // 바뀌기 전 로그인ID 를 먼저 확보한다 — 저장 뒤에는 알 수 없고, 토큰은
        // 로그인ID 로 무효화하므로 ID 를 바꾼 경우 옛 ID 쪽도 같이 끊어야 한다.
        String previousUserId = ownerUserService.get(userIdx).userId();
        OwnerUserMstDto updated = ownerUserService.save(userIdx, body);
        // 사원(mst001)과 같은 기준 — 비밀번호·로그인ID 를 바꿨는데 토큰을 끊지 않으면
        // 그 사람 휴대폰의 앱이 만료(12시간)까지 그대로 로그인 상태로 남는다.
        boolean credentialChanged =
                (body.getUserPassword() != null && !body.getUserPassword().isBlank())
                        || !Objects.equals(previousUserId, updated.userId());
        if (credentialChanged) {
            tokenInvalidationRegistry.invalidateAll(previousUserId);
            tokenInvalidationRegistry.invalidateAll(updated.userId());
        }
        return ResponseEntity.ok(ApiResponse.success("가맹점주 정보가 수정되었습니다.", updated));
    }

    @DeleteMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Integer userIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(callerId(request), MenuCodes.MST006, MenuAccessGuard.Action.DELETE);
        // 삭제 전에 로그인 ID 를 확보해 둔다 — 지운 뒤에는 조회할 수 없다.
        OwnerUserMstDto target = ownerUserService.get(userIdx);
        ownerUserService.remove(userIdx);
        tokenInvalidationRegistry.invalidateAll(target.userId());
        return ResponseEntity.ok(ApiResponse.success("가맹점주가 삭제되었습니다.", null));
    }

    /** 토큰에서 확인된 호출자 — 요청 파라미터가 아니므로 사칭할 수 없다. */
    private static String callerId(HttpServletRequest request) {
        Object v = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? null : v.toString();
    }
}
