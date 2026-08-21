package com.yeokjeon.erp.eap.dto;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;

public record EapDocumentDto(
        Long mappingId,
        String docId,
        String docNum,
        OffsetDateTime draftDate,
        OffsetDateTime updatedAt,
        String formName,
        String formCode,
        String formCategory,
        String title,
        String status,
        String draftUserId,
        String drafterName,
        String drafterDept,
        String contentHtml,
        String erpMenuId,
        String erpSourceId,
        List<EapDocLineDto> lines,
        boolean canApprove) {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    public static EapDocumentDto fromRow(EapApprovalMappingJdbcRow row) {
        return fromRow(row, row.contentHtml(), List.of(), false);
    }

    public static EapDocumentDto fromRow(EapApprovalMappingJdbcRow row, String contentHtml) {
        return fromRow(row, contentHtml, List.of(), false);
    }

    public static EapDocumentDto fromRow(
            EapApprovalMappingJdbcRow row,
            String contentHtml,
            List<EapDocLineDto> lines,
            boolean canApprove) {
        String docId = row.daouDocumentId() != null && !row.daouDocumentId().isBlank()
                ? row.daouDocumentId()
                : "MAP-" + row.id();
        String docNum = row.daouDocumentId() != null && !row.daouDocumentId().isBlank()
                ? row.daouDocumentId()
                : "ERP-" + row.id();
        String html = contentHtml != null && !contentHtml.isBlank()
                ? contentHtml
                : (row.contentHtml() == null ? "" : row.contentHtml());
        String drafterName = row.drafterName() != null && !row.drafterName().isBlank()
                ? row.drafterName()
                : (row.draftUserId() == null ? "" : row.draftUserId());
        String drafterDept = row.drafterDept() == null ? "" : row.drafterDept().trim();
        return new EapDocumentDto(
                row.id(),
                docId,
                docNum,
                toSeoul(row.createdAt()),
                toSeoul(row.updatedAt()),
                row.formName() == null ? "" : row.formName(),
                row.daouFormCode() == null ? "" : row.daouFormCode(),
                row.formCategory() == null || row.formCategory().isBlank()
                        ? "기타문서"
                        : row.formCategory(),
                row.title() == null ? "" : row.title(),
                row.status(),
                row.draftUserId() == null ? "" : row.draftUserId(),
                drafterName,
                drafterDept,
                html,
                row.erpMenuId(),
                row.erpSourceId(),
                lines == null ? List.of() : lines,
                canApprove);
    }

    static OffsetDateTime toSeoul(OffsetDateTime value) {
        if (value == null) {
            return null;
        }
        return value.atZoneSameInstant(SEOUL).toOffsetDateTime();
    }
}
