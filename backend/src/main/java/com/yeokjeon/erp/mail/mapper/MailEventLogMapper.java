package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailEventLogInsertParam;
import com.yeokjeon.erp.mail.dto.MailEventLogJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 배달 상태 이벤트 원장 매퍼(append-only).
 *
 * <p>delivered 보다 opened 가 먼저 오고, 수신자마다 결과가 갈리고, opened/clicked 는
 * 반복 발생한다. 단일 상태 컬럼으로는 표현이 안 돼서 이벤트를 통째로 쌓는다.
 */
@Mapper
public interface MailEventLogMapper {

    /**
     * ON CONFLICT (svix_id) DO NOTHING — 반환값 0 이면 이미 처리한 중복 웹훅이다.
     * 호출부는 이 값으로 "새 이벤트인가"를 판정하므로 절대 무시하지 말 것.
     */
    int insert(MailEventLogInsertParam param);

    List<MailEventLogJdbcRow> selectByMailIdx(@Param("mailIdx") Long mailIdx, @Param("limit") int limit);

    /**
     * 메일 행보다 먼저 도착해 mail_idx 가 비어 있는 이벤트를 resend_email_id 로 다시 붙인다.
     * 이걸 돌리지 않으면 상세 화면의 배달 타임라인이 영영 비어 보인다.
     */
    int relinkOrphans(@Param("limit") int limit);
}
