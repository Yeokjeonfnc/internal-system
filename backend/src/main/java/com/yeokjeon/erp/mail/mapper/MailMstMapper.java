package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailCountsJdbcRow;
import com.yeokjeon.erp.mail.dto.MailFolderCountDto;
import com.yeokjeon.erp.mail.dto.MailListQuery;
import com.yeokjeon.erp.mail.dto.MailMstInsertParam;
import com.yeokjeon.erp.mail.dto.MailMstJdbcRow;
import com.yeokjeon.erp.mail.dto.MailUpdateFlagsRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 메일 본체(mail_mst) 매퍼. 목록 화면은 이 테이블만 읽는다.
 *
 * <p>상태 전이용 update 메서드를 잘게 나눠 둔 이유는, 워커가 외부 API 호출 결과에
 * 따라 한 컬럼 묶음만 건드려야 하기 때문이다. 통짜 update 를 쓰면 동시에 도착한
 * 웹훅이 방금 갱신한 last_status 를 옛날 값으로 덮어쓴다.
 */
@Mapper
public interface MailMstMapper {

    /** useGeneratedKeys 로 param.mailIdx 에 새 PK 가 채워진다 */
    int insert(MailMstInsertParam param);

    MailMstJdbcRow selectByIdx(@Param("mailIdx") Long mailIdx);

    MailMstJdbcRow selectByResendEmailId(@Param("resendEmailId") String resendEmailId);

    /** 웹훅 멱등 판정용 — 행 전체가 필요 없을 때 PK 만 싸게 확인한다 */
    Long selectIdxByResendEmailId(@Param("resendEmailId") String resendEmailId);

    List<MailMstJdbcRow> selectByFolder(@Param("q") MailListQuery q);

    /** selectByFolder 와 반드시 같은 조건을 써야 목록과 카운트가 어긋나지 않는다 */
    int countByFolder(@Param("q") MailListQuery q);

    /** 폴더별 건수를 한 번의 스캔으로 모아 온다(왕복 6회 → 1회) */
    MailCountsJdbcRow selectFolderCounts(@Param("ownerUserId") String ownerUserId);

    List<MailMstJdbcRow> selectByThreadIdx(@Param("threadIdx") Long threadIdx);

    List<MailMstJdbcRow> selectByPartnerIdx(@Param("partnerIdx") Integer partnerIdx,
                                            @Param("limit") int limit);

    List<MailMstJdbcRow> selectByMappingId(@Param("mappingId") Long mappingId);

    /**
     * 본문 수집 대기열. {@code maxTryCnt} 로 영원히 실패하는 행을 걷어내고,
     * {@code backoffMinutes} 로 방금 실패한 행을 곧바로 다시 집지 않는다 —
     * 백오프가 없으면 워커가 같은 행으로 Resend rate limit 을 다 태운다.
     */
    List<MailMstJdbcRow> selectBodyPending(@Param("limit") int limit,
                                           @Param("maxTryCnt") int maxTryCnt,
                                           @Param("backoffMinutes") int backoffMinutes);

    List<MailMstJdbcRow> selectSendQueued(@Param("limit") int limit,
                                          @Param("maxTryCnt") int maxTryCnt,
                                          @Param("backoffMinutes") int backoffMinutes);

    /** 외부 호출 직전에 부른다. 호출이 통째로 유실돼도 시도 횟수는 남아야 무한 재시도를 막는다 */
    int markBodyTried(@Param("mailIdx") Long mailIdx);

