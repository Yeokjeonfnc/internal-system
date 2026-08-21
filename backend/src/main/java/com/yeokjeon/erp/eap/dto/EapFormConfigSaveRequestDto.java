package com.yeokjeon.erp.eap.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record EapFormConfigSaveRequestDto(
        @NotBlank @Size(max = 200) String formName,
        Boolean enabled,
        Integer sortOrder,
        @Size(max = 64) String category,
        String contentHtml,
        String fieldSchema,
        @Size(max = 64) String createdBy,
        @Size(max = 100) String createdByNm) {
}
