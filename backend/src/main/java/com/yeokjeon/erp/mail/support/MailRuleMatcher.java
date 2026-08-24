package com.yeokjeon.erp.mail.support;

import java.util.Collection;
import java.util.Locale;

/**
 * 자동분류 규칙의 조건 판정 (mal001-K).
 *
 * <p>SQL 이 아니라 자바에서 판정하는 이유. 조건이 세 개뿐이고 대상은 방금 받은 메일 <b>한 건</b>
 * 이다. 이걸 SQL 로 짜면 규칙 테이블과 메일·참여자를 조인해 동적 LIKE 를 세 개 만드는
 * 질의가 되는데, 읽기도 어렵고 첫 매칭 하나만 쓴다는 규칙을 표현하기도 번거롭다.
 * 여기서 하면 순수 함수라 눈으로 검증할 수 있다.
 *
 * <p><b>전부 대소문자를 무시한다.</b> 주소는 저장 단계에서 이미 소문자지만 사용자가 규칙에
 * 대문자를 섞어 넣고, 제목은 애초에 원문 그대로 저장된다. 여기서 한 번에 맞춰 두지 않으면
 * "왜 규칙이 안 걸리지"의 대부분이 대소문자 문제가 된다.
 */
public final class MailRuleMatcher {

    /** 포함 */
    public static final String OP_CONTAINS = "CONTAINS";
    /** 일치 */
    public static final String OP_EQUALS = "EQUALS";
    /** 시작함 */
    public static final String OP_STARTS = "STARTS";

    private MailRuleMatcher() {
    }

    /** 화면·DB 가 쓰는 정규형(대문자, 공백 제거). 모르는 값이면 null 을 준다. */
    public static String normalizeOp(String op) {
        if (op == null) {
            return null;
        }
        String value = op.trim().toUpperCase(Locale.ROOT);
        return switch (value) {
            case OP_CONTAINS, OP_EQUALS, OP_STARTS -> value;
            default -> null;
        };
    }

    /**
     * 조건 하나를 판정한다.
     *
     * <p>{@code needle}(규칙에 적힌 값)이 비면 <b>조건 자체가 없는 것</b>이라 true 다 —
     * AND 결합에서 "무시"는 곧 "통과"여야 나머지 조건만으로 판정된다. 반대로
     * {@code haystack}(메일 쪽 값)이 비면 비교할 대상이 없으므로 false 다.
     */
    public static boolean matches(String op, String needle, String haystack) {
        if (needle == null || needle.isBlank()) {
            return true;
        }
        if (haystack == null || haystack.isEmpty()) {
            return false;
        }
        String target = haystack.toLowerCase(Locale.ROOT);
        String value = needle.trim().toLowerCase(Locale.ROOT);
        String normalized = normalizeOp(op);
        if (normalized == null) {
            // DB CHECK 가 막아 두었으므로 정상 경로에서는 올 수 없다. 그래도 여기까지 왔다면
            // 가장 넓은 연산자로 떨어뜨린다 — 조용히 false 를 주면 "규칙이 있는데 아무것도
            // 안 걸리는" 상태가 되어 원인을 찾기가 훨씬 어렵다.
            normalized = OP_CONTAINS;
        }
        return switch (normalized) {
            case OP_EQUALS -> target.equals(value);
            case OP_STARTS -> target.startsWith(value);
            default -> target.contains(value);
        };
    }

    /**
     * 여러 값 중 하나라도 걸리면 참(수신자 조건 전용).
     *
     * <p>다우오피스의 "수신자(참조 포함)" 는 받는사람과 참조를 한 조건으로 묶는다.
     * 그래서 TO 와 CC 를 한 묶음으로 넘겨 그중 하나만 걸려도 통과시킨다.
     */
    public static boolean matchesAny(String op, String needle, Collection<String> haystacks) {
        if (needle == null || needle.isBlank()) {
            return true;
        }
        if (haystacks == null || haystacks.isEmpty()) {
            return false;
        }
        for (String haystack : haystacks) {
            if (matches(op, needle, haystack)) {
                return true;
            }
        }
        return false;
    }
}