    /**
     * 본문 수집 대상 1건을 <b>선점</b>한다 (mal001-M).
     *
     * <p>{@link #markBodyTried} 와 하는 일(시도 횟수 +1, 시각 갱신)은 같지만, 조건이
     * {@link #selectBodyPending} 과 <b>완전히 같다</b>는 점이 다르다. UPDATE 는 행 잠금을
     * 잡고 조건을 다시 확인하므로, 두 경로가 같은 행을 동시에 노려도 <b>정확히 한 쪽만</b>
     * 1을 돌려받는다.
     *
     * <p>이게 필요해진 이유: 수신 웹훅/발송 API 가 저장 직후 즉시 트리거를 걸면서
     * 워커와 같은 행을 동시에 집을 수 있게 됐다. 기존 방어는 "backoff 가 지나야 다시
     * 집는다"는 시간 기반이었는데, 새로 만들어진 행은 {@code body_tried_at IS NULL}
     * 이라 양쪽 모두에게 즉시 자격이 있어 그 방어가 통하지 않는다.
     *
     * <p>{@code maxTryCnt}/{@code backoffMinutes} 는 {@link #selectBodyPending} 에 넘기는
     * 값과 반드시 같아야 한다. 조건이 갈리면 워커가 고른 행을 선점이 계속 거부해
     * 본문이 영원히 안 채워진다.
     *
     * @return 1이면 이 호출이 선점에 성공한 것. 0이면 다른 쪽이 이미 가져갔거나
     *         대상 조건에서 벗어난 것이므로 <b>아무 것도 하지 말고 넘어가야</b> 한다.
     */
    int claimBodyPending(@Param("mailIdx") Long mailIdx,
                         @Param("maxTryCnt") int maxTryCnt,
                         @Param("backoffMinutes") int backoffMinutes);

    int updateBodyDone(@Param("mailIdx") Long mailIdx,
                       @Param("snippet") String snippet,
                       @Param("attCnt") Integer attCnt,
                       @Param("rfcMessageId") String rfcMessageId,
                       @Param("inReplyTo") String inReplyTo,
                       @Param("refsTxt") String refsTxt);

    /**
     * 본문 수집 실패 기록.
     *
     * <p>{@code maxTryCnt} 는 {@link #selectBodyPending} 에 넘기는 값과 <b>반드시 같아야</b> 한다.
     * 두 숫자가 갈리면 시도를 다 쓴 행이 FAILED 로 확정되지도, 다시 선택되지도 않아
     * PENDING 인 채로 영원히 남는다.
     *
     * @param permanent 재시도해도 결과가 같은 확정 실패면 true — 시도 횟수와 무관하게 FAILED 로 굳힌다.
     */
    int updateBodyFailed(@Param("mailIdx") Long mailIdx,
                         @Param("bodyErr") String bodyErr,
                         @Param("maxTryCnt") int maxTryCnt,
                         @Param("permanent") boolean permanent);

    int markSendTried(@Param("mailIdx") Long mailIdx);

    /**
     * 발송 대상 1건을 <b>선점</b>한다 (mal001-M).
     *
     * <p>{@link #claimBodyPending} 과 같은 장치의 발송판이다. 조건이
     * {@link #selectSendQueued} 와 완전히 같아서, 즉시 트리거와 워커가 같은 메일을
     * 동시에 집으면 한 쪽만 1을 받는다.
     *
     * <p>Resend 의 {@code Idempotency-Key} 가 중복 발송 자체는 막아 주지만, 그것에
     * 의지하면 (1) 같은 메일로 rate limit 을 두 번 태우고, (2) 두 호출이 겹칠 때
     * Resend 가 409(concurrent request)를 돌려주며, (3) 24시간이 지나면 키가 만료돼
     * 방어가 사라진다. 우리 쪽에서 먼저 끊는 편이 맞다.
     *
     * @return 1이면 선점 성공. 0이면 다른 쪽이 가져갔거나 이미 QUEUED 가 아니다.
     */
    int claimSendQueued(@Param("mailIdx") Long mailIdx,
                        @Param("maxTryCnt") int maxTryCnt,
                        @Param("backoffMinutes") int backoffMinutes);

    /** DRAFT 일 때만 QUEUED 로 올린다. 이미 나간 메일을 두 번 보내지 않기 위한 조건부 갱신 */
    int updateSendQueued(@Param("mailIdx") Long mailIdx);

    int updateSendSent(@Param("mailIdx") Long mailIdx,
                       @Param("resendEmailId") String resendEmailId,
                       @Param("mailAt") OffsetDateTime mailAt);

    /**
     * 발송 실패 기록.
     *
     * <p>{@code maxTryCnt} 는 {@link #selectSendQueued} 에 넘기는 값과 <b>반드시 같아야</b> 한다.
     * 갈리면 메일이 FAILED 표시도 없이 QUEUED 로 갇히고, updateSendQueued 는 DRAFT 만
     * 갱신하므로 사용자가 되살릴 방법도 없다.
     *
     * @param permanent 재시도가 무의미한 실패(수신자·본문 누락, 비재시도성 4xx)면 true.
     *                  시도 횟수와 무관하게 즉시 FAILED 로 확정한다.
     */
    int updateSendFailed(@Param("mailIdx") Long mailIdx,
                         @Param("sendErr") String sendErr,
                         @Param("maxTryCnt") int maxTryCnt,
                         @Param("permanent") boolean permanent);

