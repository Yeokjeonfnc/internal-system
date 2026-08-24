package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 웹훅 페이로드의 data 블록.
 *
 * <p>중요 — 여기에는 <b>본문도 헤더도 첨부 실체도 없다</b>. Resend 는 수신 메일 웹훅에
 * 메타데이터만 싣는다고 공식 문서에 못 박아 두었다. 본문은 Received Emails API,
 * 첨부는 Attachments API 를 따로 호출해 채워야 한다. 그래서 이 DTO 만으로는 메일이
 * 완성되지 않고 body_status='PENDING' 상태의 껍데기가 먼저 저장된다.
 *
 * <p>{@code from} 의 형태가 방향에 따라 다르다. 수신 이벤트는 순수 주소,
 * 발송계 이벤트는 {@code Name <a@b>} 형식으로 온다. 파싱은 MailAddressParser 가 한다.
 *
 * <p>{@code tags} 는 이벤트 종류에 따라 object 였다가 array 였다가 해서 자바 타입 하나로
 * 고정할 수 없다. 매핑하지 않고 detail jsonb 에 원문으로 보존한다 — 타입을 고정했다가는
 * 형태가 다른 이벤트 하나 때문에 웹훅 파싱 전체가 죽는다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendWebhookDataDto(
        @JsonProperty("email_id") String emailId,
        @JsonProperty("created_at") OffsetDateTime createdAt,
        @JsonProperty("message_id") String messageId,
        String from,
        List<String> to,
        List<String> cc,
        List<String> bcc,
        @JsonProperty("received_for") List<String> receivedFor,
        String subject,
        @JsonProperty("broadcast_id") String broadcastId,
        @JsonProperty("template_id") String templateId,
        List<ResendAttachmentMetaDto> attachments,
        ResendBounceDto bounce,
        ResendClickDto click,
        ResendFailedDto failed) {
}
