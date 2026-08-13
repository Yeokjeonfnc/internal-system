package com.yeokjeon.erp.auth.mapper;

import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AuthProfileMapper {

    AuthProfileRowDto selectByUserId(@Param("userId") String userId);

    /** 저장된 비밀번호(BCrypt 해시). 검증은 애플리케이션에서 한다. */
    String selectPasswordHash(@Param("userId") String userId);

    /** 최초 로그인 시 비밀번호 변경 강제 여부('Y'/'N'). */
    String selectPwdResetYn(@Param("userId") String userId);

    int updatePasswordHash(
            @Param("userId") String userId, @Param("passwordHash") String passwordHash);

    /** 선택 컬럼 — 미적용 DB 에서는 예외가 난다. 호출측에서 감쌀 것. */
    int updatePwdResetYn(@Param("userId") String userId, @Param("pwdResetYn") String pwdResetYn);

    int updateProfile(@Param("userId") String userId, @Param("body") AuthProfileUpdateRequestDto body);
}
