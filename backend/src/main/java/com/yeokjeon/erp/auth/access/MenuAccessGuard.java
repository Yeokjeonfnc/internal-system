package com.yeokjeon.erp.auth.access;

import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 메뉴 단위 권한 검사 — 민감한 쓰기 작업에 사용한다.
 *
 * <p>{@code AuthTokenFilter} 는 "로그인했는가 / 남의 ID 를 사칭하지 않는가"까지만 본다.
 * 그래서 로그인만 하면 사원 계정 수정·메뉴권한 부여 같은 관리 기능을 누구나 호출할 수
 * 있었다(권한 상승). 이 가드가 "그 메뉴에 대한 권한이 있는가"를 추가로 확인한다.
 *
 * <p>판정 기준은 기존 체계를 그대로 따른다 — 슈퍼관리자({@code admin_yn='Y'} 또는
 * 설정의 super-admin 목록)이거나, 해당 메뉴에 대한 권한이 있어야 한다. 별도의 역할
 * 개념을 새로 만들지 않으므로 메뉴권한 관리 화면에서 부여한 권한이 그대로 적용된다.
 */
@Component
@RequiredArgsConstructor
public class MenuAccessGuard {

    private final MenuPermissionService menuPermissionService;

    public enum Action {
        VIEW,
        CREATE,
        UPDATE,
        DELETE
    }

    /**
     * 호출자가 해당 메뉴에 대해 요청한 작업을 할 수 있는지 확인한다.
     *
     * @param userId 토큰에서 확인된 호출자(사칭 불가)
     * @throws AccessDeniedException 권한이 없을 때
     */
    public void ensure(String userId, String menuCd, Action action) {
        if (userId == null || userId.isBlank()) {
            throw new AccessDeniedException("로그인이 필요합니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        List<MenuPermissionDto> perms = menuPermissionService.resolveForLogin(userId);
        for (MenuPermissionDto p : perms) {
            if (!menuCd.equalsIgnoreCase(p.menuCd())) {
                continue;
            }
            if (allows(p, action)) {
                return;
            }
            break;
        }
        throw new AccessDeniedException("이 작업을 수행할 권한이 없습니다.");
    }

    /** [actions] 중 하나라도 허용되면 통과한다. */
    public void ensureAny(String userId, String menuCd, Action... actions) {
        if (userId == null || userId.isBlank()) {
            throw new AccessDeniedException("로그인이 필요합니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        if (actions == null || actions.length == 0) {
            throw new AccessDeniedException("이 작업을 수행할 권한이 없습니다.");
        }
        List<MenuPermissionDto> perms = menuPermissionService.resolveForLogin(userId);
        for (MenuPermissionDto p : perms) {
            if (!menuCd.equalsIgnoreCase(p.menuCd())) {
                continue;
            }
            for (Action action : actions) {
                if (allows(p, action)) {
                    return;
                }
            }
            break;
        }
        throw new AccessDeniedException("이 작업을 수행할 권한이 없습니다.");
    }

    private static boolean allows(MenuPermissionDto p, Action action) {
        return switch (action) {
            case VIEW -> p.canView();
            case CREATE -> p.canCreate();
            case UPDATE -> p.canUpdate();
            case DELETE -> p.canDelete();
        };
    }

    /** 슈퍼관리자 전용 작업(메뉴권한 부여 등). */
    public void ensureSuperAdmin(String userId) {
        if (userId == null || userId.isBlank() || !menuPermissionService.isSuperAdmin(userId)) {
            throw new AccessDeniedException("관리자만 수행할 수 있습니다.");
        }
    }

    /**
     * 요청에 실린 내부 userIdx 가 정말 호출자 본인인지 확인한다.
     *
     * <p>{@code AuthTokenFilter} 는 문자열 로그인 ID({@code userId} 파라미터)만 대조한다.
     * 그래서 {@code viewerUserIdx} 처럼 숫자 키로 신분을 받는 API 는 남의 번호를 넣어
     * 열람 권한을 우회할 수 있었다. 슈퍼관리자는 예외로 허용한다.
     *
     * @param userId 토큰에서 확인된 호출자(사칭 불가)
     * @param claimedUserIdx 요청이 주장하는 본인 번호
     */
    public void ensureSelfUserIdx(String userId, Integer claimedUserIdx) {
        if (userId == null || userId.isBlank()) {
            throw new AccessDeniedException("로그인이 필요합니다.");
        }
        if (menuPermissionService.isSuperAdmin(userId)) {
            return;
        }
        Integer actual = menuPermissionService.findUserIdx(userId);
        if (actual == null || claimedUserIdx == null || !actual.equals(claimedUserIdx)) {
            throw new AccessDeniedException("다른 사용자의 권한으로 조회할 수 없습니다.");
        }
    }

    /** 토큰에서 확인된 호출자 로그인 ID. 요청 파라미터가 아니므로 사칭할 수 없다. */
    public static String callerId(jakarta.servlet.http.HttpServletRequest request) {
        Object v = request.getAttribute(
                com.yeokjeon.erp.auth.token.AuthTokenFilter.ATTR_CURRENT_USER_ID);
        return v == null ? null : v.toString();
    }
}
