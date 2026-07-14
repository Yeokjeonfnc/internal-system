package com.yeokjeon.erp.chat.dto;

import java.time.OffsetDateTime;

/** chat_room 조회 행 — 방 기본정보 + 마지막 메시지 + 안읽음 수. */
public record ChatRoomRow(
        Integer roomIdx,
        String title,
        Boolean isGroup,
        String lastText,
        OffsetDateTime lastAt,
        Integer unreadCount) {
}
