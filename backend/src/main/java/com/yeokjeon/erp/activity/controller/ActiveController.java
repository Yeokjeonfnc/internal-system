package com.yeokjeon.erp.activity.controller;

import com.yeokjeon.erp.activity.dto.ActiveRequestDto;
import com.yeokjeon.erp.activity.dto.ActiveResponseDto;
import com.yeokjeon.erp.activity.dto.ActivityStatusRowDto;
import com.yeokjeon.erp.activity.service.ActiveService;
import com.yeokjeon.erp.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/activities")
@RequiredArgsConstructor
public class ActiveController {

    private final ActiveService activeService;

    @GetMapping("/status/by-store")
    public ResponseEntity<ApiResponse<List<ActivityStatusRowDto>>> getStatusByStore(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("가맹점별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                activeService.getStatusByStore(startDt, endDt, brandCd)));
    }

    @GetMapping("/status/by-assignee")
    public ResponseEntity<ApiResponse<List<ActivityStatusRowDto>>> getStatusByAssignee(
            @RequestParam LocalDate startDt,
            @RequestParam LocalDate endDt,
            @RequestParam(required = false) String brandCd) {
        log.info("담당자별 활동 현황 조회 요청: startDt={}, endDt={}, brandCd={}", startDt, endDt, brandCd);
        return ResponseEntity.ok(ApiResponse.success(
                activeService.getStatusByAssignee(startDt, endDt, brandCd)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ActiveResponseDto>>> getAllActivities(
            @RequestParam(required = false) Integer storeIdx,
            @RequestParam(required = false) String apprStatus) {
        log.info("활동관리 목록 조회 요청");
        List<ActiveResponseDto> rows;
        if (storeIdx != null) {
            rows = activeService.getActivitiesByStore(storeIdx);
        } else if (apprStatus != null && !apprStatus.isBlank()) {
            rows = activeService.getActivitiesByStatus(apprStatus);
        } else {
            rows = activeService.getAllActivities();
        }
        return ResponseEntity.ok(ApiResponse.success(rows));
    }

    @GetMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<ActiveResponseDto>> getActivity(
            @PathVariable Integer actIdx) {
        log.info("활동관리 상세 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(activeService.getActivity(actIdx)));
    }

    @GetMapping("/{actIdx}/checklist-results")
    public ResponseEntity<ApiResponse<List<java.util.Map<String, Object>>>> getChecklistResults(
            @PathVariable Integer actIdx) {
        log.info("활동관리 체크리스트 결과 조회 요청: {}", actIdx);
        return ResponseEntity.ok(ApiResponse.success(activeService.getChecklistResults(actIdx)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ActiveResponseDto>> createActivity(
            @Valid @RequestBody ActiveRequestDto dto) {
        log.info("활동관리 생성 요청: storeIdx={}, actType={}", dto.getStoreIdx(), dto.getActType());
        ActiveResponseDto created = activeService.createActivity(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("활동관리가 생성되었습니다", created));
    }

    @PutMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<ActiveResponseDto>> updateActivity(
            @PathVariable Integer actIdx,
            @Valid @RequestBody ActiveRequestDto dto) {
        log.info("활동관리 수정 요청: {}", actIdx);
        ActiveResponseDto updated = activeService.updateActivity(actIdx, dto);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 수정되었습니다", updated));
    }

    @DeleteMapping("/{actIdx}")
    public ResponseEntity<ApiResponse<Void>> deleteActivity(@PathVariable Integer actIdx) {
        log.info("활동관리 삭제 요청: {}", actIdx);
        activeService.deleteActivity(actIdx);
        return ResponseEntity.ok(ApiResponse.success("활동관리가 삭제되었습니다", null));
    }
}
