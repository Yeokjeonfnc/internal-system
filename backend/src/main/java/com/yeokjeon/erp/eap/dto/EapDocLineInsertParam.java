package com.yeokjeon.erp.eap.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EapDocLineInsertParam {
    private Long mappingId;
    private String roleCd;
    private int sortOrder;
    private String userId;
    private String userNm;
    private String titleNm;
    private String lineStatus;
}
