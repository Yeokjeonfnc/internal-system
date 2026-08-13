package com.yeokjeon.erp.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** {@code POST /auth/change-password} 요청 본문. */
public record AuthChangePasswordRequestDto(
        @NotBlank(message = "현재 비밀번호를 입력해 주세요.") String currentPassword,
        @NotBlank(message = "새 비밀번호를 입력해 주세요.") String newPassword) {}
