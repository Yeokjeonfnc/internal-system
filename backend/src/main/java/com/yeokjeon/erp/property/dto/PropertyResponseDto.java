package com.yeokjeon.erp.property.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PropertyResponseDto {
    private Integer propIdx;
    private String propNm;
    private String zipCd;
    private String address;
    private String addressDetail;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String region;
    private String propStatus;
    private String propType;
    private Integer floor;
    private BigDecimal contArea;
    private BigDecimal realArea;
    private Long rentDeposit;
    private Long monthlyRent;
    private Long premiumFee;
    private Long maintFee;
    private String propNotes;
    private LocalDate surveyDt;
    private LocalDateTime createDt;
    private LocalDateTime updateDt;
    private String surveyor;
}
