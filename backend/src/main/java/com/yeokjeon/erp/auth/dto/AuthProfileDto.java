package com.yeokjeon.erp.auth.dto;

import java.time.LocalDate;

/**
 * 로그인·프로필 조회/수정 응답 — 기존 {@code Map} 키와 동일(프론트 {@code AuthProvider} 호환).
 */
public record AuthProfileDto(
        String userId,
        String userNm,
        String email,
        Integer deptIdx,
        String userPhone,
        String deptNm,
        String positionCd,
        String positionNm,
        String svYn,
        String tagYn,
        LocalDate joinDt) {}
