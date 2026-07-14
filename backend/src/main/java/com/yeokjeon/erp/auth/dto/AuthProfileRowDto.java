package com.yeokjeon.erp.auth.dto;

import java.time.LocalDate;

/**
 * MyBatis 조회 전용 — SQL 컬럼과 1:1 (생성자 자동 매핑).
 * API 응답은 {@link AuthProfileDto} 를 사용한다.
 */
public record AuthProfileRowDto(
        Integer userIdx,
        String userId,
        String userNm,
        String email,
        Integer deptIdx,
        String userPhone,
        String deptNm,
        String positionCd,
        String positionNm,
        String svYn,
        String ownerYn,
        String adminYn,
        Integer storeIdx,
        String storeNm,
        LocalDate joinDt) {}
