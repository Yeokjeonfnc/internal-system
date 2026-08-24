package com.yeokjeon.erp.mail.support;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * RFC5322 Message-ID 유틸.
 *
 * <p>스레드 연결의 정확도는 전부 이 값의 정규화에 달려 있다. 같은 메일인데
 * 어떤 헤더에는 {@code <abc@x.com>}, 어떤 헤더에는 {@code abc@x.com} 으로 들어오면
 * 문자열 비교가 어긋나 대화가 갈라진다. 그래서 DB 에는 항상 꺾쇠를 뗀 형태로만 저장하고
 * (마이그레이션 주석의 {@code rfc_message_id} 설명과 같은 규칙),
 * 바깥으로 보낼 때만 {@link #angled(String)} 로 다시 씌운다.
 */
public final class MailMessageIdUtil {

    /** {@code mail_mst.rfc_message_id} / {@code in_reply_to} 는 varchar(512). */
    private static final int MESSAGE_ID_MAX = 512;
    /** References 는 대화가 길어질수록 무한히 늘어나므로 저장·발송 모두 상한을 둔다. */
    private static final int REFERENCES_MAX_IDS = 20;

    private MailMessageIdUtil() {
    }

    /** {@code <abc@x.com>} → {@code abc@x.com}. 값이 없으면 null(컬럼도 nullable). */
    public static String strip(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        if (value.isEmpty()) {
            return null;
        }
        if (value.startsWith("<")) {
            value = value.substring(1);
        }
        if (value.endsWith(">")) {
            value = value.substring(0, value.length() - 1);
        }
        value = value.trim();
        if (value.isEmpty()) {
            return null;
        }
        // Message-ID 는 대소문자를 구분하지 않는 것이 관행이고, 구분하면 같은 대화가
        // 갈라지기만 한다. 비교와 저장을 모두 소문자로 통일한다.
        value = value.toLowerCase(Locale.ROOT);
        return value.length() <= MESSAGE_ID_MAX ? value : value.substring(0, MESSAGE_ID_MAX);
    }

    /** {@code abc@x.com} → {@code <abc@x.com>}. 헤더로 내보낼 때만 쓴다. */
    public static String angled(String messageId) {
        String value = strip(messageId);
        if (value == null) {
            return "";
        }
        return "<" + value + ">";
    }

    /**
     * In-Reply-To 헤더에서 부모 Message-ID 하나를 뽑는다.
     *
     * <p>규격상 하나지만 실제로는 여러 개가 들어오거나 뒤에 발신자 주소가 붙어 오기도 한다.
     * 마이그레이션 주석대로 "첫 번째 값만" 취하고 나머지는 버린다.
     */
    public static String firstMessageId(String raw) {
        List<String> ids = parseReferences(raw);
        return ids.isEmpty() ? null : ids.get(0);
    }

    /**
     * References/In-Reply-To 헤더를 Message-ID 목록으로 쪼갠다.
     * 공백·콤마 어느 쪽으로 구분돼 있어도 받는다. 중복은 순서를 유지한 채 제거한다.
     */
    public static List<String> parseReferences(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        Set<String> unique = new LinkedHashSet<>();
        // 꺾쇠가 있으면 꺾쇠 단위로, 없으면 공백/콤마 단위로 자른다.
        String normalized = raw.replace('\r', ' ').replace('\n', ' ').replace('\t', ' ');
        String[] tokens = normalized.contains("<")
                ? normalized.split("(?<=>)\\s*,?\\s*")
                : normalized.split("[\\s,]+");
        for (String token : tokens) {
            String id = strip(token);
            if (id != null) {
                unique.add(id);
            }
        }
        return List.copyOf(unique);
    }

    /**
     * 저장용 References 문자열을 만든다(공백 구분, 꺾쇠 포함).
     * 오래된 앞쪽부터 버려 최근 {@value #REFERENCES_MAX_IDS} 개만 남긴다.
     */
    public static String joinReferences(List<String> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return null;
        }
        Set<String> unique = new LinkedHashSet<>();
        for (String messageId : messageIds) {
            String id = strip(messageId);
            if (id != null) {
                unique.add(id);
            }
        }
        if (unique.isEmpty()) {
            return null;
        }
        List<String> ids = new ArrayList<>(unique);
        if (ids.size() > REFERENCES_MAX_IDS) {
            // 스레드 판정에 실제로 쓰이는 건 가장 최근 조상들이다.
            ids = ids.subList(ids.size() - REFERENCES_MAX_IDS, ids.size());
        }
        StringBuilder builder = new StringBuilder();
        for (String id : ids) {
            if (builder.length() > 0) {
                builder.append(' ');
            }
            builder.append('<').append(id).append('>');
        }
        return builder.toString();
    }

    /**
     * 발신 메일용 Message-ID 를 만든다.
     *
     * <p>Resend 가 실제 헤더에 넣는 Message-ID 는 우리가 알 수 없다(발송 응답에 없다).
     * 그래도 우리 쪽 값을 하나 만들어 두는 이유는, 우리가 보낸 메일에 우리가 다시
     * 답장할 때 {@code in_reply_to} 로 이어 붙일 로컬 기준점이 필요하기 때문이다.
     * 외부 수신자가 보낸 답장은 이 값과 안 맞으므로 제목 폴백으로 묶인다.
     */
    public static String generate(String fromEmail) {
        String domain = domainOf(fromEmail);
        return UUID.randomUUID().toString().replace("-", "") + "@" + domain;
    }

    /** 주소에서 도메인만. 뽑을 수 없으면 {@code yeokjeon.local}. */
    public static String domainOf(String email) {
        if (email == null) {
            return "yeokjeon.local";
        }
        int at = email.lastIndexOf('@');
        if (at < 0 || at == email.length() - 1) {
            return "yeokjeon.local";
        }
        String domain = email.substring(at + 1).trim().toLowerCase(Locale.ROOT);
        return domain.isEmpty() ? "yeokjeon.local" : domain;
    }
}
