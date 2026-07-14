package com.yeokjeon.erp.chat.dto;

/** chat_room_member + user_mst 조인 조회 행. */
public record ChatMemberRow(
        String userId,
        String userName,
        String deptNm) {
}
