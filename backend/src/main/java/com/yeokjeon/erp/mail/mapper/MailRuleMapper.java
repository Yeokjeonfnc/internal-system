package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailRuleInsertParam;
import com.yeokjeon.erp.mail.dto.MailRuleJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 자동분류 규칙(mail_rule) 매퍼 (mal001-K).
 *
 * <p>{@link MailFolderMapper} 와 같이 <b>모든 조회·변경 메서드가 {@code userId} 를 받는다.</b>
 * 규칙은 개인 소유물이라 PK 만으로 갱신·삭제하면 idx 만 바꿔 남의 규칙을 지울 수 있다.
 * 서비스에서 소유자를 확인하고 SQL 에서 한 번 더 거는 이중 방어인데, 서비스 쪽 검사를
 * 누가 빠뜨려도 SQL 이 0행을 갱신하고 끝나게 하려는 것이다.
 *
 * <p>{@link #selectActiveByUserId} 만 예외적으로 수신 파이프라인이 부른다. 그때의
 * {@code userId} 는 화면이 준 값이 아니라 <b>수신자 주소로 찾아낸</b> 사용자다.
 */
@Mapper
public interface MailRuleMapper {

    /** 설정 화면용 전체 목록(꺼 둔 규칙 포함). sort_order → idx 순. */
    List<MailRuleJdbcRow> selectByUserId(@Param("userId") String userId);

    /**
     * 수신 시 적용할 규칙만(use_yn='Y'). sort_order → idx 순.
     *
     * <p>정렬이 곧 우선순위다. 호출부는 위에서부터 훑어 <b>첫 매칭 하나만</b> 적용한다 —
     * 여러 규칙을 다 적용하면 folder_idx 를 덮어써서 결과가 순서에 좌우되는데,
     * 그 동작은 사용자가 예측할 수 없다.
     */
    List<MailRuleJdbcRow> selectActiveByUserId(@Param("userId") String userId);

    /** 본인 소유일 때만 행을 돌려준다. 남의 규칙이면 null(서비스가 404 로 바꾼다). */
    MailRuleJdbcRow selectByIdx(@Param("ruleIdx") Long ruleIdx, @Param("userId") String userId);

    /** useGeneratedKeys 로 param.mailRuleIdx 에 새 PK 가 채워진다 */
    int insert(MailRuleInsertParam param);

    /**
     * 부분 수정(PATCH 의미론). null 인 항목은 기존 값을 유지한다.
     *
     * <p>조건 세 쌍만은 COALESCE 로 처리할 수 없다 — "조건을 지운다"가 곧 NULL 이라
     * null 이 "안 바꿈"인지 "지움"인지 구분이 안 된다. 그래서 호출부가
     * {@code *Given} 플래그로 "요청에 그 조건이 실려 있었는가"를 알려 준다
     * ({@link MailFolderMapper#update} 의 parentGiven 과 같은 방식).
     *
     * <p>{@code actionType}/{@code actionFolderIdx} 는 짝이라 함께 바뀐다. MOVE 인데
     * 대상 메일함이 없거나 READ 인데 있으면 DB CHECK 가 거부하므로, 서비스가 미리 맞춰 넘긴다.
     */
    int update(@Param("ruleIdx") Long ruleIdx,
               @Param("userId") String userId,
               @Param("ruleNm") String ruleNm,
               @Param("useYn") String useYn,
               @Param("sortOrder") Integer sortOrder,
               @Param("fromGiven") boolean fromGiven,
               @Param("fromOp") String fromOp,
               @Param("fromVal") String fromVal,
               @Param("toGiven") boolean toGiven,
               @Param("toOp") String toOp,
               @Param("toVal") String toVal,
               @Param("subjGiven") boolean subjGiven,
               @Param("subjOp") String subjOp,
               @Param("subjVal") String subjVal,
               @Param("actionGiven") boolean actionGiven,
               @Param("actionType") String actionType,
               @Param("actionFolderIdx") Long actionFolderIdx);

    /**
     * 순서 재지정 — 목록에서의 위치를 그대로 sort_order 로 쓴다.
     *
     * <p>규칙마다 UPDATE 를 던지지 않고 한 문장으로 끝내는 이유는, 중간에 실패하면
     * 순서가 반쯤 섞인 상태가 남기 때문이다(그 상태에서는 어느 규칙이 먼저인지
     * 사용자도 서버도 알 수 없다).
     *
     * @param ruleIdxes 새 순서대로 나열한 idx. 남의 규칙이 섞여 있으면 소유자 조건이 걸러 낸다
     */
    int reorder(@Param("userId") String userId, @Param("ruleIdxes") List<Long> ruleIdxes);

    /** 물리 삭제. 규칙은 이력 가치가 없어서 소프트 삭제하지 않는다. */
    int delete(@Param("ruleIdx") Long ruleIdx, @Param("userId") String userId);

    /** 사용자당 규칙 개수 상한 검사용. */
    int countByUserId(@Param("userId") String userId);

    /** 새 규칙을 맨 뒤에 붙일 때 쓸 다음 정렬값. 행이 없으면 0. */
    int selectNextSortOrder(@Param("userId") String userId);
}
