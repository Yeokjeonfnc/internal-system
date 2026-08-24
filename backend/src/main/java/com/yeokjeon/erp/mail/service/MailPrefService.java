package com.yeokjeon.erp.mail.service;

import com.yeokjeon.erp.mail.dto.MailPrefJdbcRow;
import com.yeokjeon.erp.mail.mapper.MailPrefMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 개인 메일 설정 (mal001-E).
 *
 * <p>다우오피스는 읽기/쓰기 설정을 20개 넘게 쪼개 두었는데 실제로 손대는 항목은 소수다.
 * 그래서 컬럼이 아니라 키-값으로 두었고, 화면에 항목이 늘어도 <b>스키마도 이 서비스도
 * 그대로다</b>. 그게 이 구조를 고른 이유다.
 *
 * <p>대신 대가가 있다 — 서버는 값의 의미를 모른다. 타입 검증(불리언인지 숫자인지)은
 * 하지 않고 길이만 본다. 값의 해석은 전적으로 화면 몫이다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailPrefService {

    /** 컬럼 길이 그대로(varchar(50)/varchar(500)). 넘으면 DB 가 자르는 게 아니라 실패한다. */
    private static final int KEY_MAX = 50;
    private static final int VAL_MAX = 500;

    /** 한 번에 저장할 수 있는 항목 수. 요청 DTO 의 @Size 와 같은 값이어야 한다. */
    private static final int MAX_ENTRIES = 100;

    private final MailPrefMapper mailPrefMapper;

    /**
     * 전체 설정 조회.
     *
     * <p>저장된 것이 없으면 빈 Map 이다. 서버가 기본값을 채워 주지 않는 이유는,
     * 그러면 "기본값"이 서버와 화면 두 군데에 생겨 언젠가 어긋나기 때문이다.
     * 화면이 자기 기본값을 갖고, 서버는 사용자가 명시적으로 바꾼 것만 돌려준다.
     */
    @Transactional(readOnly = true)
    public Map<String, String> get(String userId) {
        List<MailPrefJdbcRow> rows = mailPrefMapper.selectByUserId(requireUserId(userId));
        // 조회 SQL 이 pref_key 순으로 주므로 LinkedHashMap 이면 그 순서가 응답까지 이어진다.
        Map<String, String> result = new LinkedHashMap<>();
        for (MailPrefJdbcRow row : rows) {
            result.put(row.prefKey(), row.prefVal() == null ? "" : row.prefVal());
        }
        return result;
    }

    /**
     * 다건 저장(부분 갱신).
     *
     * <p><b>요청에 없는 키는 지우지 않는다.</b> 전체 치환으로 만들면 구버전 화면이 자기가
     * 모르는 새 설정을 통째로 날려 버린다. 값을 비우려면 빈 문자열을 명시적으로 보낸다.
     *
     * @return 저장 후의 전체 설정. 화면이 다시 조회하지 않아도 되게 한 번에 돌려준다.
     */
    @Transactional
    public Map<String, String> save(Map<String, String> prefs, String userId) {
        String uid = requireUserId(userId);
        Map<String, String> sanitized = sanitize(prefs);
        if (sanitized.isEmpty()) {
            // 빈 VALUES 는 SQL 문법 오류다. 매퍼에 닿기 전에 끊는다.
            throw new IllegalArgumentException("저장할 설정이 없습니다.");
        }
        mailPrefMapper.upsertBatch(uid, sanitized);
        log.debug("메일 설정 저장 {}건 by={}", sanitized.size(), uid);
        return get(uid);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    /**
     * 키-값을 저장 가능한 형태로 다듬는다.
     *
     * <p>길이 초과를 잘라서 저장하지 않고 거부하는 이유: 설정값이 조용히 잘리면
     * 화면은 저장에 성공했다고 알리는데 실제 동작은 다른 값으로 굴러간다.
     * 빈 키는 버린다 — 키가 없는 설정은 다시 찾을 방법이 없다.
     */
    private static Map<String, String> sanitize(Map<String, String> prefs) {
        if (prefs == null || prefs.isEmpty()) {
            return Map.of();
        }
        if (prefs.size() > MAX_ENTRIES) {
            throw new IllegalArgumentException(
                    "한 번에 최대 " + MAX_ENTRIES + "개까지 저장할 수 있습니다.");
        }
        Map<String, String> result = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : prefs.entrySet()) {
            String key = entry.getKey() == null ? "" : entry.getKey().trim();
            if (key.isEmpty()) {
                continue;
            }
            if (key.length() > KEY_MAX) {
                throw new IllegalArgumentException("설정 키가 너무 깁니다: " + key);
            }
            // NOT NULL DEFAULT '' 컬럼이라 null 은 빈 문자열로 바꿔 넣는다.
            String value = entry.getValue() == null ? "" : entry.getValue();
            if (value.length() > VAL_MAX) {
                throw new IllegalArgumentException("설정 값이 너무 깁니다: " + key);
            }
            result.put(key, value);
        }
        return result;
    }

    private static String requireUserId(String userId) {
        if (!StringUtils.hasText(userId)) {
            throw new IllegalStateException("로그인 정보를 확인할 수 없습니다.");
        }
        return userId.trim();
    }
}
