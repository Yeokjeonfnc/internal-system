package com.yeokjeon.erp.mail.dto;

/**
 * mail_addr_dtl 한 행(메일 참여자).
 *
 * <p>조회 결과이면서 동시에 {@code MailAddrMapper.insertBatch} 의 입력으로도 쓴다.
 * 참여자는 한 번 저장되면 바뀌지 않아서 INSERT 전용 파라미터 클래스를 따로 둘
 * 이유가 없었다(첨부·메일 본체와 달리 생성키를 되받을 필요도 없다).
 */
public record MailAddrDtlJdbcRow(
        Long mailIdx,
        String addrType,
        Integer seq,
        String email,
        String dispNm) {
}
