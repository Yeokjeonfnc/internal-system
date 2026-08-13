package com.yeokjeon.erp.active.controller;

import com.yeokjeon.erp.active.dto.ActiveMstResponseDto;
import com.yeokjeon.erp.active.dto.ActiveMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ActivityStatusPivotRowDto;
import com.yeokjeon.erp.active.dto.ChkMstResponseDto;
import com.yeokjeon.erp.active.dto.ChkMstWriteRequestDto;
import com.yeokjeon.erp.active.dto.ChkResultRowDto;
import com.yeokjeon.erp.active.dto.NotifMstDto;
import com.yeokjeon.erp.active.dto.ActAttachmentDto;
import com.yeokjeon.erp.active.service.ActAttachmentService;
import com.yeokjeon.erp.active.service.ActService;
import com.yeokjeon.erp.active.service.ActSignatureService;
import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;

import java.time.LocalDate;
import java.util.List;

/** 활동·체크리스트·알림 — `/activities`, `/checklists`, `/notifications` 유지. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class ActController {

    private final ActService actService;
    private final ActSignatureService actSignatureService;
    private final ActAttachmentService actAttachmentService;
    private final MenuAccessGuard menuAccessGuard;

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

    @GetMapping("/activities/list/by-store-appr-note")
    public ResponseEntity<ApiResponse<List<ActiveMstResponseDto>>> listByStoreApprNote(
            @RequestParam Integer storeIdx) {
        log.info("활동관리 목록 조회: 가맹점 지시사항 storeIdx={}", storeIdx);
        return ResponseEntity.ok(ApiResponse.success(actService.listByStoreApprMemo(storeIdx)));
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

    @GetMapping("/activities/{actIdx}/attachments")
    public ResponseEntity<ApiResponse<List<ActAttachmentDto>>> listAttachments(
            @PathVariable Integer actIdx) {
        log.info("활동 첨부 목록 조회: actIdx={}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(actAttachmentService.list(actIdx)));
    }

    /*
     * 첨부는 남의 활동 건에도 붙일 수 있다(actIdx 만 알면 된다). 권한 검사가 없으면
     * 로그인한 아무나 임의의 활동에 파일을 끼워 넣거나 증빙을 지울 수 있으므로
     * 활동 등록(act002) 권한을 요구한다.
     */

    @PostMapping(value = "/activities/{actIdx}/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<ActAttachmentDto>> uploadAttachment(
            @PathVariable Integer actIdx,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) String userId,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.CREATE);
        log.info("활동 첨부 업로드: actIdx={}, file={}", actIdx, file.getOriginalFilename());
        ActAttachmentDto created = actAttachmentService.upload(actIdx, file, userId);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("첨부파일이 업로드되었습니다", created));
    }

    @GetMapping("/activities/{actIdx}/attachments/{actAttIdx}/download")
    public ResponseEntity<org.springframework.core.io.Resource> downloadAttachment(
            @PathVariable Integer actIdx,
            @PathVariable Integer actAttIdx) {
        ActAttachmentService.DownloadPayload payload =
                actAttachmentService.download(actIdx, actAttIdx);
        return fileDownloadResponse(payload);
    }

    @DeleteMapping("/activities/{actIdx}/attachments/{actAttIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteAttachment(
            @PathVariable Integer actIdx,
            @PathVariable Integer actAttIdx,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.DELETE);
        log.info("활동 첨부 삭제: actIdx={}, attIdx={}", actIdx, actAttIdx);
        actAttachmentService.delete(actIdx, actAttIdx);
        return ResponseEntity.ok(ApiResponse.success("첨부파일이 삭제되었습니다", null));
    }

    /*
     * 전자서명은 "가맹점주가 이 활동 내용을 확인했다"는 증거로 쓰인다. 호출자를 전혀
     * 확인하지 않으면 actIdx 만 알아도 남의 활동 건에 임의의 서명 이미지를 덮어쓸 수
     * 있다(서명 위조). 활동 등록(act002) 권한을 요구한다.
     */
    @PostMapping(value = "/activities/{actIdx}/signature", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Void>> uploadSignature(
            @PathVariable Integer actIdx,
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.CREATE);
        log.info("활동 전자서명 업로드: actIdx={}", actIdx);
        actSignatureService.upload(actIdx, file);
        return ResponseEntity.ok(ApiResponse.success("전자서명이 저장되었습니다", null));
    }

    @GetMapping("/activities/{actIdx}/signature")
    public ResponseEntity<org.springframework.core.io.Resource> downloadSignature(
            @PathVariable Integer actIdx) {
        ActSignatureService.DownloadPayload payload = actSignatureService.download(actIdx);
        return fileDownloadResponse(payload);
    }

    private ResponseEntity<org.springframework.core.io.Resource> fileDownloadResponse(
            ActAttachmentService.DownloadPayload payload) {
        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (payload.contentType() != null && !payload.contentType().isBlank()) {
            mediaType = MediaType.parseMediaType(payload.contentType());
        }
        ContentDisposition disposition = ContentDisposition.attachment()
                .filename(payload.fileName(), StandardCharsets.UTF_8)
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .contentType(mediaType)
                .body(payload.resource());
    }

    private ResponseEntity<org.springframework.core.io.Resource> fileDownloadResponse(
            ActSignatureService.DownloadPayload payload) {
        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (payload.contentType() != null && !payload.contentType().isBlank()) {
            mediaType = MediaType.parseMediaType(payload.contentType());
        }
        ContentDisposition disposition = ContentDisposition.inline()
                .filename(payload.fileName(), StandardCharsets.UTF_8)
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .contentType(mediaType)
                .body(payload.resource());
    }

    /*
     * 활동 기록은 가맹점 방문 이력·결재의 원본이다. 로그인만 하면 누구나 남의 활동을
     * 고치거나 지울 수 있었으므로 활동 등록(act002) 권한을 요구한다.
     */

    @PostMapping("/activities")
    public ResponseEntity<ApiResponse<ActiveMstResponseDto>> activityCreate(
            @RequestBody ActiveMstWriteRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.CREATE);
        log.info("활동관리 생성 요청");
        ActiveMstResponseDto created = actService.create(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("활동관리가 생성되었습니다", created));
    }

    @PutMapping("/activities/{actIdx}")
    public ResponseEntity<ApiResponse<ActiveMstResponseDto>> activityUpdate(
            @PathVariable Integer actIdx,
            @RequestBody ActiveMstWriteRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.UPDATE);
        log.info("활동관리 수정 요청: {}", actIdx);
        ActiveMstResponseDto updated = actService.update(actIdx, body);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 수정되었습니다", updated));
    }

    @DeleteMapping("/activities/{actIdx}")
    public ResponseEntity<ApiResponse<Void>> activityRemove(
            @PathVariable Integer actIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT002, MenuAccessGuard.Action.DELETE);
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

    /*
     * 체크리스트는 전 가맹점 점검 항목의 기준 마스터다. 항목을 바꾸거나 지우면 이후
     * 모든 활동 점검 결과가 함께 흔들리므로 체크리스트 관리(mst004) 권한을 요구한다.
     */

    @PostMapping("/checklists")
    public ResponseEntity<ApiResponse<ChkMstResponseDto>> createChecklist(
            @Valid @RequestBody ChkMstWriteRequestDto body, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.MST004, MenuAccessGuard.Action.CREATE);
        log.info("체크리스트 생성 요청: brandCd={}, chkType={}", body.brandCd(), body.chkType());
        ChkMstResponseDto created = actService.createChecklist(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(created));
    }

    @PutMapping("/checklists/{chkIdx}")
    public ResponseEntity<ApiResponse<ChkMstResponseDto>> updateChecklist(
            @PathVariable Integer chkIdx,
            @Valid @RequestBody ChkMstWriteRequestDto body,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.MST004, MenuAccessGuard.Action.UPDATE);
        log.info("체크리스트 수정 요청: chkIdx={}", chkIdx);
        ChkMstResponseDto updated = actService.updateChecklist(chkIdx, body);
        return ResponseEntity.ok(ApiResponse.success(updated));
    }

    @DeleteMapping("/checklists/{chkIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteChecklist(
            @PathVariable Integer chkIdx, HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.MST004, MenuAccessGuard.Action.DELETE);
        log.info("체크리스트 삭제 요청: chkIdx={}", chkIdx);
        actService.deleteChecklist(chkIdx);
        return ResponseEntity.ok(ApiResponse.success("체크리스트가 삭제되었습니다", null));
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

    @PatchMapping("/notifications/read-all")
    public ResponseEntity<ApiResponse<Void>> notifMarkAllRead(@RequestParam String userId) {
        actService.markAllRead(userId);
        return ResponseEntity.ok(ApiResponse.success("모든 알림을 읽음 처리했습니다.", null));
    }

    /*
     * 경로는 `/notifications` 지만 실제로는 결재 행위 그 자체다 — 활동 건의
     * appr_status 를 APPROVED 로 바꾸고 appr_notes(지시사항)를 덮어쓴다. 즉 내 알림이
     * 아니라 기안자의 데이터를 바꾸는 작업이라 활동관리결재(act003) 권한을 요구한다.
     * (위 읽음처리들과 달리 userId 대조만으로는 부족하다.)
     */
    @PatchMapping("/notifications/activity-approval")
    public ResponseEntity<ApiResponse<Void>> notifAcknowledgeActivityApproval(
            @RequestParam String userId,
            @RequestParam Integer actIdx,
            @RequestParam(required = false) String apprNotes,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.ACT003, MenuAccessGuard.Action.UPDATE);
        actService.markActivityApprovalAcknowledged(userId, actIdx, apprNotes);
        return ResponseEntity.ok(ApiResponse.success("결재 확인이 반영되었습니다.", null));
    }
}
