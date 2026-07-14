package com.yeokjeon.erp.chat.dto;

/** 채팅 참여자(사원) — 프론트 ChatMember 와 1:1 매핑. */
public record ChatMemberDto(
        String userId,
        String userName,
        String deptNm) {
}
