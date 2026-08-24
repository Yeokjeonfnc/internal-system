package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * POST /emails 성공 응답. id 하나만 온다.
 *
 * <p>이 id 가 mail_mst.resend_email_id 가 되고, 이후 발송계 웹훅(delivered/bounced 등)을
 * 우리 메일 행에 붙이는 유일한 열쇠다. 저장에 실패하면 상태 이벤트가 전부 고아가 된다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendSendResponseDto(String id) {
}
