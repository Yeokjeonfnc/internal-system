package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * 발송 요청에 실어 보내는 첨부 한 건.
 *
 * <p>{@code content} 는 Base64 문자열이다. 요청 본문 전체가 메모리에 올라가므로
 * 첨부 용량 상한(resend.attachment-max-bytes)을 반드시 발송 전에 확인할 것 —
 * base64 는 원본보다 약 1.33배로 부풀어 상한을 그대로 믿으면 안 된다.
 *
 * <p>{@code contentId} 가 있으면 본문 html 의 {@code cid:} 참조와 연결돼 인라인
 * 이미지로 표시된다. 없으면 일반 첨부다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResendSendAttachmentDto(
        String filename,
        String content,
        @JsonProperty("content_type") String contentType,
        @JsonProperty("content_id") String contentId) {
}