    /**
     * 바운스/failed 웹훅 전용 확정 실패.
     *
     * <p>{@link #updateSendFailed} 를 쓰면 안 된다 — 바운스 시점의 행은 이미 SENT 라
     * 임계값 분기를 타면 QUEUED 로 후퇴해 반송된 주소로 재발송된다.
     */
    int markSendBounced(@Param("mailIdx") Long mailIdx, @Param("sendErr") String sendErr);

    /**
     * 배달 상태 캐시 갱신. {@code rank} 가 기존 상태의 서열보다 낮으면 갱신하지 않는다.
     * 웹훅은 순서를 보장하지 않아서, 조건 없이 덮어쓰면 늦게 도착한 delivered 가
     * 이미 기록된 bounced 를 지워 버린다.
     */
    int updateLastStatus(@Param("mailIdx") Long mailIdx,
                         @Param("lastStatus") String lastStatus,
                         @Param("lastStatusAt") OffsetDateTime lastStatusAt,
                         @Param("rank") int rank);

    int updateFlags(@Param("mailIdx") Long mailIdx, @Param("body") MailUpdateFlagsRequestDto body);

    int updateReadYn(@Param("mailIdx") Long mailIdx, @Param("readYn") String readYn);

    /** mail_att 실제 건수로 att_cnt 를 다시 계산한다(첨부 추가·삭제 후) */
    int updateAttCnt(@Param("mailIdx") Long mailIdx);

    /** 메일 이력은 감사 대상이라 물리 삭제하지 않는다 */
    int softDelete(@Param("mailIdx") Long mailIdx);

    // ── 2차 확장 ─────────────────────────────────────────────────────────────

    /**
     * 목록 일괄 동작 (mal001-B).
     *
     * <p>동작별로 메서드를 나누지 않고 하나로 묶은 이유: 열 가지 동작이 전부
     * "내 메일 중 이 idx 들의 컬럼 하나를 바꾼다"는 같은 모양이라, 나누면 소유자 확인
     * ({@code user_id = #{userId}})과 빈 목록 방어({@code 1 = 0})가 열 군데로 복사된다.
     * 그 중 한 곳만 빠뜨려도 남의 메일이 갱신된다.
     *
     * <p><b>{@code userId} 조건은 XML 에서 절대 빼지 말 것.</b> mailIdxes 는 화면이 준
     * 값이라 다른 사람의 mail_idx 가 섞여 올 수 있다.
     *
     * @param action    {@code MailBulkAction} 의 name(). XML 이 이 값으로 SET 절을 고른다.
     * @param folderIdx MOVE 일 때 목적지. null 이면 기본함으로 되돌린다.
     * @return 실제로 갱신된 건수. 요청 건수보다 적으면 남의 메일이거나 이미 그 상태였다는 뜻.
     */
    int bulkUpdate(@Param("mailIdxes") List<Long> mailIdxes,
                   @Param("userId") String userId,
                   @Param("action") String action,
                   @Param("folderIdx") Long folderIdx);

    /**
     * 완전 삭제(물리 삭제).
     *
     * <p>일괄 동작 중 유일하게 되돌릴 수 없다. mail_body/mail_att/mail_event_log 가
     * {@code ON DELETE CASCADE} 로 매달려 있어 배달 이력까지 함께 사라진다.
     *
     * <p>그래서 <b>이미 휴지통에 있는(deleted_yn = true) 메일만</b> 지운다. 목록에서
     * 바로 완전삭제가 되면 실수 한 번에 복구 불가능한 손실이 생긴다 — 휴지통을 한 번
     * 거치게 하는 것이 사실상의 확인 단계다.
     */
    int purgeByIdxes(@Param("mailIdxes") List<Long> mailIdxes, @Param("userId") String userId);

    /**
     * 사용자 정의 메일함별 안읽음/전체 건수 (mal001-I).
     *
     * <p>기본함 집계({@link #selectFolderCounts})와 쿼리를 나눈 이유는 결과 모양이
     * 다르기 때문이다 — 기본함은 고정 컬럼 한 행, 사용자 함은 가변 행 N개다.
     * 한 쿼리로 억지로 합치면 어느 쪽도 읽기 어려운 SQL 이 된다.
     */
    List<MailFolderCountDto> selectCustomFolderCounts(@Param("ownerUserId") String ownerUserId);

