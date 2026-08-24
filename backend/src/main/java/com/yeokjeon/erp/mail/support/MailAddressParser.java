package com.yeokjeon.erp.mail.support;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 메일 주소 헤더 파서.
 *
 * <p>Resend 는 필드마다 형식이 다르다. 수신 웹훅의 {@code from} 은 순수 주소지만
 * 발송 이벤트의 {@code from} 은 {@code 홍길동 <hong@x.com>} 이고, 헤더에서 뽑은
 * {@code to} 는 {@code "Doe, John" <j@d.com>, b@c.com} 처럼 한 문자열에 여러 명이
 * 콤마로 붙어 온다. 이 셋을 서비스마다 따로 처리하면 반드시 어긋나므로 여기 한 곳으로 모았다.
 *
 * <p>콤마 분리를 정규식으로 하지 않는 이유: 표시이름 안에 콤마가 들어간
 * {@code "Doe, John" <j@d.com>} 이 실무에서 흔한데 정규식으로는 따옴표 상태를
 * 추적할 수 없어 한 사람이 두 명으로 쪼개진다. 그래서 상태 기계로 직접 훑는다.
 */
public final class MailAddressParser {

    /** {@code mail_addr_dtl.email} 은 varchar(320), {@code disp_nm} 은 varchar(255). */
    private static final int EMAIL_MAX = 320;
    private static final int DISP_NM_MAX = 255;

    private MailAddressParser() {
    }

    /** 파싱 결과. email 은 항상 소문자로 정규화돼 있고 비어 있지 않다. */
    public record Address(String email, String dispNm) {
    }

    /**
     * {@code 홍길동 <hong@x.com>} / {@code <hong@x.com>} / {@code hong@x.com} 한 건을 파싱한다.
     *
     * @return 주소를 못 찾으면 null
     */
    public static Address parseOne(String raw) {
        if (raw == null) {
            return null;
        }
        String source = raw.trim();
        if (source.isEmpty()) {
            return null;
        }
        String display = "";
        String email;

        // 표시이름 안에도 꺾쇠가 들어갈 수 있으므로 마지막 꺾쇠 쌍을 주소로 본다.
        int close = source.lastIndexOf('>');
        int open = close > 0 ? source.lastIndexOf('<', close) : source.lastIndexOf('<');
        if (open >= 0 && close > open) {
            email = source.substring(open + 1, close);
            display = source.substring(0, open);
        } else {
            email = source;
        }

        email = normalizeEmail(email);
        if (email.isEmpty()) {
            return null;
        }
        display = unquote(display);
        // 표시이름이 주소와 같으면 화면에 같은 값이 두 번 나오므로 버린다.
        if (display.equalsIgnoreCase(email)) {
            display = "";
        }
        return new Address(email, clip(display, DISP_NM_MAX));
    }

    /**
     * 콤마/세미콜론으로 이어 붙인 한 줄을 여러 주소로 쪼갠다.
     * 따옴표와 꺾쇠 안쪽의 구분자는 무시한다.
     */
    public static List<Address> parseLine(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        List<Address> result = new ArrayList<>();
        StringBuilder buffer = new StringBuilder();
        boolean inQuote = false;
        boolean inAngle = false;

        for (int i = 0; i < raw.length(); i++) {
            char c = raw.charAt(i);
            if (c == '"') {
                inQuote = !inQuote;
                buffer.append(c);
                continue;
            }
            if (!inQuote && c == '<') {
                inAngle = true;
                buffer.append(c);
                continue;
            }
            if (!inQuote && c == '>') {
                inAngle = false;
                buffer.append(c);
                continue;
            }
            if (!inQuote && !inAngle && (c == ',' || c == ';')) {
                flush(buffer, result);
                continue;
            }
            buffer.append(c);
        }
        flush(buffer, result);
        return result;
    }

