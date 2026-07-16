package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;

public record EapDocumentDto(
        Long mappingId,
        String docId,
        String docNum,
        OffsetDateTime draftDate,
        OffsetDateTime updatedAt,
        String formName,
        String formCode,
        String title,
        String status,
        String drafterName,
        String contentHtml,
        String erpMenuId,
        String erpSourceId) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

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
                row.id(),
                docId,
                docNum,
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()),
                row.formName() == null ? "" : row.formName(),
                row.daouFormCode(),
                row.title() == null ? "" : row.title(),
                row.status(),
                row.draftUserId() == null ? "" : row.draftUserId(),
                html,
                row.erpMenuId(),
                row.erpSourceId());
    }

    static OffsetDateTime toSeoul(OffsetDateTime value) {
        if (value == null) {
            return null;
        }
        return value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
