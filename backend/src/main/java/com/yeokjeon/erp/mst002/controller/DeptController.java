package com.yeokjeon.erp.mst002.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.common.RequestMapUtil;
import com.yeokjeon.erp.mst002.service.DeptService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/dept")
@RequiredArgsConstructor
public class DeptController {

    private final DeptService deptService;

    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getDeptList() {
        log.info("부서 트리 목록 조회 요청");
        return ResponseEntity.ok(ApiResponse.success(deptService.getDeptTree()));
    }

    @PutMapping("/sort-order")
    public ResponseEntity<ApiResponse<Void>> updateSortOrder(
            @RequestBody Map<String, Object> body) {
        log.info("부서 정렬 순서 변경 요청: {}건", RequestMapUtil.optMapList(body, "items").size());
        deptService.updateSortOrder(body);
        return ResponseEntity.ok(ApiResponse.success("부서 순서가 변경되었습니다", null));
    }
}
