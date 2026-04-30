package com.yeokjeon.erp.checklist.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChecklistRequestDto {

    @NotBlank(message = "브랜드는 필수입니다")
    private String brandCd;

    @NotBlank(message = "구분은 필수입니다")
    private String chkType;

    @NotBlank(message = "체크항목은 필수입니다")
    private String chkContent;

    private Integer baseScore;
    private Character useYn;
}
