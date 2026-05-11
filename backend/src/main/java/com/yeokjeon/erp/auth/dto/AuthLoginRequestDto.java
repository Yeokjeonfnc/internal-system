package com.yeokjeon.erp.auth.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;

/** {@code POST /auth/login} 요청 본문. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record AuthLoginRequestDto(
        @NotBlank String userId,
        @NotBlank String userPassword) {}
