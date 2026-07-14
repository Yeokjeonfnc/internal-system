package com.yeokjeon.erp.chat.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChatRoomInsertParam {
    private Integer roomIdx;
    private String title;
    private Boolean group;
    private String createdBy;
}
