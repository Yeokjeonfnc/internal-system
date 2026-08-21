package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.MstUserListJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MstUserMapper {

    List<MstUserListJdbcRow> selectUsersEnriched(@Param("deptIdx") Integer deptIdx);

    List<MstUserListJdbcRow> selectResignedUsersEnriched();

    MstUserListJdbcRow selectUserEnrichedById(@Param("userIdx") int userIdx);
}
