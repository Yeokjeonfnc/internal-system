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
        String tagYn,
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
                row.tagYn(),
                row.joinDt(),
                menuPermissions);
    }
}
