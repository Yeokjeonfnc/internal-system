package com.yeokjeon.erp.chat.dto;

import java.time.OffsetDateTime;
import java.util.List;

/** 채팅방 — 프론트 ChatRoom 과 1:1 매핑(JSON 키 동일). */
public record ChatRoomDto(
        String id,
        String title,
        boolean isGroup,
        List<ChatMemberDto> members,
        String lastText,
        OffsetDateTime lastAt,
        int unreadCount) {
}
