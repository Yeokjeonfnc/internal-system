package com.yeokjeon.erp.master.dto;

import jakarta.validation.constraints.NotBlank;

/** 클라이언트 메뉴 사용 기록 요청. */
public record UsageLogMenuRequestDto(
        @NotBlank String userId,
        @NotBlank String userNm,
        String deptNm,
        String positionNm,
        String svYn,
        String menuCd,
        @NotBlank String menuLabel) {}
