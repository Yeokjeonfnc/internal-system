package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailBodyJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 메일 본문 매퍼.
 *
 * <p>insert 가 아니라 upsert 인 이유: 본문 수집은 재시도되는 작업이고, 수동
 * 재수집(refresh-body) 도 같은 경로를 탄다. INSERT 로 두면 두 번째 시도가
 * PK 충돌로 죽는다.
 */
@Mapper
public interface MailBodyMapper {

    MailBodyJdbcRow selectByMailIdx(@Param("mailIdx") Long mailIdx);

    /**
     * {@code headersRaw} 는 이미 직렬화된 JSON 문자열이며 XML 에서 jsonb 로 캐스팅한다.
     * 재수집 때 headers 가 비어 오면 기존 값을 지우지 않고 유지한다 — 헤더는
     * Resend 보관 기간(30일)이 지나면 다시 받을 방법이 없다.
     */
    int upsert(@Param("mailIdx") Long mailIdx,
               @Param("bodyText") String bodyText,
               @Param("bodyHtml") String bodyHtml,
               @Param("headersRaw") String headersRaw,
               @Param("searchTxt") String searchTxt,
               @Param("truncatedYn") boolean truncatedYn);

    int deleteByMailIdx(@Param("mailIdx") Long mailIdx);
}
