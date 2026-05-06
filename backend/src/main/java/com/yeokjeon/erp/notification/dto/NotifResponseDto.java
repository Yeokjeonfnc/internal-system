package com.yeokjeon.erp.notification.dto;

import lombok.*;

import java.time.ZonedDateTime;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotifResponseDto {
    private Long notifIdx;
    private String userId;
    private String msgTxt;
    private String notifTyp;
    private Integer actIdx;
    private String apprYn;
    private Character readYn;
    private ZonedDateTime creatDt;
}
