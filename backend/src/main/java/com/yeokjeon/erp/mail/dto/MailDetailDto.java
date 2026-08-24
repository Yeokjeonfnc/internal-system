package com.yeokjeon.erp.mail.dto;

import java.util.List;

/**
 * 메일 상세. 목록 한 줄({@code summary}) 위에 본문·참여자·첨부·이벤트를 얹은 형태다.
 *
 * <p>목록 필드를 펼쳐 담지 않고 {@code MailListItemDto} 를 그대로 품은 이유:
 * 상세를 읽고 목록으로 돌아갈 때 화면이 같은 객체를 재사용할 수 있고, 목록 필드가
 * 늘어나도 두 DTO 가 어긋나지 않는다.
 *
 * <p>리스트에는 절대 null 을 넣지 않는다. 본문 수집이 아직 안 끝난 수신 메일은
 * 첨부·이벤트가 비어 있는 것이 정상 상태라, null 로 내보내면 화면이 "오류"와
 * "아직 안 왔음"을 구분하지 못한다.
 */
public record MailDetailDto(
        MailListItemDto summary,
        String bodyText,
        String bodyHtml,
        boolean truncated,
        String headersRaw,
        String rfcMessageId,
        String inReplyTo,
        String bodyErr,
        String sendErr,
        List<MailAddressDto> addresses,
        List<MailAttachmentDto> attachments,
        List<MailEventDto> events) {

    public static MailDetailDto of(
            MailMstJdbcRow mst,
            MailBodyJdbcRow body,
            List<MailAddrDtlJdbcRow> addrs,
            List<MailAttJdbcRow> atts,
            List<MailEventLogJdbcRow> events) {
        return new MailDetailDto(
                MailListItemDto.fromRow(mst),
                body == null || body.bodyText() == null ? "" : body.bodyText(),
                body == null || body.bodyHtml() == null ? "" : body.bodyHtml(),
                body != null && Boolean.TRUE.equals(body.truncatedYn()),
                body == null || body.headersRaw() == null ? "" : body.headersRaw(),
                mst.rfcMessageId() == null ? "" : mst.rfcMessageId(),
                mst.inReplyTo() == null ? "" : mst.inReplyTo(),
                mst.bodyErr() == null ? "" : mst.bodyErr(),
                mst.sendErr() == null ? "" : mst.sendErr(),
                addrs == null ? List.of() : addrs.stream().map(MailAddressDto::fromRow).toList(),
                atts == null ? List.of() : atts.stream().map(MailAttachmentDto::fromRow).toList(),
                events == null ? List.of() : events.stream().map(MailEventDto::fromRow).toList());
    }
}
