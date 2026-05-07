package com.yeokjeon.erp.act001.controller;

import com.yeokjeon.erp.act001.service.Act001Service;
import com.yeokjeon.erp.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/activities")
@RequiredArgsConstructor
public class Act001Controller {

    private final Act001Service act001Service;

    @GetMapping("/status/by-store")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getStatusByStore(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("가맹점별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                act001Service.getStatusByStore(startDt, endDt, brandCd)));
    }

    @GetMapping("/status/by-assignee")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getStatusByAssignee(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("담당자별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                act001Service.getStatusByAssignee(startDt, endDt, brandCd)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllActivities(
            @RequestParam(required = false) Integer storeIdx,
            @RequestParam(required = false) String apprStatus,
            @RequestParam(required = false) String svId,
            @RequestParam(required = false) String relUserId,
            @RequestParam(required = false) Character chkYn,
            @RequestParam(required = false) Boolean hasSuggestions) {
        log.info("활동관리 목록 조회 요청: apprStatus={}, svId={}, relUserId={}, chkYn={}, hasSuggestions={}",
                apprStatus, svId, relUserId, chkYn, hasSuggestions);
        List<Map<String, Object>> rows;
        if (storeIdx != null) {
            rows = act001Service.getActivitiesByStore(storeIdx);
        } else if (Boolean.TRUE.equals(hasSuggestions)) {
            rows = act001Service.getApprovedActivitiesWithSuggestions();
        } else if (chkYn != null) {
            rows = act001Service.getActivitiesByChecklistYn(chkYn);
        } else if (apprStatus != null && !apprStatus.isBlank()) {
            rows = act001Service.getActivitiesByStatus(apprStatus, svId, relUserId);
        } else {
            rows = act001Service.getAllActivities();
        }
        return ResponseEntity.ok(ApiResponse.success(rows));
    }

    @GetMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getActivity(
            @PathVariable Integer actIdx) {
        log.info("활동관리 상세 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(act001Service.getActivity(actIdx)));
    }

    @GetMapping("/{actIdx}/checklist-results")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getChecklistResults(
            @PathVariable Integer actIdx) {
        log.info("활동관리 체크리스트 결과 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(act001Service.getChecklistResults(actIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createActivity(
            @RequestBody Map<String, Object> body) {
        log.info("활동관리 생성 요청: body keys={}", body != null ? body.keySet() : null);
        Map<String, Object> created = act001Service.createActivity(body);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("활동관리가 생성되었습니다", created));
    }

    @PutMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateActivity(
            @PathVariable Integer actIdx,
            @RequestBody Map<String, Object> body) {
        log.info("활동관리 수정 요청: {}", actIdx);
        Map<String, Object> updated = act001Service.updateActivity(actIdx, body);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 수정되었습니다", updated));
    }

    @DeleteMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteActivity(@PathVariable Integer actIdx) {
        log.info("활동관리 삭제 요청: {}", actIdx);
        act001Service.deleteActivity(actIdx);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 삭제되었습니다", null));
    }
}
