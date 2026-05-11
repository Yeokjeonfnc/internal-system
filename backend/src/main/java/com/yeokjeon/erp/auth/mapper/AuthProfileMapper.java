package com.yeokjeon.erp.auth.mapper;

import com.yeokjeon.erp.auth.dto.AuthProfileDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AuthProfileMapper {

    AuthProfileDto selectByUserIdAndPassword(
            @Param("userId") String userId, @Param("userPassword") String userPassword);

    AuthProfileDto selectByUserId(@Param("userId") String userId);

    int updateProfile(@Param("userId") String userId, @Param("body") AuthProfileUpdateRequestDto body);
}
