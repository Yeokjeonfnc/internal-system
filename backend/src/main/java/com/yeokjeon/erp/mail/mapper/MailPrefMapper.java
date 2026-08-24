package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailPrefJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 개인 메일 설정(mail_pref) 매퍼 (mal001-E).
 *
 * <p>테이블이 키-값 한 쌍뿐이라 매퍼도 조회·upsert 두 개면 충분하다.
 * 설정 항목이 늘어도 여기는 그대로다 — 그게 컬럼 대신 키-값으로 둔 이유다.
 */
@Mapper
public interface MailPrefMapper {

    List<MailPrefJdbcRow> selectByUserId(@Param("userId") String userId);

    /**
     * 다건 upsert.
     *
     * <p>키마다 한 문장씩 던지지 않고 {@code foreach} 로 묶는 이유는 왕복 횟수도 있지만,
     * 설정 화면이 "저장" 한 번에 여러 항목을 바꾸기 때문이다. 중간에 실패해 일부만
     * 반영되면 화면과 DB 가 어긋난 채 남는다.
     *
     * <p>PK 가 (user_id, pref_key) 라 {@code ON CONFLICT ... DO UPDATE} 로 삽입·수정이
     * 한 문장에 처리된다. 먼저 SELECT 해서 갈래를 나누면 동시 저장 시 경합이 생긴다.
     */
    int upsertBatch(@Param("userId") String userId, @Param("prefs") Map<String, String> prefs);
}
