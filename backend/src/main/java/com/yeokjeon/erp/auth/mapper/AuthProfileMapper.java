package com.yeokjeon.erp.auth.mapper;

import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AuthProfileMapper {

    AuthProfileRowDto selectByUserIdAndPassword(
            @Param("userId") String userId, @Param("userPassword") String userPassword);

    AuthProfileRowDto selectByUserId(@Param("userId") String userId);

    int updateProfile(@Param("userId") String userId, @Param("body") AuthProfileUpdateRequestDto body);
}
