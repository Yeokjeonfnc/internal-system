package com.yeokjeon.erp.eap.dto;

public record EapDraftResultDto(
        Long mappingId,
        String daouDocumentId,
        String formCode,
        String status,
        String title,
        boolean daouSubmitted,
        String message,
        /** 다우 기안 성공(302) 시 Redirect Location — 브라우저에서 열어야 함 */
        String redirectUrl) {
}
