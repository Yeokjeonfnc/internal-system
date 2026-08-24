package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_signature 한 행.
 *
 * <p>필드 순서 = XML resultMap {@code <arg>} 순서 = 테이블 컬럼 순서.
 * 셋 중 하나만 틀어져도 런타임에 값이 뒤섞인다.
 */
public record MailSignatureJdbcRow(
        Long mailSignIdx,
        String userId,
        String signNm,
        String signHtml,
        String defaultNewYn,
        String defaultReplyYn,
        Integer sortOrder,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