    /**
     * 예약발송으로 확정한다. DRAFT/QUEUED 일 때만 올린다.
     *
     * <p>이미 SENT 인 메일을 예약으로 되돌리면 발송 이력이 사라진 것처럼 보이므로
     * 조건부 갱신이다({@link #updateSendQueued} 와 같은 이유).
     */
    int updateScheduled(@Param("mailIdx") Long mailIdx,
                        @Param("scheduledAt") OffsetDateTime scheduledAt,
                        @Param("resendEmailId") String resendEmailId);

    /**
     * 예약 취소 — SCHEDULED → DRAFT 로 되돌린다.
     *
     * <p>{@code resend_email_id} 를 NULL 로 지우는 것이 중요하다. 취소된 예약 메일의
     * id 를 남겨 두면 (1) 그 메일을 다시 보낼 때 유니크 제약에 걸리고,
     * (2) 뒤늦게 도착한 웹훅이 취소된 메일에 배달 상태를 찍는다.
     */
    int updateScheduleCancelled(@Param("mailIdx") Long mailIdx);

    /**
     * 수신확인 기록 (mal001-G).
     *
     * <p>{@code opened_at} 은 {@code COALESCE} 로 <b>최초 1회만</b> 남긴다 — 사용자가
     * 알고 싶은 것은 "언제 처음 읽었나"이고, 매번 덮으면 그 값이 사라진다.
     * {@code open_cnt} 는 매 호출마다 올린다.
     *
     * <p>발신 메일에만 적용한다({@code direction='OUT'}). 수신 메일에 열람 기록이 찍히면
     * "내가 받은 메일을 상대가 읽었다"는 말이 안 되는 상태가 된다.
     *
     * <p>open_cnt 는 smallint(최대 32767)라 상한에서 멈춘다. 넘치면 예외가 나는데,
     * 열람 기록 하나 때문에 픽셀 응답이 500 이 되면 본문에 깨진 이미지가 뜬다.
     */
    int markOpened(@Param("mailIdx") Long mailIdx);

    // ── 3차 확장: 자동분류 · 자동전달 ────────────────────────────────────────

    /**
     * 자동분류 규칙의 '메일함 이동' (mal001-K).
     *
     * <p>{@link #bulkUpdate} 의 MOVE 를 재사용하지 않는 이유는 소유자 조건이다.
     * bulkUpdate 는 "요청자 본인 또는 담당자 미지정" 메일만 건드리는데, 규칙을 적용하는
     * 주체는 요청자가 아니라 <b>수신자 주소로 찾아낸 사용자</b>다. 그 조건을 그대로 쓰면
     * 규칙이 조용히 0건 갱신으로 끝난다.
     *
     * <p>대신 수신 메일이면서 전달로 생성된 것이 아닌 행으로 좁힌다.
     */
    int updateRuleFolder(@Param("mailIdx") Long mailIdx, @Param("folderIdx") Long folderIdx);

    /**
     * 자동전달로 만들어진 메일에 원본 번호를 남긴다 (mal001-L).
     *
     * <p>이 표시가 무한 전달을 막는 장치다. 표시가 있는 행은 규칙·전달 엔진이 건너뛰고,
     * "이 원본을 이미 전달했는가"({@link #countByFwdSrcIdx})의 근거도 이 값이다.
     *
     * <p>발송 요청 DTO 에 필드를 열지 않고 사후에 UPDATE 하는 이유: 그 DTO 는 화면이
     * 보내는 값이라, 클라이언트가 임의의 메일을 "전달로 생성된 것"으로 표시해
     * 규칙 적용에서 빼돌릴 수 있게 된다.
     */
    int updateFwdSrcIdx(@Param("mailIdx") Long mailIdx, @Param("fwdSrcIdx") Long fwdSrcIdx);

    /**
     * 이 원본을 이미 전달했는가.
     *
     * <p>본문 수동 재수집({@code refresh-body})이 같은 전달 경로를 다시 타기 때문에
     * 필요하다. 이 검사가 없으면 "본문 다시 받기"를 누를 때마다 전달 메일이 한 통씩 더 나간다.
     */
    int countByFwdSrcIdx(@Param("fwdSrcIdx") Long fwdSrcIdx);
}
