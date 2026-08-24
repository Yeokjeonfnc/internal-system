package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

/**
 * POST /emails 요청 본문.
 *
 * <p>{@code @JsonInclude(NON_NULL)} 이 필수다. cc/bcc/attachments 를 null 인 채로
 * 직렬화해 보내면 Resend 가 필드 형식 오류로 400 을 돌려준다 — 안 쓰는 필드는
 * 아예 빼야 한다.
 *
 * <p>{@code headers} 는 답장에서 In-Reply-To / References 를 심는 통로다. 이걸 넣어야
 * 상대방 메일 클라이언트가 대화로 묶어 준다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResendSendRequestDto(
        String from,
        List<String> to,
        List<String> cc,
        List<String> bcc,
        @JsonProperty("reply_to") List<String> replyTo,
        String subject,
        String html,
        String text,
        Map<String, String> headers,
        List<ResendSendAttachmentDto> attachments,
        /**
         * 예약발송 시각(ISO-8601, 예 {@code 2026-08-25T09:00:00+09:00}).
         *
         * <p>Resend 는 최대 30일 뒤까지 예약을 받는다. null 이면 즉시 발송이므로
         * NON_NULL 직렬화가 필드를 통째로 빼 준다 — 빈 문자열을 보내면 400 이 난다.
         *
         * <p>예약된 메일은 <b>시각만</b> 바꿀 수 있고(PATCH /emails/{id}) 본문·수신자는
         * 고칠 수 없다. 내용을 바꾸려면 취소(POST /emails/{id}/cancel) 후 다시 작성해야 한다.
         */
        @JsonProperty("scheduled_at") String scheduledAt) {
}
