package com.yeokjeon.erp.activity.dto;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActiveResponseDto {
    private Integer actIdx;
    private Integer storeIdx;
    private String storeNm;
    private String storeCd;
    private String brandCd;
    private String brandNm;
    private String actType;
    private LocalDate actDt;
    private LocalDateTime creatDt;
    private String actNotes;
    private String svId;
    private String apprStatus;
    private LocalDateTime apprDt;
    private String suggestions;
    private String svNotes;
    private Integer rChkId;
    private Character chkYn;
}
