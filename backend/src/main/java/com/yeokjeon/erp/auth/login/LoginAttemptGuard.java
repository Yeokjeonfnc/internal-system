package com.yeokjeon.erp.auth.login;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 로그인 무차별 대입(brute force) 차단.
 *
 * <p>로그인은 토큰 없이 열려 있는 유일한 쓰기 경로다. 지금까지는 시도 횟수 제한이 전혀
 * 없어서, 인터넷에 열린 주소로 초당 수백 번씩 비밀번호를 넣어 볼 수 있었다.
 * 계정 하나가 뚫리면 그 계정의 메뉴 권한 전체가 넘어간다.
 *
 * <p>계정(로그인 ID)별로 연속 실패를 세고, 한도를 넘으면 잠금 시간 동안 아이디·비밀번호가
 * 맞아도 거절한다. 성공하면 즉시 초기화한다. 백엔드가 단일 인스턴스라 메모리 보관으로
 * 충분하며, 재시작하면 초기화된다.
 */
@Slf4j
@Component
public class LoginAttemptGuard {

    /** 잠금까지 허용할 연속 실패 횟수. */
    private static final int MAX_FAILURES = 10;

    /** 잠금 유지 시간(밀리초). */
    private static final long LOCK_MILLIS = 10 * 60 * 1000L;

    /** 마지막 실패 후 이 시간이 지나면 실패 기록을 잊는다. */
    private static final long RESET_MILLIS = 30 * 60 * 1000L;

    private static final class Attempt {
        final AtomicInteger failures = new AtomicInteger();
        volatile long lastFailureAt;
        volatile long lockedUntil;
    }

    private final Map<String, Attempt> attempts = new ConcurrentHashMap<>();

    /** 잠겨 있으면 남은 초, 아니면 0. */
    public long lockedSecondsRemaining(String userId) {
        Attempt a = attempts.get(key(userId));
        if (a == null) {
            return 0;
        }
        long remaining = a.lockedUntil - System.currentTimeMillis();
        return remaining > 0 ? (remaining / 1000) + 1 : 0;
    }

    public void recordFailure(String userId) {
        String k = key(userId);
        if (k.isEmpty()) {
            return;
        }
        long now = System.currentTimeMillis();
        Attempt a = attempts.computeIfAbsent(k, x -> new Attempt());
        // 오래 전 실패는 이어 세지 않는다(정상 사용자의 오타 누적 방지).
        if (a.lastFailureAt > 0 && now - a.lastFailureAt > RESET_MILLIS) {
            a.failures.set(0);
        }
        a.lastFailureAt = now;
        int count = a.failures.incrementAndGet();
        if (count >= MAX_FAILURES) {
            a.lockedUntil = now + LOCK_MILLIS;
            a.failures.set(0);
            log.warn("로그인 연속 실패로 계정 잠금: userId={}, {}분", k, LOCK_MILLIS / 60000);
        }
    }

    public void recordSuccess(String userId) {
        attempts.remove(key(userId));
    }

    private static String key(String userId) {
        return userId == null ? "" : userId.trim();
    }
}
