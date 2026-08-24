package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailForwardRuleInsertParam;
import com.yeokjeon.erp.mail.dto.MailForwardRuleJdbcRow;
import com.yeokjeon.erp.mail.dto.MailForwardSettingJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 자동전달 매퍼 — 전체 설정(mail_forward_setting) + 예외 규칙(mail_forward_rule) (mal001-L).
 *
 * <p><b>한 매퍼가 두 테이블을 다룬다.</b> 이 프로젝트는 테이블당 매퍼 하나가 관례지만
 * 여기서는 예외로 뒀다 — 두 테이블이 "자동전달 설정" 하나를 이루고 <b>언제나 함께</b>
 * 읽힌다(설정 화면 진입, 수신 시 전달 대상 판정). 매퍼를 나누면 호출부가 매번 둘을
 * 주입받아 짝지어야 하고, 그러다 한쪽만 읽는 실수가 생긴다.
 *
 * <p>{@link MailFolderMapper} 와 같이 모든 메서드가 {@code userId} 를 받는다. 전달 설정은
 * 개인 소유물이고, 특히 <b>전달 주소를 바꿀 수 있으면 남의 메일을 자기 주소로 빼돌릴 수
 * 있다</b>. 서비스 검사와 SQL 조건의 이중 방어가 여기서는 특히 중요하다.
 */
@Mapper
public interface MailForwardMapper {

    // ── 전체 설정 ───────────────────────────────────────────────────────────

    /** 저장한 적이 없으면 null. 호출부는 "꺼짐"으로 읽는다(빈 행을 미리 만들지 않는다). */
    MailForwardSettingJdbcRow selectSetting(@Param("userId") String userId);

    /**
     * 전체 설정 upsert.
     *
     * <p>INSERT 가 아니라 upsert 인 이유: 사용자당 1행이라 "처음 저장"과 "수정"을 호출부가
     * 구분해 봐야 얻는 것이 없고, 구분하면 두 요청이 동시에 들어왔을 때 PK 충돌로 죽는다.
     */
    int upsertSetting(@Param("userId") String userId,
                      @Param("useYn") String useYn,
                      @Param("forwardEmail") String forwardEmail,
                      @Param("keepOriginalYn") String keepOriginalYn);

    // ── 예외 규칙 ───────────────────────────────────────────────────────────

    /** 설정 화면용 전체 목록(꺼 둔 규칙 포함). */
    List<MailForwardRuleJdbcRow> selectRulesByUserId(@Param("userId") String userId);

    /**
     * 수신 시 적용할 예외 규칙만(use_yn='Y').
     *
     * <p><b>EMAIL 을 DOMAIN 보다 먼저</b> 준다. 같은 발신자가 두 규칙에 걸릴 수 있는데
     * (예: {@code tax@hometax.go.kr} 과 도메인 {@code hometax.go.kr}), 그때는 더 구체적인
     * 주소 규칙이 이겨야 사용자의 의도와 맞는다. sort_order 로 뒤집을 수 없게 정렬 첫 키로 뒀다.
     */
    List<MailForwardRuleJdbcRow> selectActiveRulesByUserId(@Param("userId") String userId);

    /** 본인 소유일 때만 행을 돌려준다. 남의 규칙이면 null(서비스가 404 로 바꾼다). */
    MailForwardRuleJdbcRow selectRuleByIdx(@Param("ruleIdx") Long ruleIdx,
                                           @Param("userId") String userId);

    /** useGeneratedKeys 로 param.mailFwdRuleIdx 에 새 PK 가 채워진다 */
    int insertRule(MailForwardRuleInsertParam param);

    /** 부분 수정. null 인 항목은 COALESCE 로 기존 값을 유지한다(PATCH 의미론). */
    int updateRule(@Param("ruleIdx") Long ruleIdx,
                   @Param("userId") String userId,
                   @Param("matchType") String matchType,
                   @Param("matchVal") String matchVal,
                   @Param("forwardEmail") String forwardEmail,
                   @Param("useYn") String useYn,
                   @Param("sortOrder") Integer sortOrder);

    int deleteRule(@Param("ruleIdx") Long ruleIdx, @Param("userId") String userId);

    /** 사용자당 예외 규칙 상한(10개) 검사용. */
    int countRulesByUserId(@Param("userId") String userId);

    /**
     * 같은 발신자 조건이 이미 있는지. {@code excludeIdx} 는 수정 시 자기 자신을 제외하려는 것.
     *
     * <p>{@code uq_mail_fwd_rule_match} 가 어차피 막지만, 그대로 두면 사용자에게 제약 위반
     * 원문이 나간다. 여기서 미리 세어 사람이 읽을 문장으로 바꾼다.
     */
    int countRuleByMatch(@Param("userId") String userId,
                         @Param("matchType") String matchType,
                         @Param("matchVal") String matchVal,
                         @Param("excludeIdx") Long excludeIdx);

    /** 새 규칙을 맨 뒤에 붙일 때 쓸 다음 정렬값. 행이 없으면 0. */
    int selectNextRuleSortOrder(@Param("userId") String userId);
}
