package com.yeokjeon.erp.notification.service;

import com.yeokjeon.erp.activity.repository.ActiveRepository;
import com.yeokjeon.erp.notification.dto.NotifResponseDto;
import com.yeokjeon.erp.notification.entity.Notif;
import com.yeokjeon.erp.notification.repository.NotifRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private static final String TYPE_ACTIVITY_APPROVAL = "ACTIVITY_APPROVAL";

    private final NotifRepository notifRepository;
    private final ActiveRepository activeRepository;

    public List<NotifResponseDto> listForUser(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        return notifRepository.findForUser(userId.trim())
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public long countUnread(String userId) {
        if (userId == null || userId.isBlank()) {
            return 0;
        }
        return notifRepository.countByUserIdAndReadYn(userId.trim(), 'N');
    }

    @Transactional(readOnly = false)
    public void markRead(Long notifIdx, String userId) {
        if (notifIdx == null || userId == null || userId.isBlank()) {
            return;
        }
        notifRepository.findById(notifIdx).ifPresent(n -> {
            if (userId.trim().equals(n.getUserId())) {
                n.setReadYn('Y');
                notifRepository.save(n);
            }
        });
    }

    /**
     * 활동 결재 화면에서 [결재하기] 클릭 시: 결재 알림 appr_yn=Y, active_mst.appr_status=APPROVED·appr_dt 갱신.
     * 알림 행이 없으면(구데이터·알림 누락) 결재 확인 행을 새로 넣어 상세 조회 시 반영되게 한다.
     */
    @Transactional(readOnly = false)
    public void markActivityApprovalAcknowledged(String userId, Integer actIdx) {
        if (userId == null || userId.isBlank() || actIdx == null) {
            return;
        }
        String uid = userId.trim();
        List<Notif> rows = notifRepository.findByUserIdAndActIdxAndNotifTyp(uid, actIdx, TYPE_ACTIVITY_APPROVAL);
        if (rows.isEmpty()) {
            Notif ack = Notif.builder()
                    .userId(uid)
                    .msgTxt("활동 결재 확인")
                    .notifTyp(TYPE_ACTIVITY_APPROVAL)
                    .actIdx(actIdx)
                    .apprYn("Y")
                    .readYn('Y')
                    .build();
            notifRepository.save(ack);
        } else {
            for (Notif n : rows) {
                n.setApprYn("Y");
                notifRepository.save(n);
            }
        }
        activeRepository.findById(actIdx).ifPresent(active -> {
            active.setApprDt(LocalDateTime.now());
            active.setApprStatus("APPROVED");
            activeRepository.save(active);
        });
    }

    /** 활동별 결재 확인 완료(notif appr_yn=Y) 사용자 → 표시 일자(yyyy-MM-dd). DB에 별도 확인 시각 컬럼이 없으므로 creat_dt 기준. */
    public Map<String, String> approvalAckDateMapForActivity(Integer actIdx) {
        if (actIdx == null) {
            return Map.of();
        }
        List<Notif> rows = notifRepository.findByActIdxAndNotifTypAndApprYnOrderByNotifIdxAsc(
                actIdx, TYPE_ACTIVITY_APPROVAL, "Y");
        Map<String, String> out = new LinkedHashMap<>();
        for (Notif n : rows) {
            String uid = n.getUserId();
            if (uid == null || uid.isBlank()) {
                continue;
            }
            ZonedDateTime ts = n.getCreatDt();
            String day = ts != null ? ts.toLocalDate().toString() : "";
            out.put(uid.trim(), day);
        }
        return out;
    }

    /**
     * 활동 상신(PENDING) 시 결재자(본인 제외로 클라이언트에서 넘어온 목록)에게 알림 저장.
     */
    @Transactional(readOnly = false)
    public void notifyActivityApprovers(Integer actIdx, List<String> apprUserIds) {
        if (actIdx == null || apprUserIds == null || apprUserIds.isEmpty()) {
            return;
        }
        LinkedHashSet<String> distinct = new LinkedHashSet<>();
        for (String raw : apprUserIds) {
            if (raw == null) {
                continue;
            }
            String id = raw.trim();
            if (!id.isEmpty()) {
                distinct.add(id);
            }
        }
        if (distinct.isEmpty()) {
            return;
        }

        String msg = "결재자에 추가되었습니다. 결재 대기 중인 활동내역이 있습니다.";
        for (String uid : distinct) {
            Notif n = Notif.builder()
                    .userId(uid)
                    .msgTxt(msg)
                    .notifTyp(TYPE_ACTIVITY_APPROVAL)
                    .actIdx(actIdx)
                    .apprYn("N")
                    .build();
            notifRepository.save(n);
        }
    }

    private NotifResponseDto toDto(Notif n) {
        return NotifResponseDto.builder()
                .notifIdx(n.getNotifIdx())
                .userId(n.getUserId())
                .msgTxt(n.getMsgTxt())
                .notifTyp(n.getNotifTyp())
                .actIdx(n.getActIdx())
                .apprYn(n.getApprYn())
                .readYn(n.getReadYn())
                .creatDt(n.getCreatDt())
                .build();
    }
}
