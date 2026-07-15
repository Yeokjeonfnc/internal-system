package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapFormConfigDto(
        String formCode,
        String formName,
        String integrationType,
        String erpSourceMenu,
        String htmlTemplateKey,
        boolean useEmail,
        boolean useBoard,
        boolean enabled,
        int sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {

    public static EapFormConfigDto fromRow(EapFormConfigJdbcRow row) {
        return new EapFormConfigDto(
                row.formCode(),
                row.formName(),
                row.integrationType(),
                row.erpSourceMenu(),
                row.htmlTemplateKey(),
                Boolean.TRUE.equals(row.useEmail()),
                Boolean.TRUE.equals(row.useBoard()),
                !Boolean.FALSE.equals(row.enabled()),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                row.createdAt(),
                row.updatedAt());
    }
}
