package com.yeokjeon.erp.activity.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActivityStatusRowDto {

    private String storeNm;
    private String userId;
    private String userName;
    private LocalDate actDt;
    private Long count;
}
