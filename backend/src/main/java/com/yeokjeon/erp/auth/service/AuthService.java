package com.yeokjeon.erp.auth.service;

import com.yeokjeon.erp.auth.dto.AuthLoginRequestDto;
import com.yeokjeon.erp.auth.dto.AuthProfileDto;
import com.yeokjeon.erp.auth.dto.AuthProfileRowDto;
import com.yeokjeon.erp.auth.dto.AuthProfileUpdateRequestDto;
import com.yeokjeon.erp.auth.mapper.AuthProfileMapper;
import com.yeokjeon.erp.auth.password.PasswordHasher;
import com.yeokjeon.erp.auth.token.AuthTokenService;
import com.yeokjeon.erp.master.dto.MenuPermissionDto;
import com.yeokjeon.erp.master.service.MenuPermissionService;
import com.yeokjeon.erp.master.service.UsageLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
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
    private final AuthTokenService authTokenService;
    private final PasswordHasher passwordHasher;

    /**
     * 로그인ID는 있는데 비밀번호를 안 정한 계정(신규 등록 시 비워둔 경우, 관리자의
     * "비밀번호 초기화")에 쓰는 값. config\backend.env 의 DEFAULT_USER_PASSWORD 로
     * 덮어쓸 수 있다.
     */
    @Value("${auth.default-password:durwjs1982}")
    private String defaultPassword;

    /** 신규 계정 생성 시 비밀번호를 비워두면 이 값을 쓴다. */
    public String defaultPassword() {
        return defaultPassword;
    }

    /**
     * 로그인. 아이디·비밀번호가 틀리면 {@code null}.
     *
     * <p><b>예상치 못한 오류는 삼키지 않고 그대로 던진다.</b> 예전에는 전체를
     * try/catch 로 감싸 무슨 오류든 {@code null} 을 돌려줬는데, 그러면 컨트롤러가
     * "아이디 또는 비밀번호가 일치하지 않습니다"(401)로 응답한다. 실제로 DB 스키마
     * 문제로 전 사용자가 로그인 불가였을 때 이 메시지 때문에 원인이 완전히 가려졌다.
     * 서버 문제는 500 으로 드러나야 조기에 알아챌 수 있다.
     */
    public AuthProfileDto login(AuthLoginRequestDto body) {
        String userId = body.userId();
        String userPassword = body.userPassword();

        // --- 여기까지가 로그인의 본질: 비밀번호 확인 + 사용자 조회 ---
        String stored = authProfileMapper.selectPasswordHash(userId);
        if (!passwordHasher.matches(userPassword, stored)) {
            return null;
        }
        AuthProfileRowDto row = authProfileMapper.selectByUserId(userId);
        if (row == null) {
            return null;
        }

        /*
         * --- 여기서부터는 전부 "부가 정보"다 ---
         * 해시 전환, 사용기록, 메뉴 권한, 관리자 표시, 강제변경 표시.
         * 비밀번호가 맞고 사용자를 찾았으므로 로그인은 이미 성립했다.
         * 이 중 하나가 실패했다고 로그인을 실패시키면 안 된다.
         *
         * 실제로 그렇게 터졌다 — 해시 전환 UPDATE 가 없는 컬럼을 건드려 예외를
         * 던졌을 뿐인데, 그 예외가 login() 전체를 감싼 catch 로 흘러가 null 이
         * 반환되었고 전 사용자가 401 을 받았다. 그래서 개별로 감싼다.
         */

        // 평문으로 남아 있던 계정은 로그인 성공 시점에 해시로 올려둔다.
        if (passwordHasher.needsRehash(stored)) {
            try {
                authProfileMapper.updatePasswordHash(userId, passwordHasher.hash(userPassword));
                log.info("평문 비밀번호를 해시로 전환했습니다: userId={}", userId);
            } catch (Exception e) {
                log.warn("비밀번호 해시 전환 실패(로그인은 계속): userId={}, {}", userId, e.getMessage());
            }
        }
        usageLogService.recordLogin(row);

        List<MenuPermissionDto> menuPermissions = loadMenuPermissionsSafely(userId);
        AuthProfileDto profile = AuthProfileDto.fromRow(row, menuPermissions);

        // admin_yn 컬럼 또는 config 폴백 — 프론트가 관리자 여부를 일관되게 받도록 보정
        try {
            if (menuPermissionService.isSuperAdmin(userId)) {
                profile = profile.withAdminYn("Y");
            }
        } catch (Exception e) {
            log.warn("슈퍼관리자 판정 생략(로그인은 계속): userId={}, {}", userId, e.getMessage());
        }

        // 초기화된 비밀번호로 들어온 경우 프론트가 변경 화면을 강제하도록 표시.
        if ("Y".equalsIgnoreCase(resolvePwdResetYn(userId))) {
            profile = profile.withMustChangePassword(true);
        }
        // 이후 요청은 이 토큰으로 신분을 증명한다(AuthTokenFilter 검증).
        return profile.withAccessToken(authTokenService.issue(row.userId()));
    }

    @Transactional
    public AuthProfileDto updateUserProfile(String userId, AuthProfileUpdateRequestDto body) {
        // 이 경로로도 비밀번호가 바뀔 수 있다 — 평문으로 저장되지 않도록 해시한다.
        String pw = body.getUserPassword();
        if (pw != null && !pw.isBlank()) {
            body.setUserPassword(passwordHasher.hash(pw));
        }
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

    /**
     * 비밀번호 변경. 현재 비밀번호가 맞아야 하며, 성공 시 변경 강제 플래그를 해제한다.
     *
     * @return 실패 사유(성공이면 null)
     */
    @Transactional
    public String changePassword(String userId, String currentPassword, String newPassword) {
        if (newPassword == null || newPassword.trim().length() < 8) {
            return "새 비밀번호는 8자 이상이어야 합니다.";
        }
        if (newPassword.equals(currentPassword)) {
            return "현재 비밀번호와 다른 값을 입력해 주세요.";
        }
        String stored = authProfileMapper.selectPasswordHash(userId);
        if (!passwordHasher.matches(currentPassword, stored)) {
            return "현재 비밀번호가 일치하지 않습니다.";
        }
        int updated = authProfileMapper.updatePasswordHash(userId, passwordHasher.hash(newPassword));
        if (updated <= 0) {
            return "비밀번호 변경에 실패했습니다.";
        }
        log.info("비밀번호 변경 완료: userId={}", userId);
        return null;
    }

    /**
     * 관리자가 비밀번호를 초기값으로 되돌린다(사원관리 목록의 "비밀번호 초기화").
     * 다음 로그인 때 반드시 바꾸도록 강제 플래그도 같이 세운다.
     *
     * <p><b>{@code @Transactional} 을 붙이면 안 된다.</b> 아래 두 문장을 한 트랜잭션에
     * 묶으면, 두 번째({@code pwd_reset_yn})가 "컬럼 없음"으로 실패하는 순간 PostgreSQL 이
     * 트랜잭션 전체를 abort 시켜 **이미 성공한 비밀번호 변경까지 롤백된다.** 자바
     * try/catch 는 DB 의 abort 상태를 되돌리지 못한다. 실제로 그렇게 동작해서,
     * "초기화되었습니다" 메시지만 뜨고 비밀번호는 그대로인 상태였다.
     *
     * <p>트랜잭션이 없으면 각 문장이 개별 auto-commit 이라 비밀번호 변경이 먼저
     * 확정되고, 플래그 실패는 그 뒤에 독립적으로 무시된다.
     */
    public void resetPasswordToDefault(String userId) {
        authProfileMapper.updatePasswordHash(userId, passwordHasher.hash(defaultPassword));
        setPasswordResetFlag(userId, "Y");
        log.info("비밀번호를 초기값으로 재설정했습니다: userId={}", userId);
    }

    /**
     * 신규 계정을 기본 비밀번호로 생성했을 때 강제변경 플래그를 세운다.
     *
     * <p><b>계정 생성 트랜잭션이 커밋된 뒤에 호출해야 한다</b>(컨트롤러에서 호출).
     * 생성 트랜잭션 안에서 부르면 컬럼 없음 오류가 트랜잭션을 오염시켜 방금 만든
     * 계정이 통째로 롤백되는데, 응답은 성공으로 나간다 — 실제로 그렇게 터졌다.
     */
    public void markPasswordResetRequired(String userId) {
        setPasswordResetFlag(userId, "Y");
    }

    /**
     * 강제변경 플래그 해제 — 실패해도 무시한다.
     *
     * <p>{@code pwd_reset_yn} 은 미적용 DB 가 있는 선택 컬럼이다. 트랜잭션 안에서
     * 실패하면 try/catch 로 잡아도 롤백 표시가 남아 **이미 성공한 비밀번호 변경까지
     * 되돌아간다.** 그래서 {@link #changePassword} 트랜잭션 밖에서 따로 호출한다.
     */
    public void clearPasswordResetFlag(String userId) {
        setPasswordResetFlag(userId, "N");
    }

    /** {@code pwd_reset_yn} 갱신 — 컬럼 미적용 DB 에서는 조용히 건너뛴다. */
    private void setPasswordResetFlag(String userId, String flag) {
        try {
            authProfileMapper.updatePwdResetYn(userId, flag);
        } catch (Exception e) {
            log.warn("pwd_reset_yn 갱신 생략(컬럼 미적용 가능): userId={}, {}", userId, e.getMessage());
        }
    }

    /** `pwd_reset_yn` 조회 — 컬럼 미적용 DB 에서도 로그인이 막히지 않게 방어한다. */
    private String resolvePwdResetYn(String userId) {
        try {
            String v = authProfileMapper.selectPwdResetYn(userId);
            return v == null ? "N" : v;
        } catch (Exception e) {
            log.warn("pwd_reset_yn 조회 생략(컬럼 미적용 가능): userId={}, {}", userId, e.getMessage());
            return "N";
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
