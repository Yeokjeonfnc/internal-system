package com.yeokjeon.erp.auth.controller;

import com.yeokjeon.erp.auth.dto.AuthChangePasswordRequestDto;
import com.yeokjeon.erp.auth.dto.AuthLoginRequestDto;
import com.yeokjeon.erp.auth.dto.AuthProfileDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import com.yeokjeon.erp.auth.dto.AuthTokenDto;
import com.yeokjeon.erp.auth.login.LoginAttemptGuard;
import com.yeokjeon.erp.auth.service.AuthService;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.auth.token.AuthTokenService;
import com.yeokjeon.erp.auth.token.TokenInvalidationRegistry;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final LoginAttemptGuard loginAttemptGuard;
    private final AuthTokenService authTokenService;
    private final TokenInvalidationRegistry tokenInvalidationRegistry;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthProfileDto>> login(
            @Valid @RequestBody AuthLoginRequestDto body) {
        log.info("로그인 요청: userId={}", body.userId());

        // 연속 실패가 쌓인 계정은 비밀번호가 맞아도 잠금이 풀릴 때까지 거절한다.
        long lockedFor = loginAttemptGuard.lockedSecondsRemaining(body.userId());
        if (lockedFor > 0) {
            log.warn("잠긴 계정 로그인 시도: userId={}", body.userId());
            return ResponseEntity
                    .status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(ApiResponse.error(
                            "로그인 시도가 너무 많습니다. " + ((lockedFor / 60) + 1) + "분 후 다시 시도해 주세요."));
        }

        AuthProfileDto result = authService.login(body);

        if (result == null) {
            loginAttemptGuard.recordFailure(body.userId());
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("아이디 또는 비밀번호가 일치하지 않습니다."));
        }

        loginAttemptGuard.recordSuccess(body.userId());
        log.info("로그인 성공: userId={}, userNm={}", result.userId(), result.userNm());
        return ResponseEntity.ok(ApiResponse.success("로그인 되었습니다.", result));
    }

    /**
     * 비밀번호 변경. 신분은 토큰에서 가져오므로 대상 사용자를 요청에서 받지 않는다
     * (남의 비밀번호를 바꾸는 경로를 만들지 않기 위함).
     */
    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<AuthTokenDto>> changePassword(
            @Valid @RequestBody AuthChangePasswordRequestDto body,
            HttpServletRequest request) {
        Object authenticated = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        if (authenticated == null) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("로그인이 필요합니다."));
        }
        String userId = authenticated.toString();
        String failure = authService.changePassword(
                userId, body.currentPassword(), body.newPassword());
        if (failure != null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(failure));
        }
        // 트랜잭션 밖에서 처리한다 — 선택 컬럼이라 실패할 수 있고, 안에서 실패하면
        // 이미 성공한 비밀번호 변경까지 롤백된다.
        authService.clearPasswordResetFlag(userId);

        // 비밀번호를 바꾸는 이유는 대개 "누가 들어온 것 같아서"다. 무상태 토큰은 그대로 두면
        // 이미 새어 나간 토큰이 만료까지 계속 통하므로, 기존 토큰을 전부 끊고 새로 발급한다.
        long cutoff = tokenInvalidationRegistry.invalidateAll(userId);
        String reissued = authTokenService.issue(userId, cutoff + 1);

        // 잠금 상태에서 비밀번호를 바꿨다면 실패 누적도 함께 푼다.
        loginAttemptGuard.recordSuccess(userId);
        return ResponseEntity.ok(
                ApiResponse.success("비밀번호가 변경되었습니다.", new AuthTokenDto(reissued)));
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<AuthProfileDto>> getProfile(
            @RequestParam String userId) {
        log.info("사용자 정보 조회 요청: userId={}", userId);

        AuthProfileDto result = authService.getUserProfile(userId);

        if (result == null) {
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("사용자 정보를 찾을 수 없습니다."));
        }

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<AuthProfileDto>> updateProfile(
            @RequestParam String userId,
            @RequestBody AuthProfileUpdateRequestDto body) {
        log.info("사용자 정보 수정 요청: userId={}", userId);

        AuthProfileDto result = authService.updateUserProfile(userId, body);

        if (result == null) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("사용자 정보 수정에 실패했습니다."));
        }

        log.info("사용자 정보 수정 성공: userId={}", userId);
        return ResponseEntity.ok(ApiResponse.success("사용자 정보가 수정되었습니다.", result));
    }
}
