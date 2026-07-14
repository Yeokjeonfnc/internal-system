package com.yeokjeon.erp.auth.dto;

import com.yeokjeon.erp.master.dto.MenuPermissionDto;

import java.time.LocalDate;
import java.util.List;

/**
 * 로그인·프로필 조회/수정 응답 — 기존 {@code Map} 키와 동일(프론트 {@code AuthProvider} 호환).
 */
public record AuthProfileDto(
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
        LocalDate joinDt,
        List<MenuPermissionDto> menuPermissions) {

    public AuthProfileDto {
        if (menuPermissions == null) {
            menuPermissions = List.of();
        }
    }

    public static AuthProfileDto fromRow(
            AuthProfileRowDto row, List<MenuPermissionDto> menuPermissions) {
        return new AuthProfileDto(
                row.userIdx(),
                row.userId(),
                row.userNm(),
                row.email(),
                row.deptIdx(),
                row.userPhone(),
                row.deptNm(),
                row.positionCd(),
                row.positionNm(),
                row.svYn(),
                row.ownerYn(),
                row.adminYn(),
                row.storeIdx(),
                row.storeNm(),
                row.joinDt(),
                menuPermissions);
    }

    /** 슈퍼 관리자 판정 결과를 반영한 사본(컬럼 미적용 시 config 폴백 포함). */
    public AuthProfileDto withAdminYn(String adminYn) {
        return new AuthProfileDto(
                userIdx, userId, userNm, email, deptIdx, userPhone, deptNm,
                positionCd, positionNm, svYn, ownerYn, adminYn,
                storeIdx, storeNm, joinDt, menuPermissions);
    }
}
