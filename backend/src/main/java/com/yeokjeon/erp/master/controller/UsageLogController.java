package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.AccessDeniedException;
import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.UsageLogMenuRequestDto;
import jakarta.servlet.http.HttpServletRequest;
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
    private final MenuAccessGuard menuAccessGuard;

    /**
     * 전 직원의 메뉴 사용 이력과 가맹점 출입 태그(GPS 좌표 포함)가 그대로 나온다.
     * 사실상 위치 추적 자료이므로 사용기록 조회(mst005) 권한을 요구한다.
     */
    @GetMapping("/usage-logs")
    public ResponseEntity<ApiResponse<List<UsageLogRowDto>>> list(
            @RequestParam(required = false) String userNm,
            @RequestParam(required = false) String useType,
            @RequestParam(required = false, defaultValue = "ALL") String tab,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate startDt,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate endDt,
            HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.MST005, MenuAccessGuard.Action.VIEW);
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

    /*
     * 사용기록은 감사(audit) 자료다. 신분을 요청 본문(userId)에서 받으면
     * AuthTokenFilter 의 파라미터 검사가 닿지 않아 **남의 이름으로 기록을 남길 수** 있다.
     * 본문 값이 토큰 주인과 다르면 거부한다.
     */

    @PostMapping("/usage-logs/menu")
    public ResponseEntity<ApiResponse<Void>> recordMenu(
            @Valid @RequestBody UsageLogMenuRequestDto body, HttpServletRequest request) {
        ensureSelf(request, body.userId());
        usageLogService.recordMenu(body);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/usage-logs/tag")
    public ResponseEntity<ApiResponse<Void>> recordTag(
            @Valid @RequestBody UsageLogTagRequestDto body, HttpServletRequest request) {
        ensureSelf(request, body.userId());
        usageLogService.recordTag(body);
        return ResponseEntity.ok(ApiResponse.success("출입등록되었습니다", null));
    }

    /** 본문에 실린 userId 가 토큰 주인과 같은지 확인한다. */
    private static void ensureSelf(HttpServletRequest request, String bodyUserId) {
        Object caller = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        if (caller == null || bodyUserId == null || !caller.toString().equals(bodyUserId.trim())) {
            throw new AccessDeniedException("다른 사용자의 이름으로 기록할 수 없습니다.");
        }
    }
}
