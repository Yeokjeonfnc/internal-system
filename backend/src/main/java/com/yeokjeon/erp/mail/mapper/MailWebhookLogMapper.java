package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailWebhookLogJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 웹훅 수신 원장 매퍼(멱등성 1차 방어선).
 *
 * <p>Resend 는 at-least-once 배달이고 중복 제거 키로 svix-id 헤더를 지정한다.
 * 원장에 먼저 꽂고 나서 실제 처리를 하기 때문에, 처리 도중 서버가 죽어도
 * 페이로드는 남아 워커가 이어서 재처리할 수 있다.
 */
@Mapper
public interface MailWebhookLogMapper {

    /**
     * 반환값 1 이면 신규, 0 이면 이미 받은 중복 전달이다.
     * 호출부는 0 일 때 곧바로 200 을 돌려주고 아무 처리도 하지 않아야 한다.
     */
    int insertIfAbsent(@Param("svixId") String svixId,
                       @Param("eventType") String eventType,
                       @Param("resendEmailId") String resendEmailId,
                       @Param("payload") String payloadJson);

    MailWebhookLogJdbcRow selectBySvixId(@Param("svixId") String svixId);

    /** try_cnt 를 올리고 tried_at 을 찍는다. 재처리 백오프의 기준이 된다 */
    int markStatus(@Param("svixId") String svixId,
                   @Param("processStatus") String processStatus,
                   @Param("errorMsg") String errorMsg);

    /** PENDING 뿐 아니라 FAILED 도 집는다 — 일시적 오류로 실패한 건이 그대로 묻히면 메일이 유실된다 */
    List<MailWebhookLogJdbcRow> selectPending(@Param("limit") int limit, @Param("maxTryCnt") int maxTryCnt);

    List<MailWebhookLogJdbcRow> selectRecent(@Param("limit") int limit);

    int deleteOlderThan(@Param("days") int days);
}
