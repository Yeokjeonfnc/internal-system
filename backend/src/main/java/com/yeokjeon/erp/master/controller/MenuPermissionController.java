package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.MenuMstDto;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.dto.UserMenuPermissionSaveRequestDto;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
public class MenuPermissionController {

    private final MenuPermissionService menuPermissionService;

    @GetMapping("/menus")
    public ResponseEntity<ApiResponse<List<MenuMstDto>>> menus() {
        return ResponseEntity.ok(ApiResponse.success(menuPermissionService.listMenus()));
    }

    @GetMapping("/users/{userIdx}/menu-permissions")
    public ResponseEntity<ApiResponse<List<MenuPermissionDto>>> userMenuPermissions(
            @PathVariable int userIdx) {
        log.info("사용자 메뉴 권한 조회: userIdx={}", userIdx);
        return ResponseEntity.ok(ApiResponse.success(menuPermissionService.getUserPermissions(userIdx)));
    }

    @PutMapping("/users/{userIdx}/menu-permissions")
    public ResponseEntity<ApiResponse<Void>> saveUserMenuPermissions(
            @PathVariable int userIdx,
            @Valid @RequestBody UserMenuPermissionSaveRequestDto body) {
        log.info("사용자 메뉴 권한 저장: userIdx={}, items={}",
                userIdx, body.items() != null ? body.items().size() : 0);
        menuPermissionService.saveUserPermissions(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("메뉴 권한이 저장되었습니다.", null));
    }
}
