package com.yeokjeon.erp.master.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UserPageFilterSaveRequestDto(
        @NotBlank @Size(max = 50) String pageCode,
        @NotBlank @Size(max = 20000) String filterJson) {
}
