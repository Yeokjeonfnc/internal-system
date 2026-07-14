package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.OwnerUserListJdbcRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MstOwnerUserMapper {

    List<OwnerUserListJdbcRow> selectOwnerUsers();

    OwnerUserListJdbcRow selectOwnerUserById(@Param("userIdx") int userIdx);
}
