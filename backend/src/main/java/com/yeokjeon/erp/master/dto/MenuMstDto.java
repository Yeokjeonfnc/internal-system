package com.yeokjeon.erp.master.dto;

/**
 * 메뉴 마스터 한 건.
 */
public record MenuMstDto(
        String menuCd,
        String menuNm,
        String parentMenuCd,
        String routePath,
        String menuType,
        Integer sortOrder,
        String useYn) {}
