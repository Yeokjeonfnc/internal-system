package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

/**
 * Received Emails API(GET /emails/receiving/{id}) 응답 — 웹훅이 주지 않는 본문·헤더가
 * 여기 있다.
 *
 * <p>반드시 {@code ?html_format=cid} 로 호출해야 한다. 기본값인 data_uri 로 받으면
 * 인라인 이미지가 base64 로 html 안에 통째로 박혀서 body_html 이 수 MB 로 부풀고,
 * mail_att.content_id / inline_yn 로 첨부를 따로 관리하는 설계 자체가 무의미해진다.
 *
 * <p>{@code text} 는 발신자가 평문 파트를 안 보냈으면 null 이다. 그때는 html 을
 * MailHtmlToText 로 1회 변환해 body_text 에 채운다 — 검색·미리보기가 평문에
 * 의존하므로 비워 둘 수 없다.
 *
 * <p>{@code headers} 는 키가 소문자로 정규화돼 온다. raw.download_url 은 우리가
 * 원본 MIME 을 다루지 않으므로 매핑하지 않는다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendReceivedEmailDto(
        String object,
        String id,
        String from,
        List<String> to,
        List<String> cc,
        List<String> bcc,
        @JsonProperty("reply_to") List<String> replyTo,
        @JsonProperty("received_for") List<String> receivedFor,
        @JsonProperty("message_id") String messageId,
        String subject,
        String html,
        @JsonProperty("html_format") String htmlFormat,
        String text,
        Map<String, Object> headers,
        @JsonProperty("created_at") OffsetDateTime createdAt,
        List<ResendAttachmentMetaDto> attachments) {
}
