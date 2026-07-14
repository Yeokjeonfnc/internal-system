package com.yeokjeon.erp.chat.dto;

import java.time.OffsetDateTime;

/** chat_message + user_mst 조인 조회 행. */
public record ChatMessageRow(
        Long messageIdx,
        Integer roomIdx,
        String senderId,
        String senderName,
        String text,
        OffsetDateTime createdAt,
        String msgType,
        String fileName,
        String storedName,
        String contentType,
        Long fileSize,
        Boolean deleted) {
}
