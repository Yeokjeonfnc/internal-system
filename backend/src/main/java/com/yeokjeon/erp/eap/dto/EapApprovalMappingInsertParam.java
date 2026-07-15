package com.yeokjeon.erp.eap.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EapApprovalMappingInsertParam {
    private Long id;
    private String erpMenuId;
    private String erpSourceId;
    private String daouDocumentId;
    private String daouFormCode;
    private String status;
    private String draftUserId;
    private String title;
    private String contentHtml;
}
