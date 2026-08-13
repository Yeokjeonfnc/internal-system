package com.yeokjeon.erp.master.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 사번(emp_no) 조회·저장.
 *
 * <p>선택 컬럼이다 — {@code user_mst.emp_no} 가 아직 없는 DB 에서는 예외가 난다.
 * 호출측(서비스)에서 반드시 try/catch 로 감싸 조용히 건너뛰게 할 것. 사원관리
 * 핵심 목록/조회 쿼리(MstUserMapper)와는 완전히 분리해 둔다 — 이 컬럼이 없다고
 * 사원 목록 전체가 깨지면 안 되기 때문이다.
 */
@Mapper
public interface EmpNoMapper {

    String selectEmpNo(@Param("userIdx") int userIdx);

    int upsertEmpNo(@Param("userIdx") int userIdx, @Param("empNo") String empNo);
}
