package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

/** {@code POST /users} 요청 본문 — {@code user_idx}는 DB가 부여(IDENTITY). */
@JsonIgnoreProperties(ignoreUnknown = true)
public record UserMstCreateRequestDto(
        @NotBlank String userName,
        @NotBlank String userPassword,
        String userId,
        Integer deptIdx,
        String userPhone,
        String userEmail,
        String svYn,
        String positionCd,
        String ownerYn,
        LocalDate joinDt) {}
