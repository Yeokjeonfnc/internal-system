package com.yeokjeon.erp.active.controller;

import com.yeokjeon.erp.active.dto.ActiveMstResponseDto;
import com.yeokjeon.erp.active.dto.ActiveMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ActivityStatusPivotRowDto;
import com.yeokjeon.erp.active.dto.ChkMstResponseDto;
import com.yeokjeon.erp.active.dto.ChkMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ChkResultRowDto;
import com.yeokjeon.erp.active.dto.NotifMstDto;
import com.yeokjeon.erp.active.service.ActService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** 활동·체크리스트·알림 — `/activities`, `/checklists`, `/notifications` 유지. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class ActController {

    private final ActService actService;

    @GetMapping("/activities/status/by-store")
    public ResponseEntity<ApiResponse<List<ActivityStatusPivotRowDto>>> statusByStore(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("가맹점별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                actService.statusByStore(startDt, endDt, brandCd)));
    }

    @GetMapping("/activities/status/by-assignee")
    public ResponseEntity<ApiResponse<List<ActivityStatusPivotRowDto>>> statusBySv(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("담당자별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                actService.statusBySv(startDt, endDt, brandCd)));
    }

    @GetMapping("/activities/list/all")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listAll() {
        log.info("활동관리 목록 조회: 전체");
        return ResponseEntity.ok(ApiResponse.success(actService.listAll()));
    }

    @GetMapping("/activities/list/by-store")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByStore(
            @RequestParam Integer storeIdx) {
        log.info("활동관리 목록 조회: 가맹점 storeIdx={}", storeIdx);
        return ResponseEntity.ok(ApiResponse.success(actService.listByStore(storeIdx)));
    }

    @GetMapping("/activities/list/by-appr-note")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByApprNote(
            @RequestParam String svId) {
        log.info("활동관리 목록 조회: 지시사항(메모·비결재대기) svId={}", svId);
        return ResponseEntity.ok(ApiResponse.success(actService.listBySvAppr(svId)));
    }

    @GetMapping("/activities/list/by-memo-notif")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByMemoNotifForApprover(
            @RequestParam String userId) {
        log.info("활동관리결재 목록 조회: 지시사항(메모·알림·결재선) userId={}", userId);
        return ResponseEntity.ok(ApiResponse.success(actService.listMemoInstructionsForApprover(userId)));
    }

    @GetMapping("/activities/list/by-suggestions")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listBySuggestionsOnly() {
        log.info("활동관리 목록 조회: 건의사항");
        return ResponseEntity.ok(ApiResponse.success(actService.listBySuggestions()));
    }

    @GetMapping("/activities/list/by-check")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByCheck(
            @RequestParam Character chkYn) {
        log.info("활동관리 목록 조회: chkYn={}", chkYn);
        return ResponseEntity.ok(ApiResponse.success(actService.listByChkYn(chkYn)));
    }

    @GetMapping("/activities/list/by-status")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByStatusOnly(
            @RequestParam String apprStatus,
            @RequestParam(required = false) String svId,
            @RequestParam(required = false) String relUserId) {
        log.info("활동관리 목록 조회: apprStatus={}, svId={}, relUserId={}", apprStatus, svId, relUserId);
        return ResponseEntity.ok(ApiResponse.success(
                actService.listByStatus(apprStatus, svId, relUserId)));
    }

    @GetMapping("/activities/{actIdx}")
    public ResponseEntity<ApiResponse<ActiveMstResponseDto>> activityOne(
            @PathVariable Integer actIdx) {
        log.info("활동관리 상세 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(actService.one(actIdx)));
    }

    @GetMapping("/activities/{actIdx}/checklist-results")
    public ResponseEntity<ApiResponse<List<ChkResultRowDto>>> chkResults(
            @PathVariable Integer actIdx) {
        log.info("활동관리 체크리스트 결과 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(actService.chkResults(actIdx)));
    }

    @PostMapping("/activities")
    public ResponseEntity<ApiResponse<ActiveMstResponseDto>> activityCreate(
            @RequestBody ActiveMstWriteRequestDto body) {
        log.info("활동관리 생성 요청");
        ActiveMstResponseDto created = actService.create(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("활동관리가 생성되었습니다", created));
    }

    @PutMapping("/activities/{actIdx}")
    public ResponseEntity<ApiResponse<ActiveMstResponseDto>> activityUpdate(
            @PathVariable Integer actIdx,
            @RequestBody ActiveMstWriteRequestDto body) {
        log.info("활동관리 수정 요청: {}", actIdx);
        ActiveMstResponseDto updated = actService.update(actIdx, body);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 수정되었습니다", updated));
    }

    @DeleteMapping("/activities/{actIdx}")
    public ResponseEntity<ApiResponse<Void>> activityRemove(@PathVariable Integer actIdx) {
        log.info("활동관리 삭제 요청: {}", actIdx);
        actService.remove(actIdx);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 삭제되었습니다", null));
    }

    @GetMapping("/checklists")
    public ResponseEntity<ApiResponse<List<ChkMstResponseDto>>> getChecklists(
            @RequestParam(required = false) String brandCd,
            @RequestParam(required = false) String chkType) {
        log.info("체크리스트 목록 조회 요청: brandCd={}, chkType={}", brandCd, chkType);
        return ResponseEntity.ok(ApiResponse.success(
                actService.getChecklists(brandCd, chkType)));
    }

    @PostMapping("/checklists")
    public ResponseEntity<ApiResponse<ChkMstResponseDto>> createChecklist(
            @Valid @RequestBody ChkMstWriteRequestDto body) {
        log.info("체크리스트 생성 요청: brandCd={}, chkType={}", body.brandCd(), body.chkType());
        ChkMstResponseDto created = actService.createChecklist(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(created));
    }

    @PutMapping("/checklists/{chkIdx}")
    public ResponseEntity<ApiResponse<ChkMstResponseDto>> updateChecklist(
            @PathVariable Integer chkIdx,
            @Valid @RequestBody ChkMstWriteRequestDto body) {
        log.info("체크리스트 수정 요청: chkIdx={}", chkIdx);
        ChkMstResponseDto updated = actService.updateChecklist(chkIdx, body);
        return ResponseEntity.ok(ApiResponse.success(updated));
    }

    @GetMapping("/notifications")
    public ResponseEntity<ApiResponse<List<NotifMstDto>>> notifList(
            @RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(actService.listForUser(userId)));
    }

    @GetMapping("/notifications/unread-count")
    public ResponseEntity<ApiResponse<Long>> notifUnreadCount(@RequestParam String userId) {
        return ResponseEntity.ok(ApiResponse.success(actService.countUnread(userId)));
    }

    @PatchMapping("/notifications/{notifIdx}/read")
    public ResponseEntity<ApiResponse<Void>> notifMarkRead(
            @PathVariable Long notifIdx,
            @RequestParam String userId) {
        actService.markRead(notifIdx, userId);
        return ResponseEntity.ok(ApiResponse.success("읽음 처리되었습니다.", null));
    }

    @PatchMapping("/notifications/activity-approval")
    public ResponseEntity<ApiResponse<Void>> notifAcknowledgeActivityApproval(
            @RequestParam String userId,
            @RequestParam Integer actIdx,
            @RequestParam(required = false) String apprNotes) {
        actService.markActivityApprovalAcknowledged(userId, actIdx, apprNotes);
        return ResponseEntity.ok(ApiResponse.success("결재 확인이 반영되었습니다.", null));
    }
}
