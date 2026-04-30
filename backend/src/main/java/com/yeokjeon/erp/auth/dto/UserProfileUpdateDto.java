package com.yeokjeon.erp.auth.dto;

import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileUpdateDto {
    private String userName;
    private String userPassword;  // 변경할 비밀번호 (선택적)
    private Integer deptIdx;
    private String userPhone;
    private LocalDate joinDt;
    private Character svYn;
    private String positionCd;
    private Character tagYn;
}
