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

    /*
     * 아래 2개는 "누가 무엇을 할 수 있는가" 지도다. 쓰기(PUT)만 잠그고 읽기를 열어 두면
     * 공격자가 mst001·mst003 권한을 가진 계정을 정확히 골라낼 수 있어(권한 상승 표적 정찰)
     * 쓰기에 건 기준과 어긋난다. 읽기에도 같은 mst003 권한을 요구한다.
     */

    @GetMapping("/menus")
    public ResponseEntity<ApiResponse<List<MenuMstDto>>> menus(HttpServletRequest request) {
        menuAccessGuard.ensure(
                MenuAccessGuard.callerId(request), MenuCodes.MST003, MenuAccessGuard.Action.VIEW);
        return ResponseEntity.ok(ApiResponse.success(menuPermissionService.listMenus()));
    }

    @GetMapping("/users/{userIdx}/menu-permissions")
    public ResponseEntity<ApiResponse<List<MenuPermissionDto>>> userMenuPermissions(
            @PathVariable int userIdx, HttpServletRequest request) {
        ensureCanReadPermissions(userIdx, request);
        log.info("사용자 메뉴 권한 조회: userIdx={}", userIdx);
        return ResponseEntity.ok(ApiResponse.success(menuPermissionService.getUserPermissions(userIdx)));
    }

    /**
     * 본인 권한만은 예외로 연다 — 화면이 로그인 직후 자기 권한을 다시 읽어
     * 버튼 노출을 맞추는 경로(mst004 등)가 있어, 막으면 그 화면이 조용히 깨진다.
     * 남의 것은 메뉴권한 관리(mst003) 조회 권한이 있어야 한다.
     */
    private void ensureCanReadPermissions(int userIdx, HttpServletRequest request) {
        String caller = MenuAccessGuard.callerId(request);
        Integer self = menuPermissionService.findUserIdx(caller);
        if (self != null && self.intValue() == userIdx) {
            return;
        }
        menuAccessGuard.ensure(caller, MenuCodes.MST003, MenuAccessGuard.Action.VIEW);
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
