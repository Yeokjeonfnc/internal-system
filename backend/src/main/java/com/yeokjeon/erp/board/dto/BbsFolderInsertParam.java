package com.yeokjeon.erp.board.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BbsFolderInsertParam {
    private Integer folderIdx;
    private String folderNm;
    private Integer sortOrder;
    private String useYn;
    private String ownerViewYn;
    private String staffViewYn;
    private String userId;
}
