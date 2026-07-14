package com.yeokjeon.erp.chat.dto;

import jakarta.validation.constraints.NotBlank;

/** 메시지 전송 요청. */
public record ChatMessageSendRequest(
        @NotBlank(message = "메시지를 입력하세요.")
        String text) {
}
