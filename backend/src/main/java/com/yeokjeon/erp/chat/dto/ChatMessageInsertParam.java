package com.yeokjeon.erp.chat.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChatMessageInsertParam {
    private Long messageIdx;
    private Integer roomIdx;
    private String senderId;
    private String msgTxt;
    private String msgType;
    private String fileName;
    private String storedName;
    private String contentType;
    private Long fileSize;
}
