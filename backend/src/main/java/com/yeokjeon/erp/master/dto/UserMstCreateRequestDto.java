package com.yeokjeon.erp.master.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

/**
 * {@code POST /users} 요청 본문 — {@code user_idx}는 DB가 부여(IDENTITY).
 *
 * <p>{@code userPassword} 를 비워 두면 서버가 초기 비밀번호를 자동으로 설정하고
 * 최초 로그인 시 변경을 강제한다({@link com.yeokjeon.erp.auth.service.AuthService}).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record UserMstCreateRequestDto(
        @NotBlank String userName,
        String userPassword,
        String userId,
        Integer deptIdx,
        String userPhone,
        String userEmail,
        String svYn,
        String positionCd,
        String ownerYn,
        LocalDate joinDt) {}
