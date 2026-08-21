package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapFormConfigJdbcRow(
        String formCode,
        String formName,
        Boolean enabled,
        Integer sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        String category,
        String contentHtml,
        String fieldSchema,
        String createdBy,
        String createdByNm) {
}
