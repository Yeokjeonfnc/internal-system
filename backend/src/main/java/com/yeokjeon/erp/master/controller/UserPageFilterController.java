package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.UserPageFilterDto;
import com.yeokjeon.erp.master.dto.UserPageFilterSaveRequestDto;
import com.yeokjeon.erp.master.service.UserPageFilterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user-page-filters")
@RequiredArgsConstructor
public class UserPageFilterController {

    private final UserPageFilterService userPageFilterService;

    @GetMapping
    public ResponseEntity<ApiResponse<UserPageFilterDto>> get(
            @RequestParam String userId,
            @RequestParam String pageCode) {
        return ResponseEntity.ok(ApiResponse.success(userPageFilterService.get(userId, pageCode)));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<UserPageFilterDto>> save(
            @RequestParam String userId,
            @Valid @RequestBody UserPageFilterSaveRequestDto body) {
        return ResponseEntity.ok(ApiResponse.success("필터가 저장되었습니다.", userPageFilterService.save(userId, body)));
    }
}
