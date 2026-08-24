package com.yeokjeon.erp.mail.dto;

/**
 * 수신자 검색 결과 한 행 (mal001-J).
 *
 * <p>사원·거래처·부서를 UNION ALL 로 합치기 때문에 세 테이블의 서로 다른 컬럼을
 * 이 공통 모양으로 캐스팅해서 담는다. {@code refIdx} 가 Long 인 이유는 세 테이블의
 * PK 가 모두 integer 인데 UNION 결과를 하나의 타입으로 받아야 하기 때문이다.
 */
public record MailRecipientJdbcRow(
        String type,
        Long refIdx,
        String name,
        String email,
        String deptNm,
        Integer memberCnt) {
}
