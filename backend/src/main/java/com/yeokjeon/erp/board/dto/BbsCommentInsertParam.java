package com.yeokjeon.erp.board.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BbsCommentInsertParam {
    private Integer commentIdx;
    private Integer postIdx;
    private String bodyTxt;
    private String userId;
}
