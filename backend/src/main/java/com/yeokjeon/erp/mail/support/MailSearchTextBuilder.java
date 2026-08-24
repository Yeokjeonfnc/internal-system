package com.yeokjeon.erp.mail.support;

import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * {@code mail_body.search_txt} 생성기.
 *
 * <p>왜 별도 컬럼인가: 검색은 "제목에 있든 보낸 사람에 있든 본문에 있든" 한 번에 찾히길
 * 기대한다. 컬럼 4개에 각각 ILIKE 를 OR 로 걸면 trigram 인덱스를 컬럼마다 태워야 하고
 * 플래너가 대부분 그냥 seq scan 을 고른다. 제목+참여자+본문을 한 컬럼에 이어 붙여 두면
 * {@code idx_mail_body_search_trgm} 하나로 끝난다.
 *
 * <p>왜 바이트 상한인가: 원문 그대로 넣으면 뉴스레터 한 통이 수백 KB 라
 * trigram 인덱스가 본문 테이블보다 커진다. 상한을 넘는 뒷부분은 검색 대상에서 빠지지만
 * 실제로 필요한 건 앞부분이고, 원문은 {@code body_text}/{@code body_html} 에 그대로 남는다.
 */
public final class MailSearchTextBuilder {

    private MailSearchTextBuilder() {
    }

    /**
     * 제목 + 참여자 주소 + 평문 본문을 이어 붙인다.
     *
     * @param maxBytes UTF-8 기준 상한(기본 100KB). 0 이하면 자르지 않는다.
     */
    public static String build(String subject,
                               Collection<String> participants,
                               String bodyText,
                               int maxBytes) {
        StringBuilder builder = new StringBuilder();
        appendLine(builder, subject);

        if (participants != null && !participants.isEmpty()) {
            // 같은 주소가 TO/CC 에 겹쳐 들어오는 일이 흔해 중복을 걷어낸다.
            Set<String> unique = new LinkedHashSet<>();
            for (String participant : participants) {
                if (participant != null && !participant.isBlank()) {
                    unique.add(participant.trim().toLowerCase(Locale.ROOT));
                }
            }
            appendLine(builder, String.join(" ", unique));
        }

        appendLine(builder, bodyText);

        // trigram 은 대소문자를 구분하므로 저장할 때 한 번 낮춰 둔다
        // (조회 쪽에서 ILIKE 를 쓰더라도 인덱스 후보 추출이 안정적이다).
        String text = builder.toString().replaceAll("\\s+", " ").trim().toLowerCase(Locale.ROOT);
        return truncateToBytes(text, maxBytes);
    }

    /**
     * UTF-8 바이트 길이 기준으로 자른다.
     *
     * <p>{@code String.substring} 으로 글자 수만 세면 한글(3바이트) 본문에서
     * 상한을 3배 초과한다. 반대로 바이트 배열을 그냥 자르면 멀티바이트 글자가 반토막 나
     * 깨진 문자가 DB 에 들어간다. 그래서 자른 뒤 마지막 글자 경계를 되돌린다.
     */
    public static String truncateToBytes(String value, int maxBytes) {
        if (value == null || value.isEmpty() || maxBytes <= 0) {
            return value == null ? "" : value;
        }
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        if (bytes.length <= maxBytes) {
            return value;
        }
        int end = maxBytes;
        // UTF-8 연속 바이트(10xxxxxx)면 글자 중간이므로 앞으로 물러난다.
        while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
            end--;
        }
        return new String(bytes, 0, end, StandardCharsets.UTF_8);
    }

    /** 본문이 상한 때문에 잘렸는지({@code mail_body.truncated_yn}). */
    public static boolean exceedsBytes(String value, int maxBytes) {
        if (value == null || value.isEmpty() || maxBytes <= 0) {
            return false;
        }
        return value.getBytes(StandardCharsets.UTF_8).length > maxBytes;
    }

    private static void appendLine(StringBuilder builder, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        if (builder.length() > 0) {
            builder.append('\n');
        }
        builder.append(value.trim());
    }
}
