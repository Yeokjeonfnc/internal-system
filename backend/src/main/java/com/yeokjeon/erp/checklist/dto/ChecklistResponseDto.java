package com.yeokjeon.erp.checklist.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChecklistResponseDto {

    private Integer chkIdx;
    private String brandCd;
    private String chkType;
    private String chkTypeNm;
    private String chkContent;
    private Integer baseScore;
    private Character useYn;
    private Integer displayOrder;
}
