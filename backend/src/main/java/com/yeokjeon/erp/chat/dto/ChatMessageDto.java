package com.yeokjeon.erp.chat.dto;

import java.time.OffsetDateTime;

/** 채팅 메시지 — 프론트 ChatMessage 와 1:1 매핑(JSON 키 동일). */
public record ChatMessageDto(
        String id,
        String roomId,
        String senderId,
        String senderName,
        String text,
        OffsetDateTime sentAt,
        String type,
        String fileName,
        Long fileSize,
        String contentType,
        boolean deleted) {
}
