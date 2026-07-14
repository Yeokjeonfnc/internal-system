package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.auth.dto.AuthLoginRequestDto;
import com.yeokjeon.erp.auth.dto.AuthProfileDto;
import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import com.yeokjeon.erp.auth.mapper.AuthProfileMapper;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import com.yeokjeon.erp.master.service.UsageLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthProfileMapper authProfileMapper;
    private final MenuPermissionService menuPermissionService;
    private final UsageLogService usageLogService;

    public AuthProfileDto login(AuthLoginRequestDto body) {
        String userId = body.userId();
        String userPassword = body.userPassword();
        try {
            AuthProfileRowDto row =
                    authProfileMapper.selectByUserIdAndPassword(userId, userPassword);
            if (row == null) {
                return null;
            }
            usageLogService.recordLogin(row);
            List<MenuPermissionDto> menuPermissions = loadMenuPermissionsSafely(userId);
            AuthProfileDto profile = AuthProfileDto.fromRow(row, menuPermissions);
            // admin_yn 컬럼 또는 config 폴백 — 프론트가 관리자 여부를 일관되게 받도록 보정
            return menuPermissionService.isSuperAdmin(userId)
                    ? profile.withAdminYn("Y")
                    : profile;
        } catch (Exception e) {
            log.error("로그인 실패: userId={}", userId, e);
            return null;
        }
    }

    @Transactional
    public AuthProfileDto updateUserProfile(String userId, AuthProfileUpdateRequestDto body) {
        int updated = authProfileMapper.updateProfile(userId, body);

        if (updated > 0) {
            log.info("사용자 정보 수정 완료: userId={}", userId);
            return getUserProfile(userId);
        }

        log.error("사용자 정보 수정 실패: userId={}", userId);
        return null;
    }

    public AuthProfileDto getUserProfile(String userId) {
        try {
            AuthProfileRowDto row = authProfileMapper.selectByUserId(userId);
            return row == null ? null : AuthProfileDto.fromRow(row, List.of());
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패: userId={}, error={}", userId, e.getMessage());
            return null;
        }
    }

    /** 메뉴 테이블 미적용·조회 오류 시 빈 목록 — 로그인 자체는 성공시킨다. */
    private List<MenuPermissionDto> loadMenuPermissionsSafely(String userId) {
        try {
            return menuPermissionService.resolveForLogin(userId);
        } catch (Exception e) {
            log.warn(
                    "메뉴 권한 조회 생략( menu_mst / user_menu_auth 미적용 가능 ): userId={}, {}",
                    userId,
                    e.getMessage());
            return List.of();
        }
    }

}
