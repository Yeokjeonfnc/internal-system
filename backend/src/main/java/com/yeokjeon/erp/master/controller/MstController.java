package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.DeptMstNodeDto;
import com.yeokjeon.erp.master.dto.DeptSortOrderUpdateRequestDto;
import com.yeokjeon.erp.master.dto.UserIdAvailabilityDto;
import com.yeokjeon.erp.master.dto.UserMstCreateRequestDto;
import com.yeokjeon.erp.master.dto.UserMstDto;
import com.yeokjeon.erp.master.dto.UserMstUpdateRequestDto;
import com.yeokjeon.erp.master.service.MstService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 사원·부서 — `/users`, `/dept` 유지. */
@Slf4j
@RestController
@RequiredArgsConstructor
public class MstController {

    private final MstService mstService;

    @GetMapping("/users/check-user-id")
    public ResponseEntity<ApiResponse<UserIdAvailabilityDto>> checkUserId(
            @RequestParam String userId) {
        boolean available = mstService.isUserIdAvailable(userId);
        return ResponseEntity.ok(ApiResponse.success(new UserIdAvailabilityDto(available)));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserMstDto>>> userList(
            @RequestParam(required = false) Integer deptIdx) {
        List<UserMstDto> users = mstService.getAll(deptIdx);
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<UserMstDto>> userOne(@PathVariable Integer userIdx) {
        UserMstDto user = mstService.get(userIdx);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PostMapping("/users")
    public ResponseEntity<ApiResponse<UserMstDto>> userCreate(@Valid @RequestBody UserMstCreateRequestDto body) {
        UserMstDto created = mstService.save(body);
        return ResponseEntity.ok(ApiResponse.success("사용자가 생성되었습니다.", created));
    }

    @PutMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<UserMstDto>> userUpdate(
            @PathVariable Integer userIdx,
            @RequestBody UserMstUpdateRequestDto body) {
        UserMstDto updated = mstService.save(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("사용자가 수정되었습니다.", updated));
    }

    @DeleteMapping("/users/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> userDelete(@PathVariable Integer userIdx) {
        mstService.remove(userIdx);
        return ResponseEntity.ok(ApiResponse.success("사용자가 삭제되었습니다.", null));
    }

    @GetMapping("/dept/list")
    public ResponseEntity<ApiResponse<List<DeptMstNodeDto>>> deptList() {
        log.info("부서 트리 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(mstService.getDeptTree()));
    }

    @PutMapping("/dept/sort-order")
    public ResponseEntity<ApiResponse<Void>> deptSortOrder(
            @Valid @RequestBody DeptSortOrderUpdateRequestDto body) {
        log.info("부서 정렬 순서 변경 요청: {}건", body.items() != null ? body.items().size() : 0);
        mstService.updateSortOrder(body);
        return ResponseEntity.ok(ApiResponse.success("부서 순서가 변경되었습니다", null));
    }
}
