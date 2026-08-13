package com.yeokjeon.erp.auth.token;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 발급 이후 무효화된 토큰을 걸러낸다.
 *
 * <p>토큰은 무상태(서버에 세션을 저장하지 않음)라서, 그대로 두면 비밀번호를 바꿔도
 * 이미 새어 나간 토큰이 만료(기본 12시간)까지 계속 통한다. "누가 들어온 것 같아서
 * 비밀번호를 바꿨다"는 대응이 실제로는 아무 효과가 없다는 뜻이다.
 *
 * <p>그래서 사용자별로 "이 시각 이전에 발급된 토큰은 무효" 기준선을 기억해 둔다.
 * 백엔드가 단일 인스턴스이므로 메모리 보관으로 충분하다. 재시작하면 기록이 사라지지만
 * 그 시점엔 어차피 비밀번호가 이미 바뀌어 있어 새 로그인은 새 비밀번호를 요구한다.
 */
@Component
public class TokenInvalidationRegistry {

    private final Map<String, Long> invalidatedBefore = new ConcurrentHashMap<>();

    /**
     * 이 사용자의 기존 토큰을 모두 무효화한다(비밀번호 변경·계정 삭제 시).
     *
     * @return 적용된 기준 시각. 이 시각보다 뒤에 발급된 토큰만 살아남는다.
     */
    public long invalidateAll(String userId) {
        long cutoff = System.currentTimeMillis();
        if (userId == null || userId.isBlank()) {
            return cutoff;
        }
        invalidatedBefore.put(userId.trim(), cutoff);
        return cutoff;
    }

    /** 해당 시각에 발급된 토큰이 아직 유효한지. */
    public boolean isStillValid(String userId, long issuedAt) {
        if (userId == null) {
            return false;
        }
        Long cutoff = invalidatedBefore.get(userId.trim());
        return cutoff == null || issuedAt > cutoff;
    }
}
