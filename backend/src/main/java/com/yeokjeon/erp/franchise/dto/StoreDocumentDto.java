package com.yeokjeon.erp.franchise.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** 가맹점 문서 목록·업로드 응답 — Flutter {@code Document} 모델과 동일 키. */
public record StoreDocumentDto(
        Integer storeDocIdx,
        Integer storeIdx,
        String fileName,
        String modifiedAt,
        String modifiedBy,
        boolean attached,
        String attachmentBaseDate,
        String attachedAt) {

    public static StoreDocumentDto fromRow(
            StoreDocumentJdbcRow row, boolean fileExists) {
        return new StoreDocumentDto(
                row.storeDocIdx(),
                row.storeIdx(),
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
