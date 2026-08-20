package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.MstUserListJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MstUserMapper {

    List<MstUserListJdbcRow> selectUsersEnriched(@Param("deptIdx") Integer deptIdx);

    MstUserListJdbcRow selectUserEnrichedById(@Param("userIdx") int userIdx);

    /*
     * 사원 삭제 전 정리 — user_mst 를 참조하지만 ON DELETE CASCADE 가 없는 테이블들.
     * 활동 도메인 테이블이지만 "사원을 지울 수 있는가"는 사원관리의 책임이라 여기 둔다.
     */

    int deleteActivityPlanStoreByUserIdx(@Param("userIdx") int userIdx);

    int deleteActivityPlanByUserIdx(@Param("userIdx") int userIdx);

    int deleteTeamViewPermissionByUserIdx(@Param("userIdx") int userIdx);
}
