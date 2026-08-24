package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * mail_forward_rule INSERT 파라미터.
 *
 * <p>{@link MailFolderInsertParam} 과 같은 이유로 record 가 아니다 — MyBatis 가
 * {@code useGeneratedKeys} 로 생성된 PK 를 되써 넣어야 하는데 record 에는 setter 가 없다.
 */
@Getter
@Setter
public class MailForwardRuleInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키 */
    private Long mailFwdRuleIdx;

    private String userId;
    private String matchType;
    private String matchVal;
    private String forwardEmail;
    private String useYn;
    private Integer sortOrder;
}
