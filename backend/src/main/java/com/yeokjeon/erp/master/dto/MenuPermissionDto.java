package com.yeokjeon.erp.master.dto;

/**
 * 로그인·권한 조회용 메뉴 권한 한 건.
 */
public record MenuPermissionDto(
        String menuCd,
        String menuNm,
        String parentMenuCd,
        String routePath,
        String menuType,
        Integer sortOrder,
        boolean canView,
        boolean canCreate,
        boolean canUpdate,
        boolean canDelete) {}
