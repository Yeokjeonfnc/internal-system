package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_body 한 행. 본문은 목록 조회에서 읽지 않으므로 mail_mst 와 분리돼 있다.
 *
 * <p>{@code headersRaw} 는 DB 상 jsonb 지만 자바에서는 String 으로 받는다.
 * 우리는 헤더 맵을 구조적으로 질의하지 않고 "원문 그대로 보존"만 하면 되기 때문에
 * jsonb → 객체 역직렬화 비용을 치를 이유가 없다. INSERT 할 때는 XML 에서
 * {@code CAST(#{headersRaw} AS jsonb)} 로 되돌린다.
 */
public record MailBodyJdbcRow(
        Long mailIdx,
        String bodyText,
        String bodyHtml,
        String headersRaw,
        String searchTxt,
        Boolean truncatedYn,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
