package com.yeokjeon.erp.auth.dto;

import lombok.*;
import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponseDto {
    private String userId;
    private String userNm;
    private String email;
    private Integer deptIdx;
    private String userPhone;
    private String deptNm;
    private String positionCd;
    private String positionNm;
    private Character svYn;
    private Character tagYn;
    private LocalDate joinDt;
}
