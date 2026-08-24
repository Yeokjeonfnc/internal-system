package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailAddrDtlJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 메일 참여자 매퍼.
 *
 * <p>"이 주소와 주고받은 메일 전부"가 ERP 메일 기능의 존재 이유라서 참여자를
 * JSONB 가 아니라 정규화 테이블로 뒀다. {@link #selectMailIdxByEmail} 이 그 질의다.
 */
@Mapper
public interface MailAddrMapper {

    List<MailAddrDtlJdbcRow> selectByMailIdx(@Param("mailIdx") Long mailIdx);

    /**
     * 참여자를 한 번에 넣는다. 메일 한 통에 수신자가 수십 명일 수 있어 건별 INSERT 는
     * 왕복이 그만큼 늘어난다. 재처리로 같은 참여자가 다시 들어와도 죽지 않도록
     * ON CONFLICT DO NOTHING 을 건다.
     */
    int insertBatch(@Param("mailIdx") Long mailIdx, @Param("rows") List<MailAddrDtlJdbcRow> rows);

    int deleteByMailIdx(@Param("mailIdx") Long mailIdx);

    /** 주소는 소문자로 정규화해 저장하므로 검색어도 소문자로 맞춰 비교한다 */
    List<Long> selectMailIdxByEmail(@Param("email") String email, @Param("limit") int limit);
}
