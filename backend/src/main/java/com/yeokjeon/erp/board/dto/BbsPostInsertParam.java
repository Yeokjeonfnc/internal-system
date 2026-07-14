package com.yeokjeon.erp.board.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BbsPostInsertParam {
    private Integer postIdx;
    private Integer folderIdx;
    private Integer storeIdx;
    private String title;
    private String bodyTxt;
    private String privateYn;
    private String noticeYn;
    private String userId;
}
