package com.yeokjeon.erp.mail.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * mail_rule INSERT 파라미터.
 *
 * <p>{@link MailFolderInsertParam} 과 같은 이유로 record 가 아니라 가변 클래스다.
 * MyBatis 의 {@code useGeneratedKeys="true" keyProperty="mailRuleIdx"} 가 INSERT 직후
 * 생성된 PK 를 이 객체에 되써 넣어야 하는데, record 는 setter 가 없어 값을 받을 수 없다.
 */
@Getter
@Setter
public class MailRuleInsertParam {

    /** INSERT 후 MyBatis 가 채워 주는 생성키 */
    private Long mailRuleIdx;

    private String userId;
    private String ruleNm;
    private Integer sortOrder;
    private String useYn;
    private String fromOp;
    private String fromVal;
    private String toOp;
    private String toVal;
    private String subjOp;
    private String subjVal;
    private String actionType;
    private Long actionFolderIdx;
}
