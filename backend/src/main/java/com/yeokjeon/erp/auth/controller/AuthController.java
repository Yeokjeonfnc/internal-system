package com.yeokjeon.erp.auth.controller;

import com.yeokjeon.erp.auth.dto.LoginRequestDto;
import com.yeokjeon.erp.auth.dto.LoginResponseDto;
import com.yeokjeon.erp.auth.dto.UserProfileUpdateDto;
import com.yeokjeon.erp.auth.service.AuthService;
import com.yeokjeon.erp.common.ApiResponse;
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

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDto>> login(
            @Valid @RequestBody LoginRequestDto dto) {
        log.info("로그인 요청: userId={}", dto.getUserId());
        
        LoginResponseDto result = authService.login(dto);
        
        if (result == null) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("아이디 또는 비밀번호가 일치하지 않습니다."));
        }
        
        log.info("로그인 성공: userId={}, userNm={}", result.getUserId(), result.getUserNm());
        return ResponseEntity.ok(ApiResponse.success("로그인 되었습니다.", result));
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<LoginResponseDto>> getProfile(
            @RequestParam String userId) {
        log.info("사용자 정보 조회 요청: userId={}", userId);
        
        LoginResponseDto result = authService.getUserProfile(userId);
        
        if (result == null) {
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("사용자 정보를 찾을 수 없습니다."));
        }
        
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<LoginResponseDto>> updateProfile(
            @RequestParam String userId,
            @Valid @RequestBody UserProfileUpdateDto dto) {
        log.info("사용자 정보 수정 요청: userId={}", userId);
        
        LoginResponseDto result = authService.updateUserProfile(userId, dto);
        
        if (result == null) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("사용자 정보 수정에 실패했습니다."));
        }
        
        log.info("사용자 정보 수정 성공: userId={}", userId);
        return ResponseEntity.ok(ApiResponse.success("사용자 정보가 수정되었습니다.", result));
    }
}
