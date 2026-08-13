package com.yeokjeon.erp.auth.password;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 비밀번호 해싱·검증 (BCrypt).
 *
 * <p>기존에는 비밀번호를 평문으로 저장하고 SQL 동등비교로 로그인했다. DB 가 유출되면
 * 전 직원 비밀번호가 그대로 노출되는 구조라 BCrypt 해시로 전환했다.
 *
 * <p>과도기 호환: 아직 해시로 바뀌지 않은 평문 비밀번호가 남아 있을 수 있으므로
 * {@link #matches} 는 저장값이 BCrypt 형식이 아니면 평문 비교로 폴백한다.
 * 이때 {@link #needsRehash} 가 true 를 돌려주므로 호출측에서 즉시 해시로 갱신한다.
 * (전체 초기화 마이그레이션 이후에는 사실상 쓰이지 않는 경로다.)
 */
@Component
public class PasswordHasher {

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    /** 저장용 해시. */
    public String hash(String rawPassword) {
        return encoder.encode(rawPassword);
    }

    /** 입력 비밀번호가 저장값과 일치하는지. */
    public boolean matches(String rawPassword, String stored) {
        if (rawPassword == null || stored == null || stored.isBlank()) {
            return false;
        }
        if (isBcryptHash(stored)) {
            return encoder.matches(rawPassword, stored);
        }
        // 아직 해시되지 않은 평문 잔재 — 동등비교로 받아준 뒤 호출측에서 재해시한다.
        return rawPassword.equals(stored);
    }

    /** 저장값이 평문이라 해시로 갱신해야 하는지. */
    public boolean needsRehash(String stored) {
        return stored != null && !stored.isBlank() && !isBcryptHash(stored);
    }

    private static boolean isBcryptHash(String stored) {
        return stored.startsWith("$2a$") || stored.startsWith("$2b$") || stored.startsWith("$2y$");
    }
}
