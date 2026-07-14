package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.UsageLogMenuRequestDto;
import com.yeokjeon.erp.master.dto.UsageLogRowDto;
import com.yeokjeon.erp.master.dto.UsageLogTagRequestDto;
import com.yeokjeon.erp.master.service.UsageLogService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** 사용기록 — `/usage-logs`. */
@RestController
@RequiredArgsConstructor
public class UsageLogController {

    private final UsageLogService usageLogService;

    @GetMapping("/usage-logs")
    public ResponseEntity<ApiResponse<List<UsageLogRowDto>>> list(
            @RequestParam(required = false) String userNm,
            @RequestParam(required = false) String useType,
            @RequestParam(required = false, defaultValue = "ALL") String tab,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate startDt,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate endDt) {
        List<UsageLogRowDto> rows =
                usageLogService.list(userNm, useType, tab, startDt, endDt);
        return ResponseEntity.ok(ApiResponse.success(rows));
    }

    @GetMapping("/usage-logs/entry-tags")
    public ResponseEntity<ApiResponse<List<UsageLogRowDto>>> listEntryTagsForActivity(
            @RequestParam String userId,
            @RequestParam Integer storeIdx,
            @RequestParam(required = false, defaultValue = "true") boolean unlinkedOnly) {
        return ResponseEntity.ok(ApiResponse.success(
                usageLogService.listEntryTagsForActivity(userId, storeIdx, unlinkedOnly)));
    }

    @PostMapping("/usage-logs/menu")
    public ResponseEntity<ApiResponse<Void>> recordMenu(
            @Valid @RequestBody UsageLogMenuRequestDto body) {
        usageLogService.recordMenu(body);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/usage-logs/tag")
    public ResponseEntity<ApiResponse<Void>> recordTag(
            @Valid @RequestBody UsageLogTagRequestDto body) {
        usageLogService.recordTag(body);
        return ResponseEntity.ok(ApiResponse.success("출입등록되었습니다", null));
    }
}
