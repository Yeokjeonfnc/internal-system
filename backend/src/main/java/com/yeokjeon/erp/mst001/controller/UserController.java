package com.yeokjeon.erp.mst001.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.mst001.service.Emp001Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final Emp001Service emp001Service;

    @GetMapping("/check-user-id")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkUserId(
            @RequestParam String userId) {
        boolean available = emp001Service.free(userId);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("available", available);
        return ResponseEntity.ok(ApiResponse.success(body));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) Integer deptIdx) {
        List<Map<String, Object>> users = emp001Service.getAll(deptIdx);
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> one(@PathVariable Integer userIdx) {
        Map<String, Object> user = emp001Service.get(userIdx);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@RequestBody Map<String, Object> body) {
        Map<String, Object> created = emp001Service.save(body);
        return ResponseEntity.ok(ApiResponse.success("사용자가 생성되었습니다.", created));
    }

    @PutMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> update(
            @PathVariable Integer userIdx,
            @RequestBody Map<String, Object> body) {
        Map<String, Object> updated = emp001Service.save(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("사용자가 수정되었습니다.", updated));
    }

    @DeleteMapping("/{userIdx}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Integer userIdx) {
        emp001Service.remove(userIdx);
        return ResponseEntity.ok(ApiResponse.success("사용자가 삭제되었습니다.", null));
    }
}
