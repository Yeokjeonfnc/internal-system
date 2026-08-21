package com.yeokjeon.erp.master.dto;

import com.yeokjeon.erp.master.entity.MstUser;

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
        Character ownerYn,
        LocalDate joinDt,
        Character workYn,
        LocalDate leaveDt,
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
                firstChar(r.ownerYn()),
                r.joinDt(),
                firstChar(r.workYn()),
                r.leaveDt(),
                r.createdAt() != null ? r.createdAt().toInstant() : null,
                r.updatedAt() != null ? r.updatedAt().toInstant() : null);
    }

    /** JOIN 조회 실패 시 저장 직후 응답용(직급·부서명 없음). */
    public static UserMstDto fromEntity(MstUser u) {
        return new UserMstDto(
                u.getUserIdx(),
                u.getUserName(),
                u.getUserId(),
                u.getDeptIdx(),
                null,
                u.getUserPhone(),
                u.getUserEmail(),
                u.getSvYn(),
                u.getPositionCd(),
                null,
                u.getOwnerYn(),
                u.getJoinDt(),
                u.getWorkYn(),
                u.getLeaveDt(),
                u.getCreatedAt() != null ? u.getCreatedAt().toInstant() : null,
                u.getUpdatedAt() != null ? u.getUpdatedAt().toInstant() : null);
    }

    private static Character firstChar(String s) {
        if (s == null || s.isEmpty()) {
            return null;
        }
        return s.charAt(0);
    }
}
