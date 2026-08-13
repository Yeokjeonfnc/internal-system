package com.yeokjeon.erp.master.service;

import com.yeokjeon.erp.exception.ResourceNotFoundException;
import com.yeokjeon.erp.master.dto.MenuMstDto;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.dto.UserMenuPermissionSaveRequestDto;
import com.yeokjeon.erp.master.entity.UserMenuAuth;
import com.yeokjeon.erp.master.mapper.MenuPermissionMapper;
import com.yeokjeon.erp.master.repository.MstUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MenuPermissionService {

    private final MenuPermissionMapper menuPermissionMapper;
    private final MstUserRepository mstUserRepository;

    @Value("${menu.permission.super-admin-user-ids:admin}")
    private String superAdminUserIds;

    public List<MenuMstDto> listMenus() {
        return menuPermissionMapper.selectActiveMenus();
    }

    public List<MenuPermissionDto> getUserPermissions(int userIdx) {
        ensureUserExists(userIdx);
        return menuPermissionMapper.selectPermissionsByUserIdx(userIdx);
    }

    /** 로그인 ID 로 내부 userIdx 를 찾는다. 없으면 null. */
    public Integer findUserIdx(String userId) {
        if (userId == null || userId.isBlank()) {
            return null;
        }
        return menuPermissionMapper.selectUserIdxByUserId(userId.trim());
    }

    public List<MenuPermissionDto> resolveForLogin(String userId) {
        if (!StringUtils.hasText(userId)) {
            return List.of();
        }
        try {
            if (isSuperAdmin(userId)) {
                return menuPermissionMapper.selectAllMenusAsGranted();
            }
            Integer userIdx = menuPermissionMapper.selectUserIdxByUserId(userId.trim());
            if (userIdx == null) {
                return List.of();
            }
            return menuPermissionMapper.selectPermissionsByUserIdx(userIdx);
        } catch (Exception e) {
            log.warn("로그인용 메뉴 권한 조회 실패: userId={}, {}", userId, e.getMessage());
            return List.of();
        }
    }

    @Transactional
    public void saveUserPermissions(int userIdx, UserMenuPermissionSaveRequestDto body) {
        ensureUserExists(userIdx);
        menuPermissionMapper.deleteByUserIdx(userIdx);
        if (body == null || body.items() == null) {
            return;
        }
        for (UserMenuPermissionSaveRequestDto.Item item : body.items()) {
            if (item == null || !StringUtils.hasText(item.menuCd())) {
                continue;
            }
            if (!item.canView() && !item.canCreate() && !item.canUpdate() && !item.canDelete()) {
                continue;
            }
            UserMenuAuth row = UserMenuAuth.builder()
                    .userIdx(userIdx)
                    .menuCd(item.menuCd().trim())
                    .canView(yn(item.canView()))
                    .canCreate(yn(item.canCreate()))
                    .canUpdate(yn(item.canUpdate()))
                    .canDelete(yn(item.canDelete()))
                    .build();
            menuPermissionMapper.insertUserMenuAuth(row);
        }
    }

    public boolean isSuperAdmin(String userId) {
        if (!StringUtils.hasText(userId)) {
            return false;
        }
        // 1순위: user_mst.admin_yn = 'Y'
        try {
            String adminYn = menuPermissionMapper.selectAdminYnByUserId(userId.trim());
            if (adminYn != null && "Y".equalsIgnoreCase(adminYn.trim())) {
                return true;
            }
        } catch (Exception e) {
            log.warn("admin_yn 조회 실패(컬럼 미적용 가능): userId={}, {}", userId, e.getMessage());
        }
        // 2순위(폴백): 설정값 menu.permission.super-admin-user-ids
        // 이 메서드는 로그인 경로에서 호출된다 — 설정이 비어 있어도 절대 터지면 안 된다.
        if (!StringUtils.hasText(superAdminUserIds)) {
            return false;
        }
        Set<String> ids = new HashSet<>();
        for (String part : superAdminUserIds.split(",")) {
            if (StringUtils.hasText(part)) {
                ids.add(part.trim().toLowerCase());
            }
        }
        return ids.contains(userId.trim().toLowerCase());
    }

    private void ensureUserExists(int userIdx) {
        mstUserRepository.findById(userIdx)
                .orElseThrow(() -> new ResourceNotFoundException("사용자", "userIdx", userIdx));
    }

    private static char yn(boolean value) {
        return value ? 'Y' : 'N';
    }
}