    /**
     * Resend 가 배열로 주는 주소 목록을 파싱한다. 배열 원소 하나가 다시
     * 콤마로 이어진 여러 명일 수 있어 원소마다 {@link #parseLine(String)} 을 태운다.
     * 같은 주소가 두 번 나오면 첫 번째만 남긴다(입력 순서 유지).
     */
    public static List<Address> parseAll(List<String> raws) {
        if (raws == null || raws.isEmpty()) {
            return List.of();
        }
        Map<String, Address> unique = new LinkedHashMap<>();
        for (String raw : raws) {
            for (Address address : parseLine(raw)) {
                unique.putIfAbsent(address.email(), address);
            }
        }
        return List.copyOf(unique.values());
    }

    /** 소문자화 + 꺾쇠/mailto: 제거. 주소로 볼 수 없으면 빈 문자열. */
    public static String normalizeEmail(String raw) {
        if (raw == null) {
            return "";
        }
        String value = raw.trim();
        if (value.startsWith("<") && value.endsWith(">") && value.length() > 2) {
            value = value.substring(1, value.length() - 1).trim();
        }
        if (value.regionMatches(true, 0, "mailto:", 0, 7)) {
            value = value.substring(7).trim();
        }
        // 헤더 끝에 남은 구분자 정리
        while (!value.isEmpty() && (value.endsWith(",") || value.endsWith(";") || value.endsWith("."))) {
            value = value.substring(0, value.length() - 1).trim();
        }
        value = value.toLowerCase(Locale.ROOT);
        return isValidEmail(value) ? clip(value, EMAIL_MAX) : "";
    }

    /**
     * 최소한의 형태 검사만 한다.
     *
     * <p>RFC 준수 검증을 하지 않는 이유: 우리가 만든 주소가 아니라 남이 보낸 헤더를
     * 기록하는 것이 목적이라, 조금 이상해도 버리는 것보다 남기는 편이 낫다.
     * 발송 요청의 주소 검증은 DTO 의 {@code @Email} 이 따로 맡는다.
     */
    public static boolean isValidEmail(String email) {
        if (email == null) {
            return false;
        }
        String value = email.trim();
        int at = value.indexOf('@');
        if (at <= 0 || at != value.lastIndexOf('@') || at == value.length() - 1) {
            return false;
        }
        if (value.length() > EMAIL_MAX) {
            return false;
        }
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (Character.isWhitespace(c) || c == '<' || c == '>' || c == ',' || c == ';') {
                return false;
            }
        }
        return true;
    }

    /** 주소만 순서대로 뽑는다. */
    public static List<String> emails(List<Address> addresses) {
        if (addresses == null || addresses.isEmpty()) {
            return List.of();
        }
        List<String> result = new ArrayList<>(addresses.size());
        for (Address address : addresses) {
            result.add(address.email());
        }
        return result;
    }

    /**
     * 목록 화면용 수신자 요약({@code mail_mst.to_summary}).
     * 예: {@code hong@x.com 외 2명}
     */
    public static String summarize(List<Address> addresses, int maxLen) {
        if (addresses == null || addresses.isEmpty()) {
            return "";
        }
        String head = addresses.get(0).email();
        String summary = addresses.size() == 1
                ? head
                : head + " 외 " + (addresses.size() - 1) + "명";
        return clip(summary, maxLen);
    }

    // ── 내부 ────────────────────────────────────────────────────────────────

    private static void flush(StringBuilder buffer, List<Address> out) {
        String token = buffer.toString();
        buffer.setLength(0);
        Address address = parseOne(token);
        if (address == null) {
            return;
        }
        for (Address exists : out) {
            if (exists.email().equals(address.email())) {
                return;
            }
        }
        out.add(address);
    }

    private static String unquote(String raw) {
        String value = raw == null ? "" : raw.trim();
        while (value.length() > 1 && value.startsWith("\"") && value.endsWith("\"")) {
            value = value.substring(1, value.length() - 1).trim();
        }
        // 인코딩된 표시이름(=?UTF-8?B?...?=)은 디코딩하지 않는다. Resend 가 이미 디코딩해서
        // 주는 것이 정상이고, 아니라면 원문 그대로 남기는 편이 추적에 낫다.
        return value.replaceAll("\\s+", " ").trim();
    }

    private static String clip(String value, int max) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }
}
