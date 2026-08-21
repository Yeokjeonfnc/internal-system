package com.yeokjeon.erp.eap.dto;

public record EapDraftResultDto(
        Long mappingId,
        String documentId,
        String formCode,
        String status,
        String title,
        String message) {
}
