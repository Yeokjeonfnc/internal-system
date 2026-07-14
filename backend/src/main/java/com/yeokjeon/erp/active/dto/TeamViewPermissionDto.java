package com.yeokjeon.erp.active.dto;

public record TeamViewPermissionDto(
        Integer targetDeptIdx,
        String targetDeptNm,
        boolean canView) {}
