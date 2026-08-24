package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * mail_signature INSERT 파라미터.
 *
 * <p>{@link MailMstInsertParam} 과 같은 이유로 가변 클래스다 — useGeneratedKeys 가
 * 생성된 PK 를 여기에 되써 넣는다.
 */
@Getter
@Setter
public class MailSignatureInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키 */
    private Long mailSignIdx;

    private String userId;
    private String signNm;
    private String signHtml;
    private String defaultNewYn;
    private String defaultReplyYn;
    private Integer sortOrder;
}
