package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;

public record EapDocumentDto(
        String docId,
        String docNum,
        OffsetDateTime draftDate,
        String formName,
        String formCode,
        String title,
        String status,
        String drafterName,
        String contentHtml,
        String erpMenuId,
        String erpSourceId) {

    public static EapDocumentDto fromRow(EapApprovalMappingJdbcRow row) {
        return fromRow(row, row.contentHtml());
    }

    public static EapDocumentDto fromRow(EapApprovalMappingJdbcRow row, String contentHtml) {
        String docId = row.daouDocumentId() != null && !row.daouDocumentId().isBlank()
                ? row.daouDocumentId()
                : "MAP-" + row.id();
        String docNum = row.daouDocumentId() != null && !row.daouDocumentId().isBlank()
                ? row.daouDocumentId()
                : "ERP-" + row.id();
        String html = contentHtml != null && !contentHtml.isBlank()
                ? contentHtml
                : (row.contentHtml() == null ? "" : row.contentHtml());
        return new EapDocumentDto(
                docId,
                docNum,
                row.createdAt(),
                row.formName() == null ? "" : row.formName(),
                row.daouFormCode(),
                row.title() == null ? "" : row.title(),
                row.status(),
                row.draftUserId() == null ? "" : row.draftUserId(),
                html,
                row.erpMenuId(),
                row.erpSourceId());
    }
}
