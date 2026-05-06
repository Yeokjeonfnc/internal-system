package com.yeokjeon.erp.notification.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.ZonedDateTime;

@Entity
@Table(name = "notif_mst")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notif {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notif_idx")
    private Long notifIdx;

    @Column(name = "user_id", nullable = false, length = 50)
    private String userId;

    @Column(name = "msg_txt", nullable = false, length = 500)
    private String msgTxt;

    @Column(name = "notif_typ", length = 40)
    private String notifTyp;

    /** 활동 idx ([active_mst.act_idx]). */
    @Column(name = "act_idx")
    private Integer actIdx;

    /** 결재여부 알림 처리 여부 (기본 N, 결재하기 클릭 시 Y). DB 컬럼이 nullable 인 환경 호환. */
    @Column(name = "appr_yn", length = 2)
    private String apprYn;

    @Column(name = "read_yn", nullable = false, length = 1)
    private Character readYn;

    @Column(name = "creat_dt", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP")
    private ZonedDateTime creatDt;

    @PrePersist
    void prePersist() {
        if (readYn == null) {
            readYn = 'N';
        }
        if (apprYn == null || apprYn.isBlank()) {
            apprYn = "N";
        }
        if (creatDt == null) {
            creatDt = ZonedDateTime.now();
        }
    }
}
