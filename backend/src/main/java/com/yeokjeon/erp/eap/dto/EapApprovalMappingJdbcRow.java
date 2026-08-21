package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapApprovalMappingJdbcRow(
        Long id,
        String erpMenuId,
        String erpSourceId,
        String daouDocumentId,
        String daouFormCode,
        String formName,
        String status,
        String draftUserId,
        String title,
        String contentHtml,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        String formCategory,
        String drafterName,
        String drafterDept) {
}
