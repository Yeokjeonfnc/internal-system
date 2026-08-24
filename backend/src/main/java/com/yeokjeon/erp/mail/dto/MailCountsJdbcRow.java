package com.yeokjeon.erp.mail.dto;

/**
 * 메일함별 건수 집계 한 행.
 *
 * <p>폴더마다 count 쿼리를 던지면 왕복이 폴더 수만큼 늘어난다. mail_mst 를 한 번만 훑고
 * {@code COUNT(*) FILTER (WHERE ...)} 로 갈라 담는 편이 훨씬 싸서 전용 행을 뒀다.
 * 무엇보다 쿼리를 나눠 던지면 그 사이에 메일이 들어와 "받은메일함 10 / 전체 9" 처럼
 * 합계가 서로 안 맞는 순간이 생긴다.
 *
 * <p>필드 순서는 XML {@code mailCountsRow} resultMap 의 {@code <arg>} 순서와 반드시
 * 같아야 한다. 전부 Integer 라 한 칸 어긋나도 컴파일·실행이 되고 숫자만 뒤바뀐다.
 *
 * <p>각 함의 <b>전체</b>와 <b>안읽음</b>을 함께 담는다. 사이드바 뱃지가 다우오피스처럼
 * "받은메일함 (3)" 형태로 안읽음을 보여 주는데, 목록 헤더는 전체 건수를 쓰기 때문이다.
 */
public record MailCountsJdbcRow(
        Integer inbox,
        Integer inboxUnread,
        Integer sent,
        Integer draft,
        Integer scheduled,
        Integer failed,
        Integer spam,
        Integer spamUnread,
        Integer trash,
        Integer star,
        Integer starUnread,
        Integer all,
        Integer allUnread) {
}
