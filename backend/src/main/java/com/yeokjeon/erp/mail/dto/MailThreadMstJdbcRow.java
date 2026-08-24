package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_thread_mst 한 행(대화 묶음).
 *
 * <p>{@code mailCnt}/{@code firstMailAt}/{@code lastMailAt} 는 mail_mst 에서 파생되는
 * 캐시값이다. 스레드 목록을 뽑을 때마다 집계하면 메일이 쌓일수록 느려지므로
 * 메일이 붙을 때 {@code touch} 로 다시 계산해 둔다.
 */
public record MailThreadMstJdbcRow(
        Long threadIdx,
        String subjectNorm,
        OffsetDateTime firstMailAt,
        OffsetDateTime lastMailAt,
        Integer mailCnt,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
