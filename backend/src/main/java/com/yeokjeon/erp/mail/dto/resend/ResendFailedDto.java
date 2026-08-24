package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * email.failed 상세. 사유 문자열 하나뿐이지만 mail_mst.send_err 에 그대로 실려
 * 화면에 노출되므로, 값이 길어도 자르지 않고 받아서 저장 단계에서 절단한다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendFailedDto(String reason) {
}
