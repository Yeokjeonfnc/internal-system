package com.yeokjeon.erp.master.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;

/**
 * {@code user_mst} + 부서·직급 JOIN 조회 행 — MyBatis {@code MstUserMapper} 전용.
 */
public record MstUserListJdbcRow(
        Integer userIdx,
        String userName,
        String userId,
        Integer deptIdx,
        String deptNm,
        String userPhone,
        String userEmail,
        String svYn,
        String positionCd,
        String positionNm,
        String ownerYn,
        LocalDate joinDt,
        String workYn,
        LocalDate leaveDt,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {}
