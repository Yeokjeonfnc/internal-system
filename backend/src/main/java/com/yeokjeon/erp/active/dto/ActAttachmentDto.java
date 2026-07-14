package com.yeokjeon.erp.active.dto;

import java.time.LocalDateTime;

/** 활동 첨부 목록·업로드 응답 — Flutter {@code ActAttachment} 모델과 동일 키. */
public record ActAttachmentDto(
        Integer actAttIdx,
        Integer actIdx,
        String fileName,
        String modifiedAt,
        String modifiedBy,
        boolean attached,
        String attachedAt) {

    public static ActAttachmentDto fromRow(ActAttachmentJdbcRow row, boolean fileExists) {
        return new ActAttachmentDto(
                row.actAttIdx(),
                row.actIdx(),
                row.fileName(),
                formatDateTime(row.modifiedAt()),
                displayName(row.modifiedBy(), row.modifiedByNm()),
                !row.deletedYn() && fileExists,
                formatDateTime(row.attachedAt()));
    }

    private static String displayName(String userId, String userName) {
        if (userName != null && !userName.isBlank()) {
            return userName.trim();
        }
        return userId != null ? userId : "";
    }

    private static String formatDateTime(LocalDateTime dateTime) {
        return dateTime != null ? dateTime.toLocalDate().toString() : "";
    }
}
