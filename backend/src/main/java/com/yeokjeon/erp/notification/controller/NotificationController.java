package com.yeokjeon.erp.notification.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.notification.dto.NotifResponseDto;
import com.yeokjeon.erp.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotifResponseDto>>> list(
            @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(notificationService.listForUser(userId)));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> unreadCount(@RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(notificationService.countUnread(userId)));
    }

    @PatchMapping("/{notifIdx}/read")
    public ResponseEntity<ApiResponse<Void>> markRead(
            @PathVariable Long notifIdx,
            @RequestParam String userId) {
        notificationService.markRead(notifIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("읽음 처리되었습니다.", null));
    }

    @PatchMapping("/activity-approval")
    public ResponseEntity<ApiResponse<Void>> acknowledgeActivityApproval(
            @RequestParam String userId,
            @RequestParam Integer actIdx) {
        notificationService.markActivityApprovalAcknowledged(userId, actIdx);
        return ResponseEntity.ok(ApiResponse.success("결재 확인이 반영되었습니다.", null));
    }
}
