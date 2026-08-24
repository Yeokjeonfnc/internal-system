package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailThreadInsertParam;
import com.yeokjeon.erp.mail.dto.MailThreadMstJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 메일 스레드(대화 묶음) 매퍼.
 *
 * <p>스레드 연결은 2단계다. 먼저 References/In-Reply-To 로 정확히 잇고
 * ({@link #selectThreadIdxByMessageIds}), 그게 없으면 제목으로 폴백한다
 * ({@link #selectThreadIdxBySubjectNorm}). 헤더를 제대로 안 붙이는 메일 클라이언트가
 * 실무에 흔해서 폴백이 없으면 답장마다 새 스레드가 생긴다.
 */
@Mapper
public interface MailThreadMapper {

    MailThreadMstJdbcRow selectByIdx(@Param("threadIdx") Long threadIdx);

    /**
     * 주어진 Message-ID 들 중 하나라도 물고 있는 메일의 스레드를 찾는다.
     * 정방향(내 References 가 기존 메일을 가리킴)과 역방향(기존 메일이 나를
     * 부모로 가리킴)을 모두 본다 — 웹훅 도착 순서가 뒤집히는 일이 실제로 있다.
     */
    Long selectThreadIdxByMessageIds(@Param("messageIds") List<String> messageIds);

    /**
     * 제목 폴백 매칭. {@code withinDays} 로 기간을 좁히는 이유는, "회신"처럼 흔한
     * 제목이 몇 년 치 메일을 한 스레드로 뭉쳐 버리는 사고를 막기 위해서다.
     */
    Long selectThreadIdxBySubjectNorm(@Param("subjectNorm") String subjectNorm,
                                      @Param("withinDays") int withinDays);

    /** useGeneratedKeys 로 param.threadIdx 에 새 PK 가 채워진다 */
    int insert(MailThreadInsertParam param);

    /** mail_mst 기준으로 first/last_mail_at, mail_cnt 를 다시 계산한다 */
    int touch(@Param("threadIdx") Long threadIdx);

    List<MailThreadMstJdbcRow> selectRecent(@Param("limit") int limit);
}
