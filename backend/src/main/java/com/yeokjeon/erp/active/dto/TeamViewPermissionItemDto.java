package com.yeokjeon.erp.active.dto;

import jakarta.validation.constraints.NotNull;

public record TeamViewPermissionItemDto(
        @NotNull Integer targetDeptIdx,
        boolean canView) {}
