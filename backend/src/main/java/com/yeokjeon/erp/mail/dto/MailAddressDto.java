package com.yeokjeon.erp.mail.dto;

/**
 * 메일 참여자 한 명(FROM/TO/CC/BCC/REPLY_TO).
 *
 * <p>BCC 는 발신 메일에만 존재한다. 수신자에게는 보이면 안 되는 정보이므로,
 * 이 DTO 를 그대로 상세 응답에 실을 때 화면단에서 노출 범위를 제한해야 한다.
 */
public record MailAddressDto(
        String addrType,
        int seq,
        String email,
        String dispNm) {

    public static MailAddressDto fromRow(MailAddrDtlJdbcRow row) {
        return new MailAddressDto(
                row.addrType() == null ? "" : row.addrType(),
                row.seq() == null ? 0 : row.seq(),
                row.email() == null ? "" : row.email(),
                row.dispNm() == null ? "" : row.dispNm());
    }
}
