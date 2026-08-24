package com.yeokjeon.erp.mail.dto;

import java.time.OffsetDateTime;

/**
 * mail_rule 한 행(자동분류 규칙).
 *
 * <p>필드 순서를 XML resultMap 의 {@code <arg>} 순서 = 테이블 컬럼 순서와 똑같이 맞춰 둘 것.
 * {@link MailMstJdbcRow} 와 같은 이유로 한 칸만 어긋나도 컴파일은 통과하고 런타임에
 * 값만 뒤섞인다.
 *
 * <p>조건 세 쌍({@code *Op}/{@code *Val})은 <b>같이 있거나 같이 없다</b>. 둘 다 null 이면
 * "이 조건은 무시" 라는 뜻이고, 세 조건은 AND 로 묶인다(다우오피스에 OR 이 없다).
 */
public record MailRuleJdbcRow(
        Long mailRuleIdx,
        String userId,
        String ruleNm,
        Integer sortOrder,
        String useYn,
        String fromOp,
        String fromVal,
        String toOp,
        String toVal,
        String subjOp,
        String subjVal,
        /** MOVE=메일함 이동 / READ=읽음처리. 규칙당 하나만 고른다. */
        String actionType,
        /** MOVE 일 때의 대상 메일함. READ 면 NULL 이다(DB CHECK 로 강제). */
        Long actionFolderIdx,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
