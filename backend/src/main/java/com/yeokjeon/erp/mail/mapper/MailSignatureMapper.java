package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailSignatureInsertParam;
import com.yeokjeon.erp.mail.dto.MailSignatureJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 개인 서명(mail_signature) 매퍼 (mal001-D).
 *
 * <p>{@link MailFolderMapper} 와 같은 규칙 — 모든 메서드가 {@code userId} 를 받아
 * 남의 서명을 idx 만 바꿔 건드릴 수 없게 한다.
 */
@Mapper
public interface MailSignatureMapper {

    List<MailSignatureJdbcRow> selectByUserId(@Param("userId") String userId);

    MailSignatureJdbcRow selectByIdx(@Param("signIdx") Long signIdx,
                                     @Param("userId") String userId);

    int insert(MailSignatureInsertParam param);

    /**
     * 부분 수정. null 인 항목은 기존 값을 유지한다.
     *
     * <p>{@code defaultNewYn}/{@code defaultReplyYn} 은 여기서 올리기만 한다.
     * "사용자당 하나만 Y" 규칙은 {@link #clearDefaultNew}/{@link #clearDefaultReply} 를
     * 먼저 부르는 서비스가 보장한다 — SQL 한 문장으로 묶으려면 다른 행을 갱신하는
     * 서브쿼리가 필요한데, 그러면 이 update 가 "내 서명 하나만 바꾼다"는 단순한
     * 계약을 잃는다.
     */
    int update(@Param("signIdx") Long signIdx,
               @Param("userId") String userId,
               @Param("signNm") String signNm,
               @Param("signHtml") String signHtml,
               @Param("defaultNewYn") String defaultNewYn,
               @Param("defaultReplyYn") String defaultReplyYn,
               @Param("sortOrder") Integer sortOrder);

    /**
     * 이 사용자의 "새 메일 기본 서명"을 전부 해제한다.
     *
     * <p>{@code exceptIdx} 를 제외 조건으로 받는 이유: 지정하려는 서명까지 N 으로 내렸다가
     * 다시 Y 로 올리면 그 찰나에 기본 서명이 없는 상태가 생긴다. 같은 트랜잭션 안이라
     * 밖에서 보이지는 않지만, 굳이 쓸 필요 없는 UPDATE 를 한 번 더 하는 셈이라 뺀다.
     */
    int clearDefaultNew(@Param("userId") String userId, @Param("exceptIdx") Long exceptIdx);

    /** 답장 기본 서명 해제. {@link #clearDefaultNew} 와 같은 규칙. */
    int clearDefaultReply(@Param("userId") String userId, @Param("exceptIdx") Long exceptIdx);

    /**
     * 물리 삭제.
     *
     * <p>서명은 발송 시점에 본문으로 복사돼 나가므로, 지워도 이미 보낸 메일의 서명은
     * 그대로 남는다. 감사 이력이 걸리지 않아 소프트 삭제가 필요 없다(메일 본체와 다른 점).
     */
    int delete(@Param("signIdx") Long signIdx, @Param("userId") String userId);

    /** 서명 개수 상한 검사용. */
    int countByUserId(@Param("userId") String userId);

    /** 새 서명을 맨 뒤에 붙일 때 쓸 다음 정렬값. 행이 없으면 0. */
    int selectNextSortOrder(@Param("userId") String userId);
}
