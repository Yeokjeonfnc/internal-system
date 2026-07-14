package com.yeokjeon.erp.chat.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** 새 방 생성 요청 — 상대 멤버 ID 목록(현재 사용자는 서버에서 추가)과 (그룹) 방 이름. */
public record ChatRoomCreateRequest(
        @NotEmpty(message = "대화 상대를 선택하세요.")
        List<String> memberIds,
        String title) {
}
