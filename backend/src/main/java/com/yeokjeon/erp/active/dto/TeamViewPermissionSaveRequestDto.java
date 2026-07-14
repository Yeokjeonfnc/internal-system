package com.yeokjeon.erp.active.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record TeamViewPermissionSaveRequestDto(
        @NotNull @Valid List<TeamViewPermissionItemDto> items) {}
