package com.yeokjeon.erp.development.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** 물건 문서 목록·업로드 응답 — Flutter {@code PropertyDocument} 모델과 동일 키. */
public record PropertyDocumentDto(
        Integer propertyDocIdx,
        Integer propIdx,
        String fileName,
        String modifiedAt,
        String modifiedBy,
        boolean attached,
        String attachmentBaseDate,
        String attachedAt) {

    public static PropertyDocumentDto fromRow(
            PropertyDocumentJdbcRow row, boolean fileExists) {
        return new PropertyDocumentDto(
                row.propertyDocIdx(),
                row.propIdx(),
                row.fileName(),
                formatDateTime(row.modifiedAt()),
                displayName(row.modifiedBy(), row.modifiedByNm()),
                !row.deletedYn() && fileExists,
                formatDate(row.attachmentBaseDate()),
                formatDateTime(row.attachedAt()));
    }

    private static String displayName(String userId, String userName) {
        if (userName != null && !userName.isBlank()) {
            return userName.trim();
        }
        return userId != null ? userId : "";
    }

    private static String formatDate(LocalDate date) {
        return date != null ? date.toString() : "";
    }

    private static String formatDateTime(LocalDateTime dateTime) {
        return dateTime != null ? dateTime.toLocalDate().toString() : "";
    }
}
