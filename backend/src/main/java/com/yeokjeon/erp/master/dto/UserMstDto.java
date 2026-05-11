package com.yeokjeon.erp.master.dto;

import java.time.Instant;
import java.time.LocalDate;

/**
 * {@code user_mst} 조회·저장 응답(부서·직급명 JOIN 포함) — 기존 {@code Map} 키와 동일.
 */
public record UserMstDto(
        Integer userIdx,
        String userName,
        String userId,
        Integer deptIdx,
        String deptNm,
        String userPhone,
        String userEmail,
        Character svYn,
        String positionCd,
        String positionNm,
        Character tagYn,
        LocalDate joinDt,
        Instant createdAt,
        Instant updatedAt) {

    public static UserMstDto fromJdbcRow(MstUserListJdbcRow r) {
        return new UserMstDto(
                r.userIdx(),
                r.userName(),
                r.userId(),
                r.deptIdx(),
                r.deptNm(),
                r.userPhone(),
                r.userEmail(),
                firstChar(r.svYn()),
                r.positionCd(),
                r.positionNm(),
                firstChar(r.tagYn()),
                r.joinDt(),
                r.createdAt() != null ? r.createdAt().toInstant() : null,
                r.updatedAt() != null ? r.updatedAt().toInstant() : null);
    }

    private static Character firstChar(String s) {
        if (s == null || s.isEmpty()) {
            return null;
        }
        return s.charAt(0);
    }
}
