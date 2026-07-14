package com.yeokjeon.erp.active.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ActAttachmentInsertParam {
    private Integer actAttIdx;
    private Integer actIdx;
    private String fileName;
    private String storedName;
    private long fileSize;
    private String contentType;
    private String modifiedBy;
}
