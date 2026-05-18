package com.yeokjeon.erp.master.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

/**
 * 사용자 메뉴 권한 일괄 저장.
 */
public record UserMenuPermissionSaveRequestDto(
        @NotNull @Valid List<Item> items) {

    public record Item(
            @NotBlank String menuCd,
            boolean canView,
            boolean canCreate,
            boolean canUpdate,
            boolean canDelete) {}
}
