package com.yeokjeon.erp.mail.mapper;

import com.yeokjeon.erp.mail.dto.MailRecipientJdbcRow;
import com.yeokjeon.erp.mail.dto.MailUserRefJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 조직도 수신자 검색 매퍼 (mal001-J).
 *
 * <p>메일 전용 매퍼로 두고 master 쪽 매퍼를 재사용하지 않는다. 사원·거래처·부서를
 * 하나의 결과 모양으로 합치는 것은 메일 수신자 선택 화면에서만 필요한 형태이고,
 * 공용 매퍼에 이 쿼리를 넣으면 master 모듈이 메일 화면의 요구사항에 끌려다닌다.
 */
@Mapper
public interface MailRecipientMapper {

    /**
     * 사원 + 거래처 + 부서 통합 검색.
     *
     * <p>세 출처를 UNION ALL 로 붙인다. UNION(중복 제거)이 아닌 이유는 출처가 달라
     * 중복이 애초에 생길 수 없고, 중복 제거 정렬만 비용으로 남기 때문이다.
     *
     * @param keyword null/빈 값이면 전체(상한까지). 화면 첫 진입에서 조직도를 그대로
     *                펼쳐 보여 줄 수 있어야 해서 빈 검색을 허용한다.
     */
    List<MailRecipientJdbcRow> search(@Param("keyword") String keyword, @Param("limit") int limit);

    /**
     * 특정 부서의 부서원 메일주소 목록.
     *
     * <p>화면에서 부서를 고르면 이 결과로 to 를 채운다. 하위 부서까지 포함할지는
     * {@code includeSub} 로 정한다 — 다우오피스는 부서 트리에서 고른 노드만 넣는 것이
     * 기본이라 기본값도 false 로 둔다.
     */
    List<MailRecipientJdbcRow> selectDeptMembers(@Param("deptIdx") Integer deptIdx,
                                                 @Param("includeSub") boolean includeSub);

    /**
     * 메일주소 → 사원 역방향 조회 (mal001-K/L).
     *
     * <p>자동분류·자동전달은 개인 설정인데, 수신 메일에는 "누구 앞으로 왔는가"가
     * <b>주소로만</b> 적혀 있다. {@code mail_mst.user_id} 는 수신 시점에 비어 있으므로
     * (담당자 배정은 사람이 화면에서 한다) 규칙 주인을 찾으려면 주소로 되짚어야 한다.
     *
     * <p>주소마다 한 번씩 부르지 않고 묶어서 한 번에 묻는다. 수신자가 20명이면 왕복이
     * 20번이 되고, 그 비용을 웹훅/워커 경로에서 치를 이유가 없다. <b>우선순위(TO 먼저,
     * 그다음 CC)는 호출부가 자바에서 정한다</b> — SQL 로 순서를 표현하려면
     * array_position 같은 장치가 필요한데 얻는 것에 비해 읽기 어려워진다.
     *
     * <p>재직자({@code work_yn='Y'})만 준다. 퇴사자의 규칙이 계속 도는 것을 막는다.
     *
     * @param emails 소문자로 정규화된 주소 목록. 빈 목록이면 호출부가 먼저 걸러야 한다
     *               ({@code IN ()} 은 문법 오류다)
     */
    List<MailUserRefJdbcRow> selectUserRefsByEmails(@Param("emails") List<String> emails);
}
