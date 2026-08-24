package com.yeokjeon.erp.mail.dto.resend;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.OffsetDateTime;

/**
 * 첨부 메타 한 건. 웹훅 페이로드와 Received Emails / Attachments API 응답에서
 * 같은 모양으로 쓰인다.
 *
 * <p>{@code size} 는 웹훅에는 아예 없어서 null 로 들어온다. 그래서 mail_att 에는
 * 일단 0 으로 INSERT 하고, 나중에 본문·첨부 API 응답의 size 로 갱신한다.
 *
 * <p>{@code downloadUrl} 은 서명된 임시 URL 이고 1시간 뒤 만료된다. 절대 DB 에
 * 저장하지 말 것 — 저장해 두면 만료된 URL 로 다운로드를 시도하다 조용히 실패한다.
 * 필요할 때마다 {@code getAttachment} 로 새로 받는다.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record ResendAttachmentMetaDto(
        String id,
        String filename,
        @JsonProperty("content_type") String contentType,
        @JsonProperty("content_disposition") String contentDisposition,
        @JsonProperty("content_id") String contentId,
        Long size,
        @JsonProperty("download_url") String downloadUrl,
        @JsonProperty("expires_at") OffsetDateTime expiresAt) {
}
