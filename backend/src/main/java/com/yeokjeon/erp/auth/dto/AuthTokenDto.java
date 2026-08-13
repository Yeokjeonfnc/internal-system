package com.yeokjeon.erp.auth.dto;

/** 재발급된 로그인 토큰. 비밀번호 변경 응답에 실어 클라이언트가 곧바로 교체하게 한다. */
public record AuthTokenDto(String accessToken) {}
