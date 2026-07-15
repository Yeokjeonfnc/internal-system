package com.yeokjeon.erp.eap.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record EapFormConfigSaveRequestDto(
        @NotBlank @Size(max = 64) String formCode,
        @NotBlank @Size(max = 200) String formName,
        @Size(max = 16) String integrationType,
        @Size(max = 32) String erpSourceMenu,
        @Size(max = 64) String htmlTemplateKey,
        Boolean useEmail,
        Boolean useBoard,
        Boolean enabled,
        Integer sortOrder) {
}
