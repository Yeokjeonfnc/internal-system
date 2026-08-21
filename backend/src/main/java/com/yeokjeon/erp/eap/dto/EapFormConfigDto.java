package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapFormConfigDto(
        String formCode,
        String formName,
        boolean enabled,
        int sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        String category,
        String contentHtml,
        String fieldSchema,
        String createdBy,
        String createdByNm) {

    public static EapFormConfigDto fromRow(EapFormConfigJdbcRow row) {
        return new EapFormConfigDto(
                row.formCode(),
                row.formName(),
                !Boolean.FALSE.equals(row.enabled()),
                row.sortOrder() == null ? 0 : row.sortOrder(),
                row.createdAt(),
                row.updatedAt(),
                row.category() == null || row.category().isBlank() ? "기타문서" : row.category(),
                row.contentHtml() == null ? "" : row.contentHtml(),
                row.fieldSchema() == null ? "" : row.fieldSchema(),
                row.createdBy() == null ? "" : row.createdBy(),
                row.createdByNm() == null ? "" : row.createdByNm());
    }
}
