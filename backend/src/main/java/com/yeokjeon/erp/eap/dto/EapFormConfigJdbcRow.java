package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapFormConfigJdbcRow(
        String formCode,
        String formName,
        String integrationType,
        String erpSourceMenu,
        String htmlTemplateKey,
        Boolean useEmail,
        Boolean useBoard,
        Boolean enabled,
        Integer sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
