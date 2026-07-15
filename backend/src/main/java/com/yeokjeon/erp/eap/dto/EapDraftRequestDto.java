package com.yeokjeon.erp.eap.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record EapDraftRequestDto(
        @NotBlank @Size(max = 64) String formCode,
        @Size(max = 32) String erpMenuId,
        @Size(max = 64) String erpSourceId,
        @NotBlank @Size(max = 500) String title,
        @Size(max = 64) String draftUserId,
        String contentHtml) {
}
