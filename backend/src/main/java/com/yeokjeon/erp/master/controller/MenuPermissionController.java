package com.yeokjeon.erp.master.controller;

import com.yeokjeon.erp.auth.access.MenuAccessGuard;
import com.yeokjeon.erp.auth.access.MenuCodes;
import com.yeokjeon.erp.auth.token.AuthTokenFilter;
import com.yeokjeon.erp.common.ApiResponse;
import com.yeokjeon.erp.master.dto.MenuMstDto;
import jakarta.servlet.http.HttpServletRequest;
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
    private final MenuAccessGuard menuAccessGuard;

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

    /**
     * 권한 부여는 곧 권한 상승 경로다 — 검사가 없으면 로그인한 아무 직원이나
     * 자기 자신에게 전 메뉴 권한을 줄 수 있다. 메뉴권한 관리(mst003) 권한을 요구한다.
     */
    @PutMapping("/users/{userIdx}/menu-permissions")
    public ResponseEntity<ApiResponse<Void>> saveUserMenuPermissions(
            @PathVariable int userIdx,
            @Valid @RequestBody UserMenuPermissionSaveRequestDto body,
            HttpServletRequest request) {
        Object caller = request.getAttribute(AuthTokenFilter.ATTR_CURRENT_USER_ID);
        menuAccessGuard.ensure(
                caller == null ? null : caller.toString(),
                MenuCodes.MST003,
                MenuAccessGuard.Action.UPDATE);
        log.info("사용자 메뉴 권한 저장: userIdx={}, items={}",
                userIdx, body.items() != null ? body.items().size() : 0);
        menuPermissionService.saveUserPermissions(userIdx, body);
        return ResponseEntity.ok(ApiResponse.success("메뉴 권한이 저장되었습니다.", null));
    }
}
