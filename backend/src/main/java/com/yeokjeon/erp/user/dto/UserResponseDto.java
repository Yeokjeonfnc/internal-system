package com.yeokjeon.erp.user.dto;

import lombok.*;

import java.time.ZonedDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponseDto {

    private Integer userIdx;
    private String userName;
    private String userId;
    private Integer deptIdx;
    private String deptNm;
    private String userPhone;
    private String userEmail;
    private Character svYn;
    private String positionCd;
    private String positionNm;
    private Character tagYn;
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;
}
