package com.yeokjeon.erp.ntf001.service;

import com.yeokjeon.erp.act001.repository.Act001Repository;
import com.yeokjeon.erp.ntf001.entity.Notif;
import com.yeokjeon.erp.ntf001.repository.NotifRepository;
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
    private final Act001Repository act001Repository;

    public List<Map<String, Object>> listForUser(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        return notifRepository.findForUser(userId.trim())
                .stream()
                .map(this::toRow)
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
        act001Repository.findById(actIdx).ifPresent(active -> {
            active.setApprDt(LocalDateTime.now());
            active.setApprStatus("APPROVED");
            act001Repository.save(active);
        });
    }

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

    private Map<String, Object> toRow(Notif n) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("notifIdx", n.getNotifIdx());
        m.put("userId", n.getUserId());
        m.put("msgTxt", n.getMsgTxt());
        m.put("notifTyp", n.getNotifTyp());
        m.put("actIdx", n.getActIdx());
        m.put("apprYn", n.getApprYn());
        m.put("readYn", n.getReadYn() != null ? String.valueOf(n.getReadYn()) : null);
        m.put("creatDt", n.getCreatDt());
        return m;
    }
}
