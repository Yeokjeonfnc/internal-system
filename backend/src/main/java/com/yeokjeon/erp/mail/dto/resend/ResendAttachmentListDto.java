package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Attachments 목록 API 응답 봉투.
 *
 * <p>{@code hasMore} 가 true 여도 우리는 다음 페이지를 따라가지 않는다. 한 메일에
 * 첨부 100개를 넘는 경우가 실무에 없고, 페이지네이션을 돌면 Resend rate limit
 * (팀 단위 10 req/s)을 첨부 하나 때문에 갉아먹기 때문이다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendAttachmentListDto(
        String object,
        @JsonProperty("has_more") Boolean hasMore,
        List<ResendAttachmentMetaDto> data) {
}
