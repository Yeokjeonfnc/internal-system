package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

/**
 * mail_thread_mst INSERT 파라미터.
 *
 * <p>{@code MailMstInsertParam} 과 같은 이유로 record 가 아니다 — 생성된 thread_idx 를
 * 되받아 곧바로 mail_mst.thread_idx 에 써야 한다.
 */
@Getter
@Setter
public class MailThreadInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키 */
    private Long threadIdx;

    private String subjectNorm;
    private OffsetDateTime firstMailAt;
    private OffsetDateTime lastMailAt;
}
