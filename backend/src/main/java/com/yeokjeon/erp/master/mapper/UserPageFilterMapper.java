package com.yeokjeon.erp.master.mapper;

import com.yeokjeon.erp.master.dto.UserPageFilterDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UserPageFilterMapper {

    Integer selectUserIdxByUserId(@Param("userId") String userId);

    UserPageFilterDto selectByUserIdxAndPageCode(
            @Param("userIdx") int userIdx,
            @Param("pageCode") String pageCode);

    int upsert(
            @Param("userIdx") int userIdx,
            @Param("pageCode") String pageCode,
            @Param("filterJson") String filterJson);
}
