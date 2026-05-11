package com.yeokjeon.erp.active.dto;

import com.yeokjeon.erp.active.entity.ActNotif;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;

/** {@code notif_mst} 목록 행 — 기존 알림 API Map 키와 동일. */
public record NotifMstDto(
        Long notifIdx,
        String userId,
        String msgTxt,
        String notifTyp,
        Integer actIdx,
        String apprYn,
        String readYn,
        LocalDateTime createDt) {

    public static NotifMstDto fromEntity(ActNotif n) {
        ZonedDateTime z = n.getCreateDt();
        return new NotifMstDto(
                n.getNotifIdx(),
                n.getUserId(),
                n.getMsgTxt(),
                n.getNotifTyp(),
                n.getActIdx(),
                n.getApprYn(),
                n.getReadYn() != null ? String.valueOf(n.getReadYn()) : null,
                z == null ? null : z.toLocalDateTime());
    }
}
